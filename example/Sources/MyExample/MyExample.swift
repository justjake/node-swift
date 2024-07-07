import Foundation
import NodeAPI
import ScreenCaptureKit

@available(macOS 14.0, *)
#NodeModule(exports: [
  "nums": [Double.pi.rounded(.down), Double.pi.rounded(.up)],
  "str": String(repeating: "NodeSwift! ", count: 3),
  "rect": CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 100, height: 200)),
  "add": try NodeFunction { (a: Double, b: Double) in
    print("calculating...")
    try await Task.sleep(nanoseconds: 500_000_000)
    return "\(a) + \(b) = \(a + b)"
  },
  "getSharableContent": try NodeFunction { (args: NodeArguments) async throws in
    return try await SCShareableContent.getNodeSharableContent(
      nodeArgs: args.first?.as(NodeObject.self))
  },
  "createStreamConfiguration": try NodeFunction {
    let base = SCStreamConfiguration()
    return StreamConfiguration(base)
  },
  "createContentFilter": try NodeFunction { (args: ContentFilterArgs) throws in
    return try args.contentFilter()
  },
  "captureImage": try NodeFunction { (filter: ContentFilter, config: StreamConfiguration?) async throws in
    let finalConfig = config ?? filter.createStreamConfiguration()
    let image = try await SCScreenshotManager.captureImage(contentFilter: filter.inner, configuration: finalConfig.inner)
    return NodeImage(image)
  }
])
