import AVFoundation
import Combine
import Foundation

enum SoundEffect: Hashable {
    case select
    case plant
    case sunflower
    case shoot
    case hit
    case zombieDown
    case warning
    case pause
    case resume
    case win
    case lose

    var tone: Tone {
        switch self {
        case .select: Tone(frequencies: [620], duration: 0.08, waveform: .sine, volume: 0.18)
        case .plant: Tone(frequencies: [330, 495], duration: 0.16, waveform: .sine, volume: 0.2)
        case .sunflower: Tone(frequencies: [740, 988], duration: 0.22, waveform: .sine, volume: 0.2)
        case .shoot: Tone(frequencies: [180], duration: 0.07, waveform: .square, volume: 0.1)
        case .hit: Tone(frequencies: [115], duration: 0.06, waveform: .saw, volume: 0.14)
        case .zombieDown: Tone(frequencies: [260, 180, 110], duration: 0.3, waveform: .saw, volume: 0.18)
        case .warning: Tone(frequencies: [180, 130], duration: 0.22, waveform: .square, volume: 0.12)
        case .pause: Tone(frequencies: [520], duration: 0.12, waveform: .sine, volume: 0.18)
        case .resume: Tone(frequencies: [390, 620], duration: 0.16, waveform: .sine, volume: 0.18)
        case .win: Tone(frequencies: [523, 659, 784], duration: 0.55, waveform: .sine, volume: 0.2)
        case .lose: Tone(frequencies: [220, 165, 110], duration: 0.5, waveform: .saw, volume: 0.18)
        }
    }
}

struct Tone {
    enum Waveform {
        case sine
        case square
        case saw
    }

    let frequencies: [Double]
    let duration: Double
    let waveform: Waveform
    let volume: Float
}

@MainActor
final class SoundManager: ObservableObject {
    @Published private(set) var isMuted = false

    private var players: [SoundEffect: AVAudioPlayer] = [:]

    init() {
        configureAudioSession()
    }

    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            stopAll()
        }
    }

    func play(_ effect: SoundEffect) {
        guard !isMuted else { return }

        if players[effect] == nil {
            players[effect] = makePlayer(for: effect)
        }

        guard let player = players[effect] else { return }
        player.currentTime = 0
        player.play()
    }

    func stopAll() {
        players.values.forEach { $0.stop() }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Sound remains optional if the simulator audio session is unavailable.
        }
    }

    private func makePlayer(for effect: SoundEffect) -> AVAudioPlayer? {
        do {
            let player = try AVAudioPlayer(data: makeWAVData(tone: effect.tone))
            player.volume = effect.tone.volume
            player.prepareToPlay()
            return player
        } catch {
            return nil
        }
    }

    private func makeWAVData(tone: Tone) -> Data {
        let sampleRate = 44_100.0
        let sampleCount = Int(tone.duration * sampleRate)
        let bytesPerSample = MemoryLayout<Int16>.size
        let dataSize = sampleCount * bytesPerSample
        var data = Data()

        data.append(contentsOf: Array("RIFF".utf8))
        appendLittleEndian(UInt32(36 + dataSize), to: &data)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        appendLittleEndian(UInt32(16), to: &data)
        appendLittleEndian(UInt16(1), to: &data)
        appendLittleEndian(UInt16(1), to: &data)
        appendLittleEndian(UInt32(sampleRate), to: &data)
        appendLittleEndian(UInt32(sampleRate) * UInt32(bytesPerSample), to: &data)
        appendLittleEndian(UInt16(bytesPerSample), to: &data)
        appendLittleEndian(UInt16(16), to: &data)
        data.append(contentsOf: Array("data".utf8))
        appendLittleEndian(UInt32(dataSize), to: &data)

        for index in 0..<sampleCount {
            let time = Double(index) / sampleRate
            let progress = time / tone.duration
            let envelope = min(1, progress * 40) * min(1, (1 - progress) * 18)
            let sample = tone.frequencies.enumerated().reduce(0.0) { partial, item in
                let frequency = item.element
                let phase = time * frequency * 2 * .pi
                let wave: Double
                switch tone.waveform {
                case .sine:
                    wave = sin(phase)
                case .square:
                    wave = sin(phase) >= 0 ? 1 : -1
                case .saw:
                    wave = 2 * (phase / (2 * .pi) - floor(phase / (2 * .pi) + 0.5))
                }
                return partial + wave / Double(tone.frequencies.count)
            }
            let scaled = max(-1, min(1, sample * Double(envelope) * 0.75))
            appendLittleEndian(Int16(scaled * Double(Int16.max)), to: &data)
        }

        return data
    }

    private func appendLittleEndian<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var littleEndianValue = value.littleEndian
        withUnsafeBytes(of: &littleEndianValue) { bytes in
            data.append(contentsOf: bytes)
        }
    }
}
