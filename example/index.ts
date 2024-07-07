async function time<T>(name: string, fn: () => T | Promise<T>) {
  console.time(name);
  const result = await fn();
  console.timeEnd(name);
  return result;
}

async function main() {
  console.log("start", new Date());
  const { SC, CGRect } = await time("import", async () => {
    const SC = await import("./ScreenCaptureKit.js");
    const { CGRect } = await import("./CoreGraphics.js");
    return {
      SC,
      CGRect,
    };
  });

  const sharable = await time("getSharableContent", () =>
    SC.SCSharableContent.getSharableContent({
      onScreenWindowsOnly: true,
    })
  );
  const biggestWindow = await time(
    "biggestWindow",
    () =>
      sharable.windows.sort(
        (a, b) => CGRect.area(b.frame) - CGRect.area(a.frame)
      )[0]
  );
  console.log(biggestWindow);

  const filter = await time("createFilter", () =>
    SC.SCContentFilter.forWindow(biggestWindow)
  );
  console.log(filter);

  const config = await time("createConfig", () =>
    SC.SCStreamConfiguration.create()
  );
  config.size = filter.scaledContentSize;
  console.log(config);

  const image = await time("captureImage", () => SC.captureImage(filter));
  console.log(image);

  const imageData = await time("getImageData", () => image.getImageData());

  const fs = await import("node:fs/promises");
  await time("write image.png", () => fs.writeFile("image.png", imageData));
}

main();
