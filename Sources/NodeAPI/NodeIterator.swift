public protocol NodeIterable: Sequence where Element: NodeValueConvertible {}

public extension NodeIterable {
  @NodeActor func nodeIterator() throws -> NodeIterator {
    let swiftIterator = self.lazy.map { $0 as any NodeValueConvertible }.makeIterator()
    return NodeIterator(swiftIterator)
  }
}

public final class NodeIterator: NodeClass {
  public struct Result: NodeValueConvertible, NodeValueCreatable {
      public typealias ValueType = NodeObject

      let value: NodeValueConvertible?
      let done: Bool?

      public func nodeValue() throws -> any NodeValue {
         let obj = try NodeObject()
         if let value = value {
             try obj.set("value", value.nodeValue())
         }
         if let done = done {
             try obj.set("done", done.nodeValue())
         }
         return obj
      }

      public static func from(_ value: ValueType) throws -> Self {
        Self(
          value: try value.get("value"),
          done: try value.get("done").as(Bool.self)
        )
      }
  }

    typealias Element = any NodeValueConvertible
  
    public static let properties: NodeClassPropertyList = [
        "next": NodeMethod(next),
    ]

    private var iterator: any IteratorProtocol<Element>

    init(_ iterator: any IteratorProtocol<any NodeValueConvertible>) {
        self.iterator = iterator
    }

    public func next() throws -> Result {
      if let value = iterator.next() {
        return Result(value: value, done: false)
      } else {
        return Result(value: nil, done: true)
      }
    }
}

