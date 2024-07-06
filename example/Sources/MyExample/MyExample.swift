import NodeAPI
import Foundation

enum MyError: Error {
  case missingProperty(String)
}

extension NodeObject {
  @NodeActor public func propertyAs<T: AnyNodeValueCreatable>(_ property: String, _ type: T.Type) throws -> T {
    guard let value = try self.property(forKey: property).as(type) else {
      throw MyError.missingProperty("Cannot convert property .\(property) to type '\(type)': missing or undefined")
    }
    return value
  }
}

extension CGPoint: NodeValueConvertible, NodeValueCreatable {
  public typealias ValueType = NodeObject
  
  public func nodeValue() throws -> any NodeValue {
    let obj: NodeObject = try NodeObject([
      "x": x,
      "y": y,
    ])
    return obj
  }
  
  public static func from(_ value: ValueType) throws -> Self {
    let x = try value.propertyAs("x", Double.self)
    let y = try value.propertyAs("y", Double.self)
    return Self(x: x, y: y)
  }
}


extension CGSize: NodeValueConvertible, NodeValueCreatable {
  public typealias ValueType = NodeObject
  
  public func nodeValue() throws -> any NodeValue {
    try NodeObject([
      "width": width,
      "height": height,
    ])
  }
  
  public static func from(_ value: ValueType) throws -> Self {
    let width = try value.propertyAs("width", Double.self)
    let height = try value.propertyAs("height", Double.self)
    return Self(width: width, height: height)
  }
}

extension CGRect: NodeValueConvertible, NodeValueCreatable {
  public typealias ValueType = NodeObject
  
  public func nodeValue() throws -> any NodeValue {
    try NodeObject([
      "origin": origin,
      "size": size,
    ])
  }
  
  public static func from(_ value: ValueType) throws -> Self {
    let origin = try value.propertyAs("origin", CGPoint.self)
    let size = try value.propertyAs("size", CGSize.self)
    return Self(origin: origin, size: size)
  }
}

#NodeModule(exports: [
    "nums": [Double.pi.rounded(.down), Double.pi.rounded(.up)],
    "str": String(repeating: "NodeSwift! ", count: 3),
    "rect": CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 100, height: 200)),
    "add": try NodeFunction { (a: Double, b: Double) in
        print("calculating...")
        try await Task.sleep(nanoseconds: 500_000_000)
        return "\(a) + \(b) = \(a + b)"
    },
])
