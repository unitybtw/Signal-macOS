import AVFoundation
import CoreAudio
import Combine
import AppKit

class AudioSynthesizer: ObservableObject {
    static let shared = AudioSynthesizer()
    
    @Published var selectedTheme: AudioTheme = .realNKCream {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "SelectedAudioTheme")
        }
    }
    
    @Published var isMuted: Bool = false {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: "IsMuted")
        }
    }
    
    @Published var volume: Double = 0.5 {
        didSet {
            UserDefaults.standard.set(volume, forKey: "Volume")
            engine.mainMixerNode.outputVolume = Float(volume)
        }
    }
    
    @Published var hasPermission: Bool = false
    @Published var isPopoverVisible: Bool = false
    
    @Published var isMouseSoundEnabled: Bool = false {
        didSet { UserDefaults.standard.set(isMouseSoundEnabled, forKey: "IsMouseSoundEnabled") }
    }
    @Published var isSmartMuteEnabled: Bool = false {
        didSet { UserDefaults.standard.set(isSmartMuteEnabled, forKey: "IsSmartMuteEnabled") }
    }
    @Published var isOrganicPitchEnabled: Bool = true {
        didSet { UserDefaults.standard.set(isOrganicPitchEnabled, forKey: "IsOrganicPitchEnabled") }
    }
    @Published var isSmartMutedActive: Bool = false
    
    private let engine = AVAudioEngine()
    private let reverbNode = AVAudioUnitReverb()
    
    struct SynthChannel {
        let player: AVAudioPlayerNode
        let pitch: AVAudioUnitTimePitch
        let mixer: AVAudioMixerNode
    }
    
    private let channelCount = 10
    private var channels: [SynthChannel] = []
    private var currentChannelIndex = 0
    private var recentKeyTimestamps: [Date] = []
    
    private let audioQueue = DispatchQueue(label: "com.signal.audio", qos: .userInteractive)

    private var soundPacks: [AudioTheme: SoundPack] = [:]
    
    init() {
        if let savedThemeRaw = UserDefaults.standard.string(forKey: "SelectedAudioTheme"),
           let savedTheme = AudioTheme(rawValue: savedThemeRaw) {
            self.selectedTheme = savedTheme
        }
        self.isMuted = UserDefaults.standard.bool(forKey: "IsMuted")
        
        if UserDefaults.standard.object(forKey: "Volume") != nil {
            self.volume = UserDefaults.standard.double(forKey: "Volume")
        }
        
        setupEngine()
        loadAllPacks()
    }
    
    private func setupEngine() {
        _ = engine.mainMixerNode
        
        reverbNode.loadFactoryPreset(.largeHall)
        reverbNode.wetDryMix = 0
        engine.attach(reverbNode)
        
        engine.connect(engine.mainMixerNode, to: reverbNode, format: nil)
        engine.connect(reverbNode, to: engine.outputNode, format: nil)
        
        for _ in 0..<channelCount {
            let player = AVAudioPlayerNode()
            let pitch = AVAudioUnitTimePitch()
            let mixer = AVAudioMixerNode()
            
            engine.attach(player)
            engine.attach(pitch)
            engine.attach(mixer)
            
            engine.connect(player, to: pitch, format: nil)
            engine.connect(pitch, to: mixer, format: nil)
            engine.connect(mixer, to: engine.mainMixerNode, format: nil)
            
            channels.append(SynthChannel(player: player, pitch: pitch, mixer: mixer))
        }
        
        engine.mainMixerNode.outputVolume = Float(volume)
        
        do {
            try engine.start()
        } catch {
            print("AudioEngine start error: \(error)")
        }
    }
    
    private func loadAllPacks() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!
        for theme in AudioTheme.allCases {
            if let pack = SoundPack.load(folderName: theme.folderName, format: format) {
                soundPacks[theme] = pack
            }
        }
    }
    
    func playKeySound(keyCode: Int64, isDown: Bool = true) {
        if isMuted { return }
        
        audioQueue.async {
            guard let pack = self.soundPacks[self.selectedTheme] else { return }
            let buffer: AVAudioPCMBuffer
            
            if isDown {
                switch keyCode {
                case 49: buffer = pack.space ?? pack.genericR0 ?? AVAudioPCMBuffer()
                case 36: buffer = pack.enter ?? pack.genericR0 ?? AVAudioPCMBuffer()
                case 51: buffer = pack.backspace ?? pack.genericR0 ?? AVAudioPCMBuffer()
                default:
                    // Randomize slightly between generic rows if they exist
                    let rand = Int.random(in: 0...4)
                    switch rand {
                    case 0: buffer = pack.genericR0 ?? AVAudioPCMBuffer()
                    case 1: buffer = pack.genericR1 ?? pack.genericR0 ?? AVAudioPCMBuffer()
                    case 2: buffer = pack.genericR2 ?? pack.genericR0 ?? AVAudioPCMBuffer()
                    case 3: buffer = pack.genericR3 ?? pack.genericR0 ?? AVAudioPCMBuffer()
                    case 4: buffer = pack.genericR4 ?? pack.genericR0 ?? AVAudioPCMBuffer()
                    default: buffer = pack.genericR0 ?? AVAudioPCMBuffer()
                    }
                }
            } else {
                // Key Up
                switch keyCode {
                case 49: buffer = pack.releaseSpace ?? pack.releaseGeneric ?? pack.space ?? pack.genericR0 ?? AVAudioPCMBuffer()
                case 36: buffer = pack.releaseEnter ?? pack.releaseGeneric ?? pack.enter ?? pack.genericR0 ?? AVAudioPCMBuffer()
                case 51: buffer = pack.releaseBackspace ?? pack.releaseGeneric ?? pack.backspace ?? pack.genericR0 ?? AVAudioPCMBuffer()
                default: buffer = pack.releaseGeneric ?? pack.genericR0 ?? AVAudioPCMBuffer()
                }
            }
            
            // Empty buffer check
            guard buffer.frameLength > 0 else { return }
            
            let channel = self.channels[self.currentChannelIndex]
            self.currentChannelIndex = (self.currentChannelIndex + 1) % self.channelCount
            
            // Reverb / Pitch Effects
            DispatchQueue.main.async {
                self.updateReverbEffect()
                let wpm = self.calculateWPM()
                let isComboMode = wpm > 100
                
                channel.pitch.pitch = isComboMode ? 1.0 : (isDown ? 0.0 : -100.0)
                channel.mixer.volume = (isComboMode ? 1.2 : 1.0) * (isDown ? 1.0 : 0.6)
                
                // Spatial Pan
                if keyCode < 128 {
                    let pan = self.getPanForKey(keyCode)
                    channel.mixer.pan = Float(pan)
                }
            }
            
            channel.player.scheduleBuffer(buffer, at: nil, options: .interrupts)
            
            if !channel.player.isPlaying {
                channel.player.play()
            }
        }
    }
    
    private func updateReverbEffect() {
        let now = Date()
        recentKeyTimestamps.append(now)
        recentKeyTimestamps.removeAll { now.timeIntervalSince($0) > 2.0 }
        
        let wpm = calculateWPM()
        let isComboMode = wpm > 100
        
        let targetWetDryMix: Float = isComboMode ? Float(min((wpm - 100) * 0.8, 40.0)) : 0.0
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.allowsImplicitAnimation = true
            self.reverbNode.wetDryMix = targetWetDryMix
        }
    }
    
    private func calculateWPM() -> Double {
        guard recentKeyTimestamps.count >= 2 else { return 0 }
        let timeSpan = recentKeyTimestamps.last!.timeIntervalSince(recentKeyTimestamps.first!)
        if timeSpan == 0 { return 0 }
        
        let cpm = Double(recentKeyTimestamps.count) / (timeSpan / 60.0)
        return cpm / 5.0
    }
    
    private func getPanForKey(_ keyCode: Int64) -> Float {
        let leftKeys: Set<Int64> = [12, 13, 0, 1, 6, 7, 18, 19, 20, 21, 53, 48, 50, 56, 59]
        let rightKeys: Set<Int64> = [35, 33, 30, 31, 32, 34, 40, 38, 42, 43, 46, 45, 36, 51, 60]
        
        if leftKeys.contains(keyCode) { return -0.4 }
        if rightKeys.contains(keyCode) { return 0.4 }
        return 0.0
    }
    
    func start() {
        // Zaten init içinde başlıyor ama uyumluluk için
    }
    
    func playMouseSound(isLeft: Bool, isDown: Bool, location: CGPoint) {
        // Fare sesi istenirse ileride eklenebilir
    }
    
    func checkPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        self.hasPermission = AXIsProcessTrustedWithOptions(options)
    }
}
