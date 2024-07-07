import CoreGraphics
import NodeAPI
import ScreenCaptureKit

@available(macOS 12.3, *)
extension SCDisplay: NodeValueConvertible {
  public func nodeValue() throws -> any NodeAPI.NodeValue {
    try NodeObject(coercing: Display(self))
  }
}

@available(macOS 12.3, *)
@NodeClass final class Display: NodeClass {
  let inner: SCDisplay

  init(_ inner: SCDisplay) {
    self.inner = inner
  }

  @NodeProperty var displayID: Int {
    Int(inner.displayID)
  }

  @NodeProperty var frame: CGRect {
    inner.frame
  }

  @NodeProperty var width: Int {
    inner.width
  }

  @NodeProperty var height: Int {
    inner.height
  }

  @NodeName(NodeSymbol.utilInspectCustom)
  @NodeMethod
  func nodeInspect(_ inspector: Inspector) throws -> String {
    let name = try inspector.stylize(special: Display.name)
    let displayID = try inspector.stylize(inferType: self.displayID)
    let width = try inspector.stylize(inferType: self.width)
    let height = try inspector.stylize(inferType: self.height)
    return "\(name) { displayID: \(displayID) \(width)x\(height) }"
  }
}

@available(macOS 12.3, *)
@NodeClass final class RunningApplication {
  let inner: SCRunningApplication

  init(_ inner: SCRunningApplication) {
    self.inner = inner
  }

  @NodeProperty var processID: Int {
    Int(inner.processID)
  }

  @NodeProperty var bundleIdentifier: String {
    inner.bundleIdentifier
  }

  @NodeProperty var applicationName: String {
    inner.applicationName
  }

  @NodeName(NodeSymbol.utilInspectCustom)
  @NodeMethod
  @NodeActor
  func nodeInspect(_ inspector: Inspector) throws -> String {
    try inspector.nodeClass(
      value: self,
      paths: ("applicationName", \.applicationName),
      ("bundleIdentifier", \.bundleIdentifier),
      ("processId", \.processID)
    )
  }
}

@available(macOS 12.3, *)
@NodeClass final class Window {
  let inner: SCWindow
  
  private var lastMeasuredShadow: (windowSize: CGSize, shadowSize: CGSize)? = nil
  
  init(_ inner: SCWindow) {
    self.inner = inner
  }

  @NodeProperty var owningApplication: RunningApplication? {
    guard let owningApplication = inner.owningApplication else {
      return nil
    }
    return RunningApplication(owningApplication)
  }

  @NodeProperty var windowID: Int {
    Int(inner.windowID)
  }

  @NodeProperty var frame: CGRect {
    inner.frame
  }

  @NodeProperty var windowLayer: Int {
    inner.windowLayer
  }

  @NodeProperty var isOnScreen: Bool {
    inner.isOnScreen
  }

  @NodeMethod func sizeWithShadow() -> CGSize? {
    let currentSize = frame.size
    
    if let measured = lastMeasuredShadow, measured.windowSize == currentSize {
      return measured.shadowSize
    }
    
    // https://developer.apple.com/documentation/coregraphics/1454852-cgwindowlistcreateimage
    // Appears to be the only way we can ask for the shadow bounds:
    // capture the shadow only with null bounds then measure the image
    // CGImageRef CGWindowListCreateImage(CGRect screenBounds, CGWindowListOption listOption, CGWindowID windowID, CGWindowImageOption imageOption);
    let imageOption = [CGWindowImageOption.onlyShadows, CGWindowImageOption.nominalResolution]
    guard
      let image = CGWindowListCreateImage(
        CGRectNull, CGWindowListOption.optionIncludingWindow, inner.windowID,
        [CGWindowImageOption.onlyShadows, CGWindowImageOption.nominalResolution])
    else {
      return nil
    }
    
    let currentShadowSize = image.size
    lastMeasuredShadow = (currentSize, currentShadowSize)
    return currentShadowSize
  }

  @NodeName(NodeSymbol.utilInspectCustom)
  @NodeMethod
  @NodeActor
  func nodeInspect(_ inspector: Inspector) throws -> String {
    try inspector.nodeClass(
      value: self,
      paths: ("windowId", \.windowID),
      ("owningApplication.bundleIdentifier", \.inner.owningApplication?.bundleIdentifier),
      ("frame", { try inspector.inspect($0.frame) })
    )
  }
}

@available(macOS 12.3, *)
struct ContentFilterArgs: NodeValueCreatable {
  typealias ValueType = NodeObject

  static func from(_ value: NodeAPI.NodeObject) throws -> ContentFilterArgs {
    Self(
      window: try value["window"].as(Window.self),
      includeWindowShadow: try value["includeWindowShadow"].as(Bool.self),
      display: try value["display"].as(Display.self),
      excludeMenuBar: try value["excludeMenuBar"].as(Bool.self),
      windows: try value["windows"].as([Window].self),
      excludingWindows: try value["excludingWindows"].as([Window].self),
      includingApplications: try value["includingApplications"].as([RunningApplication].self),
      excludingApplications: try value["excludingApplications"].as([RunningApplication].self)
    )
  }

  let window: Window?
  let includeWindowShadow: Bool?
  let display: Display?
  let excludeMenuBar: Bool?
  let windows: [Window]?
  let excludingWindows: [Window]?
  let includingApplications: [RunningApplication]?
  let excludingApplications: [RunningApplication]?

  @NodeActor func contentFilter() throws -> ContentFilter {
    let contentFilter = try baseContentFilter()
    if window != nil {
      contentFilter.window = window
      contentFilter.includeSingleWindowShadows = includeWindowShadow ?? false
    } else {
      contentFilter.display = display
    }
    
    if #available(macOS 14.2, *) {
      if let excludeMenuBar = self.excludeMenuBar {
        contentFilter.inner.includeMenuBar = !excludeMenuBar
      }
    }
    
    return contentFilter
  }

  @NodeActor private func baseContentFilter() throws -> ContentFilter {
    // https://forums.developer.apple.com/forums/thread/743615
    _ = CGMainDisplayID()

    if let window = self.window {
      return ContentFilter(SCContentFilter(desktopIndependentWindow: window.inner))
    }

    guard let display = self.display?.inner else {
      throw MyError.missingProperty("Must either pass a window or a display")
    }

    let excludingWindows = self.excludingWindows?.map({ $0.inner }) ?? []
    let includingWindows = self.windows?.map({ $0.inner }) ?? []

    if let excludingApplications = self.excludingApplications?.map({ $0.inner }) {
      return ContentFilter(
        SCContentFilter(
          display: display, excludingApplications: excludingApplications,
          exceptingWindows: includingWindows))
    }

    if let includingApplications = self.includingApplications?.map({ $0.inner }) {
      return ContentFilter(
        SCContentFilter(
          display: display, including: includingApplications, exceptingWindows: excludingWindows))
    }

    if self.windows != nil {
      return ContentFilter(SCContentFilter(display: display, including: includingWindows))
    }

    return ContentFilter(SCContentFilter(display: display, excludingWindows: excludingWindows))
  }
}

@available(macOS 12.3, *)
@NodeClass final class ContentFilter {
  let inner: SCContentFilter
  var includeSingleWindowShadows = false
  var window: Window? = nil
  var display: Display? = nil

  init(_ inner: SCContentFilter) {
    self.inner = inner
  }

  @NodeProperty var contentRect: CGRect {
    inner.contentRect
  }

  @NodeProperty var pointPixelScale: Double {
    Double(inner.pointPixelScale)
  }

  @NodeProperty var scaledContentSize: CGSize {
    if let window = self.window, includeSingleWindowShadows, let sizeWithShadow = window.sizeWithShadow() {
      return sizeWithShadow.scaled(by: pointPixelScale)
    }
    return contentRect.size.scaled(by: pointPixelScale)
  }

  @available(macOS 14.2, *)
  @NodeProperty var includeMenuBar: Bool {
    inner.includeMenuBar
  }

  @available(macOS 14.0, *)
  @NodeActor
  @NodeMethod
  func createStreamConfiguration() -> StreamConfiguration {
    let config = StreamConfiguration.highQuality()
    config.captureResolution = .best
    config.size = scaledContentSize
    config.scalesToFit = false
    config.ignoreShadowsSingleWindow = !includeSingleWindowShadows
    return config
  }

  @NodeName(NodeSymbol.utilInspectCustom)
  @NodeMethod
  @NodeActor
  func nodeInspect(_ inspector: Inspector) throws -> String {
    try inspector.nodeClass(
      value: self,
      paths: ("contentRect", \.contentRect),
      ("pointPixelScale", \.pointPixelScale)
    )
  }
}

@available(macOS 12.3, *)
extension SCShareableContent: NodeValueConvertible {
  public func nodeValue() throws -> any NodeAPI.NodeValue {
    try NodeObject([
      "displays": self.displays,
      "applications": self.applications.map { inner in RunningApplication(inner) },
      "windows": self.windows.map { inner in Window(inner) },
    ])
  }

  /*
  includeDesktopWindows?: boolean;
  onScreenWindowsOnly?: boolean;
  onScreenWindowsOnlyAbove?: SCWindow;
  onScreenWindowsOnlyBelow?: SCWindow;
  */
  @NodeActor public static func getNodeSharableContent(nodeArgs: NodeObject? = nil) async throws
    -> SCShareableContent
  {
    let includeDesktopWindows = try nodeArgs?["includeDesktopWindows"].as(Bool.self) ?? false

    if let onScreenWindowsOnlyAbove = try nodeArgs?["onScreenWindowsOnlyAbove"].as(Window.self) {
      return try await self.excludingDesktopWindows(
        !includeDesktopWindows, onScreenWindowsOnlyAbove: onScreenWindowsOnlyAbove.inner)
    }

    if let onScreenWindowsOnlyBelow = try nodeArgs?["onScreenWindowsOnlyBelow"].as(Window.self) {
      return try await self.excludingDesktopWindows(
        !includeDesktopWindows, onScreenWindowsOnlyBelow: onScreenWindowsOnlyBelow.inner)

    }

    if let onScreenWindowsOnly = try nodeArgs?["onScreenWindowsOnly"].as(Bool.self) {
      return try await self.excludingDesktopWindows(
        !includeDesktopWindows, onScreenWindowsOnly: onScreenWindowsOnly)
    }

    if !includeDesktopWindows {
      return try await self.excludingDesktopWindows(
        !includeDesktopWindows, onScreenWindowsOnly: false)

    }

    return try await self.current
  }
}

extension SCCaptureResolutionType: NodeValueConvertible, CustomDebugStringConvertible, NodeInspect {
  public var caseName: String {
    switch self {
    case .automatic: "automatic"
    case .best: "best"
    case .nominal: "nonimal"
    @unknown default: "unknown"
    }
  }

  func nodeInspect(_ inspector: Inspector) throws -> String {
    "\(try inspector.stylize(inferType: rawValue)) (\(type(of: self)).\(caseName))"
  }

  public var debugDescription: String {
    return "\(type(of: self))[\(rawValue) (\(caseName))]"
  }

  public func nodeValue() throws -> any NodeAPI.NodeValue {
    try NodeNumber(Double(self.rawValue))
  }
}

extension UInt32: NodeValueConvertible, NodeValueCreatable {
  public typealias ValueType = NodeNumber

  public func nodeValue() throws -> any NodeAPI.NodeValue {
    try NodeNumber(Double(self))
  }

  public static func from(_ value: NodeAPI.NodeNumber) throws -> UInt32 {
    UInt32(try value.double())
  }
}

@available(macOS 14.0, *)
@NodeClass final class StreamConfiguration: SpecificProxyContainer, NodeInspect {
  typealias Wrapped = SCStreamConfiguration
  let inner: SCStreamConfiguration

  static func highQuality() -> StreamConfiguration {
    let config = SCStreamConfiguration()
    config.scalesToFit = false
    config.captureResolution = .best
    return Self(config)
  }

  init(_ inner: SCStreamConfiguration) {
    self.inner = inner
  }

  @NodeProperty @Proxy(\.width) var width: Int
  @NodeProperty @Proxy(\.height) var height: Int
  @NodeProperty @Proxy(\.showsCursor) var showsCursor: Bool
  @NodeProperty @Proxy(\.captureResolution) var captureResolution: SCCaptureResolutionType
  @NodeProperty @Proxy(\.scalesToFit) var scalesToFit: Bool
  @NodeProperty @Proxy(\.pixelFormat) var pixelFormat: OSType
  @NodeProperty @Proxy(\.ignoreShadowsDisplay) var ignoreShadowsDisplay: Bool
  @NodeProperty @Proxy(\.ignoreShadowsSingleWindow) var ignoreShadowsSingleWindow: Bool
  @NodeProperty @Proxy(\.ignoreGlobalClipDisplay) var ignoreGlobalClipDisplay: Bool
  @NodeProperty @Proxy(\.ignoreGlobalClipSingleWindow) var ignoreGlobalClipSingleWindow: Bool
  @NodeProperty @Proxy(\.sourceRect) var sourceRect: CGRect
  @NodeProperty @Proxy(\.destinationRect) var destinationRect: CGRect
  @NodeProperty @Proxy(\.shouldBeOpaque) var shouldBeOpaque: Bool

  @NodeProperty var size: CGSize {
    get {
      CGSize(width: width, height: height)
    }
    set {
      width = Int(newValue.width)
      height = Int(newValue.height)
    }
  }

  @NodeName(NodeSymbol.utilInspectCustom)
  @NodeMethod
  @NodeActor
  func nodeInspect(_ inspector: Inspector) throws -> String {
    try inspector.nodeClass(
      value: self,
      paths:  // Output
      ("size", \.size),
      ("captureResolution", \.captureResolution),
      ("scalesToFit", \.scalesToFit),
      ("sourceRect", \.sourceRect),
      ("destinationRect", \.destinationRect),
      // Input
      ("showsCursor", \.showsCursor),
      ("shouldBeOpaque", \.shouldBeOpaque),
      ("ignoreShadowsDisplay", \.ignoreShadowsDisplay),
      ("ignoreShadowsSingleWindow", \.ignoreShadowsSingleWindow)
    )
  }
}
