import { CGRect } from "./CoreGraphics";

export class SCDisplay {
  private constructor(public readonly displayID: string) {}

  get frame(): CGRect {
    throw new Error("not implemented");
  }

  get width() {
    return this.frame.size.width;
  }

  get height() {
    return this.frame.size.height;
  }
}

export class SCRunningApplication {
  private constructor(
    public readonly processID: number,
    public readonly bundleIdentifier: string,
    public readonly applicationName: string
  ) {}
}

export class SCWindow {
  private constructor(public readonly windowID: string) {}

  get frame(): CGRect {
    throw new Error("not implemented");
  }

  /** The layer of the window relative to other windows. */
  get windowLayer(): number {
    throw new Error("not implemented");
  }

  /** A boolean value that indicates whether the window is on screen.  */
  get isOnScreen(): boolean {
    throw new Error("not implemented");
  }
}

export class SCSharableContent {
  static async getSharableContent(args: {
    includeDesktopWindows?: boolean;
    onScreenWindowsOnly?: boolean;
    onScreenWindowsOnlyAbove?: SCWindow;
    onScreenWindowsOnlyBelow?: SCWindow;
  }): Promise<SCSharableContent> {
    throw new Error("not implemented");
  }

  private constructor(
    readonly windows: SCWindow[],
    readonly displays: SCDisplay[],
    readonly applications: SCRunningApplication[]
  ) {}
}

interface SCContentFilterDisplayBase {
  display: SCDisplay;
  excludeMenuBar?: boolean;
}

interface SCContentFilterDisplayWindows extends SCContentFilterDisplayBase {
  windows: SCWindow[];
}

interface SCContentFilterDisplayExcludingWindows
  extends SCContentFilterDisplayBase {
  excludingWindows: SCWindow[];
}

interface SCContentFilterDisplayIncludingApps
  extends SCContentFilterDisplayBase {
  includingApplications: SCRunningApplication[];
  excludingWindows?: SCWindow[];
}

interface SCContentFilterDisplayExcludingApps
  extends SCContentFilterDisplayBase {
  excludingApplications: SCRunningApplication[];
  windows?: SCWindow[];
}

export class SCContentFilter {
  static forWindow(window: SCWindow): SCContentFilter {
    throw new Error("not implemented");
  }

  static forDisplay(
    args:
      | SCContentFilterDisplayWindows
      | SCContentFilterDisplayExcludingWindows
      | SCContentFilterDisplayIncludingApps
      | SCContentFilterDisplayExcludingApps
  ) {
    throw new Error("not implemented");
  }

  private constructor(
    /** https://developer.apple.com/documentation/screencapturekit/scshareablecontentstyle */
    readonly style: number
  ) {}

  get contentRect(): CGRect {
    throw new Error("not implemented");
  }

  /** The scaling factor used to translate screen points into pixels.  */
  get pointPixelScale(): number {
    throw new Error("not implemented");
  }

  includeMenuBar = false;
}

type TODO = "todo";
type CFString = TODO;
type CGColor = TODO;
type OSType = TODO;
type CMTime = TODO;

abstract class SCStreamConfigurationVars {
  abstract width: number;
  abstract height: number;
  abstract scalesToFit: boolean;
  abstract sourceRect: CGRect;
  abstract destinationRect: CGRect;
  abstract preservesAspectRatio: boolean;
  /*
BGRA
Packed little endian ARGB8888.

l10r
Packed little endian ARGB2101010.

420v
Two-plane “video” range YCbCr 4:2:0.

420f
Two-plane “full” range YCbCr 4:2:0.
  */
  abstract pixelFormat: OSType;
  abstract colorMatrix: CFString;
  abstract colorSpaceName: CFString;
  abstract backgroundColor: CGColor;
  abstract showsCursor: boolean;
  abstract shouldBeOpaque: boolean;
  abstract capturesShadowsOnly: boolean;
  abstract ignoreShadowsDisplay: boolean;
  abstract ignoreShadowsSingleWindow: boolean;
  abstract ignoreGlobalClipDisplay: boolean;
  abstract ignoreGlobalClipSingleWindow: boolean;
  abstract queueDepth: number;
  abstract minimumFrameInterval: CMTime;
  abstract captureResolution: number; // SCCaptureResolutionType
  abstract capturesAudio: boolean;
  abstract sampleRate: number;
  abstract channelCount: number;
  abstract excludesCurrentProcessAudio: boolean;
  abstract streamName: string | undefined;
}

export class SCStreamConfiguration extends SCStreamConfigurationVars {
  static create(
    args: Partial<SCStreamConfigurationVars>
  ): SCStreamConfiguration {
    throw new Error("Not implemented");
  }
}

class CGImage {
  getData(): Promise<Uint8Array> {
    throw new Error("Not implemented");
  }
}

/** https://developer.apple.com/documentation/screencapturekit/scscreenshotmanager/4251334-captureimage */
export async function captureImage(
  contentFilter: SCContentFilter,
  config: SCStreamConfiguration
): Promise<CGImage> {
  throw new Error("not implemented");
}
