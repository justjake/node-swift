import NodeAPI

@NodeActor public func obj(_ properties: NodeObjectPropertyList = [:]) throws -> NodeObject {
  try NodeObject(properties)
}

enum MyError: Error {
  case missingProperty(String)
  case unsupported(String)
}

extension NodeObject {
  @NodeActor public func propertyAs<T: AnyNodeValueCreatable>(_ property: String, _ type: T.Type) throws -> T {
    guard let value = try self.property(forKey: property).as(type) else {
      throw MyError.missingProperty("Cannot convert property .\(property) to type '\(type)': missing or undefined")
    }
    return value
  }
  
  public static func X(_ properties: NodeObjectPropertyList = [:]) throws -> NodeObject {
    try NodeObject(properties)
  }
}
