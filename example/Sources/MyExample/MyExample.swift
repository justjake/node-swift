import NodeAPI
import ScreenCaptureKit
import Foundation

#NodeModule(exports: [
    "nums": [Double.pi.rounded(.down), Double.pi.rounded(.up)],
    "str": String(repeating: "NodeSwift! ", count: 3),
    "rect": CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 100, height: 200)),
    "add": try NodeFunction { (a: Double, b: Double) in
        print("calculating...")
        try await Task.sleep(nanoseconds: 500_000_000)
        return "\(a) + \(b) = \(a + b)"
    },
    "getSharableContent": try NodeFunction { (args: NodeObject) async throws in
      if #available(macOS 12.3, *) {
      return try await SCShareableContent.getNodeSharableContent(nodeArgs: args)
    } else {
      throw MyError.unsupported("Not available on the current platform (requires macOS >= 12.3)")
    }
    }
])
