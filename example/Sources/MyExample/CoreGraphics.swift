import Foundation
import NodeAPI

extension CGFloat: NodeValueConvertible, NodeValueCreatable {
  public typealias ValueType = NodeNumber
  
  public func nodeValue() throws -> any NodeAPI.NodeValue {
    try NodeNumber(Double(self))
  }
  
  public static func from(_ value: NodeAPI.NodeNumber) throws -> CGFloat {
    CGFloat(try value.double())
  }
}

extension CGPoint: NodeValueConvertible, NodeValueCreatable, NodeInspect {
  public typealias ValueType = NodeObject
  
  public func nodeValue() throws -> any NodeValue {
    try NodeObject([
      "x": x,
      "y": y,
    ])
  }
  
  public static func from(_ value: ValueType) throws -> Self {
    let x = try value.propertyAs("x", Double.self)
    let y = try value.propertyAs("y", Double.self)
    return Self(x: x, y: y)
  }
  
  func nodeInspect(_ inspector: Inspector) throws -> String {
    "x: \(try inspector.stylize(inferType: x)) y: \(try inspector.stylize(inferType: y))"
  }
}


extension CGSize: NodeValueConvertible, NodeValueCreatable, NodeInspect {
  func nodeInspect(_ inspector: Inspector) throws -> String {
    "\(try inspector.stylize(inferType: width))x\(try inspector.stylize(inferType: height))"
  }
  
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

extension CGRect: NodeValueConvertible, NodeValueCreatable, NodeInspect {
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
  
  func nodeInspect(_ inspector: Inspector) throws -> String {
    "[\(try inspector.inspect(origin as NodeInspect)) \(try inspector.inspect(size as NodeInspect))]"
  }
}
