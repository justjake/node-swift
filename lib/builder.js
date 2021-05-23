const { promises: { mkdir, rm, stat, rename }, existsSync } = require("fs");
const { spawnSync } = require("child_process");
const { forceSymlink } = require("./utils");
const path = require("path");

const buildDir = "build";

async function clean() {
    await rm(buildDir, { recursive: true, force: true });
}

async function build(mode, product) {
    const dump = spawnSync(
        "swift", ["package", "dump-package"],
        { stdio: ["inherit", "pipe", "inherit"] }
    );
    if (dump.status !== 0) {
        process.exit(dump.status);
    }
    const parsedPackage = JSON.parse(dump.stdout);
    if (typeof product === "undefined") {
        const products = parsedPackage.products;
        if (products.length === 0) {
            throw new Error("No products found in Swift Package");
        } else if (products.length === 1) {
            product = products[0].name;
        } else {
            throw new Error(
                "Found more than 1 product in the Swift Package. Consider " +
                "specifying which product should be built via the swift.product " +
                "field in package.json."
            );
        }
    }

    let libName;
    let ldflags;
    switch (process.platform) {
        case "darwin":
            libName = "libNodeSwiftHost.dylib";
            ldflags = [
                "-Xlinker", "-undefined",
                "-Xlinker", "dynamic_lookup"
            ];
            break;
        case "linux":
            libName = "libNodeSwiftHost.so";
            ldflags = [
                "-Xlinker", "-undefined"
            ];
            break;
        case "win32":
            libName = "NodeSwiftHost.dll";
            // TODO: Figure out which flags we need on Windows
            ldflags = [];
            break;
        default:
            throw new Error(
                `The platform ${process.platform} is currently unsupported by node-swift.`
            );
    }

    // the NodeSwiftHost package acts as a "host" which uses the user's
    // package as a dependency (passed via env vars). This allows us to
    // move any flags and boilerplate that we need into the host package,
    // keeping the user's package simple.
    // TODO: Maybe simplify this by making NodeAPI a dynamic target, which
    // can serve as where we put the flags?
    const result = spawnSync(
        "swift", 
        [
            "build",
            "-c", mode,
            "--product", "NodeSwiftHost",
            "--build-path", buildDir,
            "--package-path", path.join(__dirname, "..", "NodeSwiftHost"),
            ...ldflags
        ],
        { 
            stdio: "inherit", 
            env: { 
                "NODE_SWIFT_TARGET_PACKAGE": parsedPackage.name,
                "NODE_SWIFT_TARGET_PATH": process.cwd(),
                "NODE_SWIFT_TARGET_NAME": product
            }
        }
    );
    if (result.status !== 0) {
        process.exit(result.status);
    }

    await rename(
        path.join(buildDir, mode, libName),
        path.join(buildDir, mode, `${product}.node`)
    );

    await forceSymlink(
        path.join(mode, `${product}.node`), 
        path.join(buildDir, `${product}.node`)
    );
}

module.exports = { clean, build };