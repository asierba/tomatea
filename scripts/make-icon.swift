import AppKit

let canvas = 1024
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let tileCornerRadius: CGFloat = 185

func makeContext(size: Int) -> CGContext {
    CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
}

func loadImage(at url: URL) -> CGImage {
    guard let image = NSImage(contentsOf: url)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        fatalError("Cannot read image at \(url.path)")
    }
    return image
}

func renderIcon(artwork: CGImage) -> CGImage {
    let context = makeContext(size: canvas)
    context.interpolationQuality = .high
    let tilePath = CGPath(roundedRect: tile, cornerWidth: tileCornerRadius, cornerHeight: tileCornerRadius, transform: nil)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -10), blur: 20, color: CGColor(gray: 0, alpha: 0.3))
    context.addPath(tilePath)
    context.setFillColor(.white)
    context.fillPath()
    context.restoreGState()

    context.addPath(tilePath)
    context.clip()
    context.draw(artwork, in: tile)
    return context.makeImage()!
}

func writePNG(_ image: CGImage, size: Int, to url: URL) throws {
    let context = makeContext(size: size)
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
    let data = NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
    try data.write(to: url)
}

let artwork = loadImage(at: URL(fileURLWithPath: CommandLine.arguments[1]))
let output = URL(fileURLWithPath: CommandLine.arguments[2])
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let icon = renderIcon(artwork: artwork)
for points in [16, 32, 128, 256, 512] {
    try writePNG(icon, size: points, to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
    try writePNG(icon, size: points * 2, to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try iconutil.run()
iconutil.waitUntilExit()
exit(iconutil.terminationStatus)
