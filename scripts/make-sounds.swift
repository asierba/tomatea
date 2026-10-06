import Foundation

let sampleRate = 44_100.0

struct Noise {
    private var state: UInt64 = 0x9E3779B97F4A7C15

    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state % 1_000_000) / 500_000 - 1
    }
}

final class Track {
    private(set) var samples: [Double]

    init(seconds: Double) {
        samples = .init(repeating: 0, count: Int(seconds * sampleRate))
    }

    func add(_ sound: [Double], at start: Double, gain: Double = 1) {
        let offset = Int(start * sampleRate)
        for (index, value) in sound.enumerated() where (0..<samples.count).contains(offset + index) {
            samples[offset + index] += value * gain
        }
    }
}

struct Synth {
    private var noise = Noise()

    func bandpass(_ input: [Double], frequency: Double, q: Double) -> [Double] {
        let w = 2 * .pi * frequency / sampleRate, alpha = sin(w) / (2 * q)
        let a0 = 1 + alpha, a1 = -2 * cos(w), a2 = 1 - alpha
        var output = [Double](repeating: 0, count: input.count)
        var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0
        for i in input.indices {
            let y = (alpha * input[i] - alpha * x2 - a1 * y1 - a2 * y2) / a0
            x2 = x1; x1 = input[i]; y2 = y1; y1 = y
            output[i] = y
        }
        return output
    }

    mutating func click(frequency: Double, decay: Double, q: Double = 6) -> [Double] {
        let burst = (0..<Int(decay * 5 * sampleRate)).map { i in
            noise.next() * exp(-Double(i) / sampleRate / (decay * 0.3))
        }
        return bandpass(burst, frequency: frequency, q: q).enumerated().map { i, value in
            let t = Double(i) / sampleRate
            return value * 4 + 0.3 * sin(2 * .pi * frequency * 0.6 * t) * exp(-t / decay)
        }
    }

    func bell(frequency: Double, decay: Double) -> [Double] {
        let partials = [(1.0, 1.0), (1.47, 0.5), (2.33, 0.35), (3.12, 0.2), (4.6, 0.1)]
        return (0..<Int(decay * 6 * sampleRate)).map { i in
            let t = Double(i) / sampleRate
            let tone = partials.reduce(0) { sum, partial in
                sum + partial.1 * sin(2 * .pi * frequency * partial.0 * t) * exp(-t * partial.0.squareRoot() / decay)
            }
            return tone * min(1, t / 0.001)
        }
    }

    mutating func ticks(on track: Track, at start: Double, count: Int, interval: Double = 0.2) {
        for k in 0..<count {
            track.add(click(frequency: k.isMultiple(of: 2) ? 3200 : 2600, decay: 0.004, q: 8), at: start + Double(k) * interval, gain: 0.25)
        }
    }

    mutating func ring(on track: Track, at start: Double, duration: Double, rate: Double, frequency: Double, decay: Double) {
        let strike = bell(frequency: frequency, decay: decay)
        for k in 0..<Int(duration * rate) {
            let time = start + Double(k) / rate + noise.next() * 0.002
            track.add(strike, at: time, gain: 0.08 * (0.8 + 0.2 * noise.next()))
            track.add(click(frequency: 5000, decay: 0.002), at: time, gain: 0.06)
        }
    }
}

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

func chime(_ frequency: Double, at start: Double, duration: Double, gain: Double = 0.25) -> [Tone] {
    [(1.0, 1.0), (2.76, 0.35), (5.4, 0.15), (8.93, 0.06)].map { ratio, amplitude in
        Tone(frequency: frequency * ratio, start: start, duration: duration / ratio.squareRoot(), gain: gain * amplitude)
    }
}

func render(_ tones: [Tone]) -> [Double] {
    let length = tones.map { $0.start + $0.duration }.max()! + 0.05
    return (0..<Int(length * sampleRate)).map { index in
        let time = Double(index) / sampleRate
        return tones.reduce(0) { $0 + $1.sample(at: time) }
    }
}

func wav(_ samples: [Double]) -> Data {
    var data = Data()
    func append<T: FixedWidthInteger>(_ value: T) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
    let byteCount = UInt32(samples.count * 2)
    data.append(contentsOf: Array("RIFF".utf8)); append(36 + byteCount)
    data.append(contentsOf: Array("WAVEfmt ".utf8)); append(UInt32(16))
    append(UInt16(1)); append(UInt16(1)); append(UInt32(sampleRate)); append(UInt32(sampleRate * 2))
    append(UInt16(2)); append(UInt16(16))
    data.append(contentsOf: Array("data".utf8)); append(byteCount)
    samples.forEach { append(Int16(max(-1, min(1, $0)) * Double(Int16.max))) }
    return data
}

func render(seconds: Double, _ compose: (inout Synth, Track) -> Void) -> [Double] {
    var synth = Synth()
    let track = Track(seconds: seconds)
    compose(&synth, track)
    let peak = track.samples.map(abs).max() ?? 0
    let scale = peak > 0 ? 0.8 / peak : 1
    return track.samples.map { $0 * scale }
}

let sounds: [String: [Double]] = [
    "FewTicks": render(seconds: 1.0) { synth, track in
        synth.ticks(on: track, at: 0.02, count: 4)
    },
    "OldTimerRing": render(seconds: 3.2) { synth, track in
        synth.ring(on: track, at: 0.02, duration: 1.8, rate: 16, frequency: 1700, decay: 0.45)
    },
    "DongDing": render(chime(523.25, at: 0, duration: 1.4) + chime(783.99, at: 0.45, duration: 1.8))
]

let directory = URL(fileURLWithPath: CommandLine.arguments[1])
for (name, samples) in sounds {
    try wav(samples).write(to: directory.appendingPathComponent("\(name).wav"))
}
