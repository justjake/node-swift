import ScreenCaptureKit
import NodeAPI

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

  @NodeName("potato")
  @NodeProperty
  var potatoInternal: String {
    "hi"
  }
  
  @NodeProperty var displayID: String {
    inner.displayID.formatted()
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
}

@available(macOS 12.3, *)
@NodeClass final class Window {
  let inner: SCWindow
  
  init(_ inner: SCWindow) {
    self.inner = inner
  }
  
  @NodeProperty var windowID: String {
    inner.windowID.formatted()
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
}

@available(macOS 12.3, *)
@NodeClass final class ContentFilter {
  let inner: SCContentFilter
  
  init(_ inner: SCContentFilter) {
    self.inner = inner
  }
  
  @NodeProperty var contentRect: CGRect {
    inner.contentRect
  }
  
  @NodeProperty var pointPixelScale: Double {
    Double(inner.pointPixelScale)
  }
}

@available(macOS 12.3, *)
extension SCShareableContent: NodeValueConvertible {
  public func nodeValue() throws -> any NodeAPI.NodeValue {
    try NodeObject([
      "displays": self.displays.map { inner in try inner.nodeValue() },
      "applications": self.applications.map { inner in RunningApplication(inner) },
      "windows": self.windows.map { inner in Window(inner) }
    ])
  }
  
  /*
  includeDesktopWindows?: boolean;
  onScreenWindowsOnly?: boolean;
  onScreenWindowsOnlyAbove?: SCWindow;
  onScreenWindowsOnlyBelow?: SCWindow;
  */
  @NodeActor public static func getNodeSharableContent(nodeArgs: NodeObject) async throws -> SCShareableContent {
    let includeDesktopWindows = try nodeArgs["includeDesktopWindows"].as(Bool.self) ?? false
    let onScreenWindowsOnly = try nodeArgs["onScreenWindowsOnly"].as(Bool.self)
    
    if let onScreenWindowsOnlyAbove = try nodeArgs["onScreenWindowsOnlyAbove"].as(Window.self) {
      return try await self.excludingDesktopWindows(!includeDesktopWindows, onScreenWindowsOnlyAbove: onScreenWindowsOnlyAbove.inner)
    }
    
    if let onScreenWindowsOnlyBelow = try nodeArgs["onScreenWindowsOnlyBelow"].as(Window.self) {
      return try await self.excludingDesktopWindows(!includeDesktopWindows, onScreenWindowsOnlyBelow: onScreenWindowsOnlyBelow.inner)

    }
    
    if let onScreenWindowsOnly = try nodeArgs["onScreenWindowsOnly"].as(Bool.self) {
      return try await self.excludingDesktopWindows(!includeDesktopWindows, onScreenWindowsOnly: onScreenWindowsOnly)
    }
    
    if !includeDesktopWindows {
      return try await self.excludingDesktopWindows(!includeDesktopWindows, onScreenWindowsOnly: false)

    }
    
    return try await self.current
  }
}
