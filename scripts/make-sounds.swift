import Foundation

let sampleRate = 44_100.0

struct Tone {
    let frequency: Double
    let start: Double
    let duration: Double
    let gain: Double
    var attack = 0.005

    func sample(at time: Double) -> Double {
        let t = time - start
        guard t >= 0, t <= duration else { return 0 }
        let envelope = t < attack
            ? gain * t / attack
            : gain * pow(0.0001 / gain, (t - attack) / (duration - attack))
        return envelope * sin(2 * .pi * frequency * t)
    }
}

func bell(_ frequency: Double, at start: Double, duration: Double, gain: Double = 0.25) -> [Tone] {
    [(1.0, 1.0), (2.76, 0.35), (5.4, 0.15), (8.93, 0.06)].map { ratio, amplitude in
        Tone(frequency: frequency * ratio, start: start, duration: duration / ratio.squareRoot(), gain: gain * amplitude)
    }
}

func marimba(_ frequency: Double, at start: Double, gain: Double = 0.35) -> [Tone] {
    [
        Tone(frequency: frequency, start: start, duration: 0.5, gain: gain),
        Tone(frequency: frequency * 4, start: start, duration: 0.12, gain: gain * 0.3)
    ]
}

func render(_ tones: [Tone]) -> [Int16] {
    let length = tones.map { $0.start + $0.duration }.max()! + 0.05
    return (0..<Int(length * sampleRate)).map { index in
        let time = Double(index) / sampleRate
        let value = tones.reduce(0) { $0 + $1.sample(at: time) }
        return Int16(max(-1, min(1, value)) * Double(Int16.max))
    }
}

func wav(_ samples: [Int16]) -> Data {
    var data = Data()
    func append<T: FixedWidthInteger>(_ value: T) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
    let byteCount = UInt32(samples.count * 2)
    data.append(contentsOf: Array("RIFF".utf8)); append(36 + byteCount)
    data.append(contentsOf: Array("WAVEfmt ".utf8)); append(UInt32(16))
    append(UInt16(1)); append(UInt16(1)); append(UInt32(sampleRate)); append(UInt32(sampleRate * 2))
    append(UInt16(2)); append(UInt16(16))
    data.append(contentsOf: Array("data".utf8)); append(byteCount)
    samples.forEach { append($0) }
    return data
}

let sounds: [String: [Tone]] = [
    "RisingArpeggio": [523.25, 659.25, 783.99, 1046.5].enumerated().flatMap { marimba($1, at: Double($0) * 0.11) },
    "DingDong": bell(659.25, at: 0, duration: 1.4) + bell(523.25, at: 0.45, duration: 1.8),
    "DongDing": bell(523.25, at: 0, duration: 1.4) + bell(783.99, at: 0.45, duration: 1.8)
]

let directory = URL(fileURLWithPath: CommandLine.arguments[1])
for (name, tones) in sounds {
    try wav(render(tones)).write(to: directory.appendingPathComponent("\(name).wav"))
}
