import AppKit

struct Pixels {
    let width: Int
    let height: Int
    var rgba: [UInt8]

    init(image: CGImage) {
        width = image.width
        height = image.height
        rgba = [UInt8](repeating: 0, count: width * height * 4)
        let context = Pixels.context(data: &rgba, width: width, height: height)
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }

    static func context(data: UnsafeMutableRawPointer?, width: Int, height: Int) -> CGContext {
        CGContext(
            data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
    }

    func isPaper(_ index: Int) -> Bool {
        let r = Int(rgba[index * 4]), g = Int(rgba[index * 4 + 1]), b = Int(rgba[index * 4 + 2])
        return min(r, g, b) > 200 && max(r, g, b) - min(r, g, b) < 30
    }

    mutating func removePaperAroundDrawing() {
        var visited = [Bool](repeating: false, count: width * height)
        var pending = [Int]()
        for x in 0..<width { pending += [x, (height - 1) * width + x] }
        for y in 0..<height { pending += [y * width, y * width + width - 1] }
        while let index = pending.popLast() {
            guard !visited[index], isPaper(index) else { continue }
            visited[index] = true
            for offset in 0..<4 { rgba[index * 4 + offset] = 0 }
            let x = index % width, y = index / width
            if x > 0 { pending.append(index - 1) }
            if x < width - 1 { pending.append(index + 1) }
            if y > 0 { pending.append(index - width) }
            if y < height - 1 { pending.append(index + width) }
        }
    }

    func drawingBounds() -> CGRect {
        var minX = width, minY = height, maxX = 0, maxY = 0
        for index in 0..<(width * height) where rgba[index * 4 + 3] > 0 {
            let x = index % width, y = index / width
            minX = min(minX, x); maxX = max(maxX, x)
            minY = min(minY, y); maxY = max(maxY, y)
        }
        let side = max(maxX - minX, maxY - minY)
        return CGRect(x: (minX + maxX - side) / 2, y: (minY + maxY - side) / 2, width: side, height: side)
    }

    func recolored(_ transform: (Double, Double, Double) -> (Double, Double, Double)) -> Pixels {
        var copy = self
        for index in 0..<(width * height) where rgba[index * 4 + 3] > 0 {
            let alpha = Double(rgba[index * 4 + 3]) / 255
            let (r, g, b) = transform(
                Double(rgba[index * 4]) / alpha,
                Double(rgba[index * 4 + 1]) / alpha,
                Double(rgba[index * 4 + 2]) / alpha
            )
            copy.rgba[index * 4] = UInt8(min(255, max(0, r * alpha)))
            copy.rgba[index * 4 + 1] = UInt8(min(255, max(0, g * alpha)))
            copy.rgba[index * 4 + 2] = UInt8(min(255, max(0, b * alpha)))
        }
        return copy
    }

    func writePNG(cropping bounds: CGRect, size: Int, to url: URL) throws {
        var data = rgba
        let image = Pixels.context(data: &data, width: width, height: height).makeImage()!
        let cropped = image.cropping(to: bounds)!
        let output = Pixels.context(data: nil, width: size, height: size)
        output.interpolationQuality = .high
        output.draw(cropped, in: CGRect(x: 0, y: 0, width: size, height: size))
        let png = NSBitmapImageRep(cgImage: output.makeImage()!).representation(using: .png, properties: [:])!
        try png.write(to: url)
    }
}

func grey(r: Double, g: Double, b: Double) -> (Double, Double, Double) {
    let level = (0.3 * r + 0.59 * g + 0.11 * b) * 0.75 + 70
    return (level, level, level)
}

func isRed(r: Double, g: Double, b: Double) -> Bool {
    r > g + 40 && r > b + 40
}

func unripe(r: Double, g: Double, b: Double) -> (Double, Double, Double) {
    isRed(r: r, g: g, b: b) ? (g * 0.55 + 20, r * 0.66, b * 0.45) : (r, g, b)
}

func blue(r: Double, g: Double, b: Double) -> (Double, Double, Double) {
    isRed(r: r, g: g, b: b) ? (g * 0.5 + 20, g * 0.8 + 40, r * 0.85) : (r, g, b)
}

guard let source = NSImage(contentsOfFile: CommandLine.arguments[1])?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fatalError("Cannot read \(CommandLine.arguments[1])")
}
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2])
let size = 64

var tomato = Pixels(image: source)
tomato.removePaperAroundDrawing()
let bounds = tomato.drawingBounds()

try tomato.writePNG(cropping: bounds, size: size, to: outputDirectory.appendingPathComponent("MenuBarFocus.png"))
try tomato.recolored(unripe).writePNG(cropping: bounds, size: size, to: outputDirectory.appendingPathComponent("MenuBarShortBreak.png"))
try tomato.recolored(blue).writePNG(cropping: bounds, size: size, to: outputDirectory.appendingPathComponent("MenuBarLongBreak.png"))
try tomato.recolored(grey).writePNG(cropping: bounds, size: size, to: outputDirectory.appendingPathComponent("MenuBarIdle.png"))
