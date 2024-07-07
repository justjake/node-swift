@_implementationOnly import CNodeAPI

public final class NodeSymbol: NodePrimitive, NodeName {

    @_spi(NodeAPI) public let base: NodeValueBase
    @_spi(NodeAPI) public init(_ base: NodeValueBase) {
        self.base = base
    }
  
  public static func global(for: String) throws -> NodeSymbol {
    let ctx = NodeContext.current
    let env = ctx.environment
    return try env.run(script: "globalThis.Symbol.for(\"\(`for`)\"") as! NodeSymbol
  }
  
  public static func wellKnown(_ name: String) -> NodeSymbol {
    let ctx = NodeContext.current
    let env = ctx.environment
    do {
      let symbolValue = try env.global["Symbol"][name].nodeValue()
      if try symbolValue.nodeType() == .symbol {
        return Self(symbolValue.base)
      }
      fatalError("globalThis.Symbol.\(name) is not a symbol")
    } catch {
      fatalError("Cannot get globalThis.Symbol.\(name)")
    }
  }
  
  public static var iterator: NodeSymbol { wellKnown("iterator") }
  
//  #if !NAPI_VERSIONED || NAPI_GE_9
//    public static func `for`(_ name: String) throws {
//      let ctx = NodeContext.current
//      let env = ctx.environment
//      var result: napi_value!
//      let descRaw = name.utf8CString
//      let descLen = descRaw.count
//      try env.check(node_api_symbol_for(env.raw, descRaw, descLen, &result))
//      NodeSymbol(NodeValueBase(raw: result, in: ctx))
//    }
//  #endif

    public init(description: String? = nil) throws {
        let ctx = NodeContext.current
        let env = ctx.environment
        var result: napi_value!
        let descRaw = try description.map { try $0.rawValue() }
        try env.check(napi_create_symbol(env.raw, descRaw, &result))
        self.base = NodeValueBase(raw: result, in: ctx)
    }

}
