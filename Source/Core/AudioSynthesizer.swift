import AVFoundation
import CoreAudio
import Combine
import AppKit

enum AudioTheme: String, CaseIterable {
    case cherryMXBlue
    case cherryMXBrown
    case cherryMXRed
    case topre
    case holyPanda
    case gateronBlackInk
    case kailhBoxWhite
    case zealiosV2
    case alpacaLinear
    case novelKeysCream
    case bucklingSpring
    case mechanical
    case mechanicalClicky
    case typewriter
    case scifi
    case arcade
    case waterDrop
    case glockenspiel
    case woodenBlock
    case vinylScratch
    case bubblePop
    case percussiveDjembe
    case alienBlaster
    case percussive808
    case laserGun
    case catMeow
    case rainDrop
    case digitalBeep
    case retroPhone
    case heartBeat
    case spaceSweep
    case cameraClick
    case coinCollect
    case thunderZap
    case forestWind
    case deepThud
    case heavyMetal
    case neonBeep
    case natureWood
    case subBass
    case airRush
    
    var displayName: String {
        switch self {
        case .cherryMXBlue: return "Cherry Blue"
        case .cherryMXBrown: return "Cherry Brown"
        case .cherryMXRed: return "Cherry Red"
        case .topre: return "Topre"
        case .holyPanda: return "Holy Panda"
        case .gateronBlackInk: return "Black Ink"
        case .kailhBoxWhite: return "Box White"
        case .zealiosV2: return "Zealios V2"
        case .alpacaLinear: return "Alpaca"
        case .novelKeysCream: return "NK Cream"
        case .bucklingSpring: return "Model M"
        case .mechanical: return "Mech (Linear)"
        case .mechanicalClicky: return "Mech (Clicky)"
        case .typewriter: return "Typewriter"
        case .scifi: return "Sci-Fi"
        case .arcade: return "Arcade"
        case .waterDrop: return "Water"
        case .glockenspiel: return "Glock"
        case .woodenBlock: return "Wood"
        case .vinylScratch: return "Vinyl"
        case .bubblePop: return "Bubble"
        case .percussiveDjembe: return "Djembe"
        case .alienBlaster: return "Alien"
        case .percussive808: return "808"
        case .laserGun: return "Laser"
        case .catMeow: return "Meow"
        case .rainDrop: return "Rain"
        case .digitalBeep: return "Digital"
        case .retroPhone: return "Phone"
        case .heartBeat: return "Heart"
        case .spaceSweep: return "Space"
        case .cameraClick: return "Camera"
        case .coinCollect: return "Coin"
        case .thunderZap: return "Zap"
        case .forestWind: return "Wind"
        case .deepThud: return "Deep"
        case .heavyMetal: return "Metal"
        case .neonBeep: return "Neon"
        case .natureWood: return "Forest"
        case .subBass: return "Sub"
        case .airRush: return "Rush"
        }
    }
}

class AudioSynthesizer: ObservableObject {
    @Published var currentTheme: AudioTheme = AudioTheme(rawValue: UserDefaults.standard.string(forKey: "currentTheme") ?? "") ?? .mechanical {
        didSet { UserDefaults.standard.set(currentTheme.rawValue, forKey: "currentTheme") }
    }
    @Published var isMuted: Bool = UserDefaults.standard.object(forKey: "isMuted") as? Bool ?? false {
        didSet { UserDefaults.standard.set(isMuted, forKey: "isMuted") }
    }
    @Published var isSmartMuteEnabled: Bool = UserDefaults.standard.object(forKey: "isSmartMuteEnabled") as? Bool ?? false {
        didSet { UserDefaults.standard.set(isSmartMuteEnabled, forKey: "isSmartMuteEnabled") }
    }
    @Published var isSmartMutedActive: Bool = false
    @Published var isMouseSoundEnabled: Bool = UserDefaults.standard.object(forKey: "isMouseSoundEnabled") as? Bool ?? false {
        didSet { UserDefaults.standard.set(isMouseSoundEnabled, forKey: "isMouseSoundEnabled") }
    }
    @Published var isErrorSoundEnabled: Bool = UserDefaults.standard.object(forKey: "isErrorSoundEnabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(isErrorSoundEnabled, forKey: "isErrorSoundEnabled") }
    }
    @Published var isOrganicPitchEnabled: Bool = UserDefaults.standard.object(forKey: "isOrganicPitchEnabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(isOrganicPitchEnabled, forKey: "isOrganicPitchEnabled") }
    }
    @Published var hasPermission: Bool = AXIsProcessTrusted()
    @Published var volume: Float = UserDefaults.standard.object(forKey: "volume") as? Float ?? 0.5 {
        didSet {
            UserDefaults.standard.set(volume, forKey: "volume")
            engine.mainMixerNode.outputVolume = volume
        }
    }
    
    private let engine = AVAudioEngine()
    
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

    // Synth Buffers
    private var cherryMXBlueBuffer: AVAudioPCMBuffer?
    private var cherryMXBrownBuffer: AVAudioPCMBuffer?
    private var cherryMXRedBuffer: AVAudioPCMBuffer?
    private var topreBuffer: AVAudioPCMBuffer?
    private var holyPandaBuffer: AVAudioPCMBuffer?
    private var gateronBlackInkBuffer: AVAudioPCMBuffer?
    private var kailhBoxWhiteBuffer: AVAudioPCMBuffer?
    private var zealiosV2Buffer: AVAudioPCMBuffer?
    private var alpacaLinearBuffer: AVAudioPCMBuffer?
    private var novelKeysCreamBuffer: AVAudioPCMBuffer?
    private var bucklingSpringBuffer: AVAudioPCMBuffer?
    
    // Dedicated Modifiers
    private var mechanicalSpacebarBuffer: AVAudioPCMBuffer?
    private var mechanicalEnterBuffer: AVAudioPCMBuffer?
    private var mechanicalKeyUpBuffer: AVAudioPCMBuffer?
    
    private var mechanicalBuffer: AVAudioPCMBuffer?
    private var mechanicalClickyBuffer: AVAudioPCMBuffer?
    private var typewriterBuffer: AVAudioPCMBuffer?
    private var scifiBuffer: AVAudioPCMBuffer?
    private var arcadeBuffer: AVAudioPCMBuffer?
    private var waterDropBuffer: AVAudioPCMBuffer?
    private var glockenspielBuffer: AVAudioPCMBuffer?
    private var woodenBlockBuffer: AVAudioPCMBuffer?
    private var vinylScratchBuffer: AVAudioPCMBuffer?
    private var bubblePopBuffer: AVAudioPCMBuffer?
    private var percussiveDjembeBuffer: AVAudioPCMBuffer?
    private var alienBlasterBuffer: AVAudioPCMBuffer?
    private var percussive808Buffer: AVAudioPCMBuffer?
    private var laserGunBuffer: AVAudioPCMBuffer?
    private var catMeowBuffer: AVAudioPCMBuffer?
    private var rainDropBuffer: AVAudioPCMBuffer?
    private var digitalBeepBuffer: AVAudioPCMBuffer?
    private var retroPhoneBuffer: AVAudioPCMBuffer?
    private var heartBeatBuffer: AVAudioPCMBuffer?
    private var spaceSweepBuffer: AVAudioPCMBuffer?
    private var cameraClickBuffer: AVAudioPCMBuffer?
    private var coinCollectBuffer: AVAudioPCMBuffer?
    private var thunderZapBuffer: AVAudioPCMBuffer?
    private var forestWindBuffer: AVAudioPCMBuffer?
    private var deepThudBuffer: AVAudioPCMBuffer?
    private var heavyMetalBuffer: AVAudioPCMBuffer?
    private var neonBeepBuffer: AVAudioPCMBuffer?
    private var natureWoodBuffer: AVAudioPCMBuffer?
    private var subBassBuffer: AVAudioPCMBuffer?
    private var airRushBuffer: AVAudioPCMBuffer?
    
    init() {
        setupEngine()
        generateSynthBuffers()
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkPermission()
        }
        
        // --- Uygulama Açılış Sesi ---
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.playStartupSound()
        }
        
        // Ses aygıtı (kulaklık takma/çıkarma) değiştiğinde motoru otomatik yeniden başlat
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioConfigurationChange),
            name: .AVAudioEngineConfigurationChange,
            object: engine
        )
    }
    
    @objc private func handleAudioConfigurationChange(notification: Notification) {
        print("AudioEngine: Çıkış aygıtı değişti. Motor yeniden başlatılıyor...")
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                if !self.engine.isRunning {
                    try self.engine.start()
                    for channel in self.channels {
                        if !channel.player.isPlaying {
                            channel.player.play()
                        }
                    }
                    print("AudioEngine: Aygıt değişikliği sonrası başarıyla yeniden başlatıldı.")
                }
            } catch {
                print("AudioEngine Yeniden Başlatma Hatası: \(error.localizedDescription)")
            }
        }
    }
    
    func checkPermission() {
        let status = AXIsProcessTrusted()
        if status != self.hasPermission {
            self.hasPermission = status
            if status {
                NotificationCenter.default.post(name: NSNotification.Name("RestartMonitor"), object: nil)
            }
        }
    }
    
    private func playStartupSound() {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false) else { return }
        
        // 0.4 saniyelik bir siber-açılış bip sesi
        let duration: Double = 0.4
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate
            let env = Float(exp(-t * 20.0))
            // frekans yükselen bir (pew) sese doğru gitse havalı olur
            let freq = 440.0 + 800.0 * (t / duration)
            channelData[i] = Float(sin(2.0 * .pi * freq * t)) * env * 0.4
        }
        
        let channel = channels[0]
        channel.player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !channel.player.isPlaying { channel.player.play() }
    }
    
    private func setupEngine() {
        let monoFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)
        
        for _ in 0..<channelCount {
            let player = AVAudioPlayerNode()
            let pitch = AVAudioUnitTimePitch()
            let mixer = AVAudioMixerNode()
            
            engine.attach(player)
            engine.attach(pitch)
            engine.attach(mixer)
            
            if let mono = monoFormat {
                engine.connect(player, to: pitch, format: mono)
                engine.connect(pitch, to: mixer, format: mono)
                engine.connect(mixer, to: engine.mainMixerNode, format: nil)
            }
            
            channels.append(SynthChannel(player: player, pitch: pitch, mixer: mixer))
        }
        
        engine.mainMixerNode.outputVolume = volume
    }
    
    func start() {
        do {
            try engine.start()
            print("AudioEngine: Sentezleyici başlatıldı.")
            
            // PRE-WARM OPTIMIZATION:
            // Oynatıcıları motor başladıktan hemen sonra çalıştırıp "sürekli aktif" tutuyoruz.
            // Bu sayede tuşa basıldığında AVAudioPlayerNode uyanmak için zaman kaybetmez (Sıfır Gecikme).
            for channel in channels {
                if !channel.player.isPlaying {
                    channel.player.play()
                }
            }
        } catch {
            print("AudioEngine Hata: \(error.localizedDescription)")
        }
    }
    
    func setTheme(_ theme: AudioTheme) {
        currentTheme = theme
        // --- Tema Önizleme Sesi ---
        // Picker değiştiğinde kullanıcıya yeni sesin bir örneğini çal
        playKeySound()
    }
    
    func playMouseSound(isLeft: Bool, location: CGPoint) {
        guard engine.isRunning && !isMuted && isMouseSoundEnabled else { return }
        if isSmartMuteEnabled && isSmartMutedActive { return }
        
        let screenWidth = NSScreen.main?.frame.width ?? 1920.0
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            var bufferToPlay: AVAudioPCMBuffer?
            switch self.currentTheme {
            case .cherryMXBlue: bufferToPlay = self.cherryMXBlueBuffer
            case .cherryMXBrown: bufferToPlay = self.cherryMXBrownBuffer
            case .cherryMXRed: bufferToPlay = self.cherryMXRedBuffer
            case .topre: bufferToPlay = self.topreBuffer
            case .holyPanda: bufferToPlay = self.holyPandaBuffer
            case .gateronBlackInk: bufferToPlay = self.gateronBlackInkBuffer
            case .kailhBoxWhite: bufferToPlay = self.kailhBoxWhiteBuffer
            case .zealiosV2: bufferToPlay = self.zealiosV2Buffer
            case .alpacaLinear: bufferToPlay = self.alpacaLinearBuffer
            case .novelKeysCream: bufferToPlay = self.novelKeysCreamBuffer
            case .bucklingSpring: bufferToPlay = self.bucklingSpringBuffer
            case .mechanical: bufferToPlay = self.mechanicalBuffer
            case .mechanicalClicky: bufferToPlay = self.mechanicalClickyBuffer
            case .typewriter: bufferToPlay = self.typewriterBuffer
            case .scifi: bufferToPlay = self.scifiBuffer
            case .arcade: bufferToPlay = self.arcadeBuffer
            case .waterDrop: bufferToPlay = self.waterDropBuffer
            case .glockenspiel: bufferToPlay = self.glockenspielBuffer
            case .woodenBlock: bufferToPlay = self.woodenBlockBuffer
            case .vinylScratch: bufferToPlay = self.vinylScratchBuffer
            case .bubblePop: bufferToPlay = self.bubblePopBuffer
            case .percussiveDjembe: bufferToPlay = self.percussiveDjembeBuffer
            case .alienBlaster: bufferToPlay = self.alienBlasterBuffer
            case .percussive808: bufferToPlay = self.percussive808Buffer
            case .laserGun: bufferToPlay = self.laserGunBuffer
            case .catMeow: bufferToPlay = self.catMeowBuffer
            case .rainDrop: bufferToPlay = self.rainDropBuffer
            case .digitalBeep: bufferToPlay = self.digitalBeepBuffer
            case .retroPhone: bufferToPlay = self.retroPhoneBuffer
            case .heartBeat: bufferToPlay = self.heartBeatBuffer
            case .spaceSweep: bufferToPlay = self.spaceSweepBuffer
            case .cameraClick: bufferToPlay = self.cameraClickBuffer
            case .coinCollect: bufferToPlay = self.coinCollectBuffer
            case .thunderZap: bufferToPlay = self.thunderZapBuffer
            case .forestWind: bufferToPlay = self.forestWindBuffer
            case .deepThud: bufferToPlay = self.deepThudBuffer
            case .heavyMetal: bufferToPlay = self.heavyMetalBuffer
            case .neonBeep: bufferToPlay = self.neonBeepBuffer
            case .natureWood: bufferToPlay = self.natureWoodBuffer
            case .subBass: bufferToPlay = self.subBassBuffer
            case .airRush: bufferToPlay = self.airRushBuffer
            }
            
            guard let pcmBuffer = bufferToPlay else { return }
            
            let channel = self.channels[self.currentChannelIndex]
            self.currentChannelIndex = (self.currentChannelIndex + 1) % self.channelCount
            
            var pan: Float = 0.0
            let normalizedX = Float(location.x / screenWidth)
            pan = (normalizedX * 2.0 - 1.0) * 0.6
            
            channel.pitch.pitch = isLeft ? 1200 : 900
            channel.mixer.pan = pan
            channel.player.volume = 0.4
            
            channel.player.scheduleBuffer(pcmBuffer, at: nil, options: .interrupts)
            if !channel.player.isPlaying {
                channel.player.play()
            }
        }
    }
    
    func playKeySound(keyCode: Int64 = 0, isDown: Bool = true) {
        guard engine.isRunning && !isMuted else { return }
        if isSmartMuteEnabled && isSmartMutedActive { return }
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            var bufferToPlay: AVAudioPCMBuffer?
            switch self.currentTheme {
            case .cherryMXBlue: bufferToPlay = self.cherryMXBlueBuffer
            case .cherryMXBrown: bufferToPlay = self.cherryMXBrownBuffer
            case .cherryMXRed: bufferToPlay = self.cherryMXRedBuffer
            case .topre: bufferToPlay = self.topreBuffer
            case .holyPanda: bufferToPlay = self.holyPandaBuffer
            case .gateronBlackInk: bufferToPlay = self.gateronBlackInkBuffer
            case .kailhBoxWhite: bufferToPlay = self.kailhBoxWhiteBuffer
            case .zealiosV2: bufferToPlay = self.zealiosV2Buffer
            case .alpacaLinear: bufferToPlay = self.alpacaLinearBuffer
            case .novelKeysCream: bufferToPlay = self.novelKeysCreamBuffer
            case .bucklingSpring: bufferToPlay = self.bucklingSpringBuffer
            case .mechanical: bufferToPlay = self.mechanicalBuffer
            case .mechanicalClicky: bufferToPlay = self.mechanicalClickyBuffer
            case .typewriter: bufferToPlay = self.typewriterBuffer
            case .scifi: bufferToPlay = self.scifiBuffer
            case .arcade: bufferToPlay = self.arcadeBuffer
            case .waterDrop: bufferToPlay = self.waterDropBuffer
            case .glockenspiel: bufferToPlay = self.glockenspielBuffer
            case .woodenBlock: bufferToPlay = self.woodenBlockBuffer
            case .vinylScratch: bufferToPlay = self.vinylScratchBuffer
            case .bubblePop: bufferToPlay = self.bubblePopBuffer
            case .percussiveDjembe: bufferToPlay = self.percussiveDjembeBuffer
            case .alienBlaster: bufferToPlay = self.alienBlasterBuffer
            case .percussive808: bufferToPlay = self.percussive808Buffer
            case .laserGun: bufferToPlay = self.laserGunBuffer
            case .catMeow: bufferToPlay = self.catMeowBuffer
            case .rainDrop: bufferToPlay = self.rainDropBuffer
            case .digitalBeep: bufferToPlay = self.digitalBeepBuffer
            case .retroPhone: bufferToPlay = self.retroPhoneBuffer
            case .heartBeat: bufferToPlay = self.heartBeatBuffer
            case .spaceSweep: bufferToPlay = self.spaceSweepBuffer
            case .cameraClick: bufferToPlay = self.cameraClickBuffer
            case .coinCollect: bufferToPlay = self.coinCollectBuffer
            case .thunderZap: bufferToPlay = self.thunderZapBuffer
            case .forestWind: bufferToPlay = self.forestWindBuffer
            case .deepThud: bufferToPlay = self.deepThudBuffer
            case .heavyMetal: bufferToPlay = self.heavyMetalBuffer
            case .neonBeep: bufferToPlay = self.neonBeepBuffer
            case .natureWood: bufferToPlay = self.natureWoodBuffer
            case .subBass: bufferToPlay = self.subBassBuffer
            case .airRush: bufferToPlay = self.airRushBuffer
            }
            
            guard let pcmBuffer = bufferToPlay else { return }
            
            var basePitch: Float = 0
            var volumeModifier: Float = 1.0
            
            switch keyCode {
            case 49: // Space
                if self.currentTheme == .mechanical || self.currentTheme == .cherryMXRed || self.currentTheme == .cherryMXBrown || self.currentTheme == .topre || self.currentTheme == .holyPanda {
                    bufferToPlay = self.mechanicalSpacebarBuffer
                }
                basePitch = -150
                volumeModifier = 1.3
            case 36: // Return
                if self.currentTheme == .mechanical || self.currentTheme == .cherryMXRed || self.currentTheme == .cherryMXBrown || self.currentTheme == .topre || self.currentTheme == .holyPanda {
                    bufferToPlay = self.mechanicalEnterBuffer
                }
                basePitch = -100
                volumeModifier = 1.2
            case 51: // Backspace
                basePitch = 150
                volumeModifier = 0.9
            case 48: // Tab
                basePitch = 200
            case 53: // Esc
                basePitch = -400
            default:
                break
            }
            
            let finalBuffer = bufferToPlay ?? pcmBuffer
            
            if !isDown {
                if self.currentTheme == .mechanical || self.currentTheme == .cherryMXRed || self.currentTheme == .cherryMXBrown || self.currentTheme == .topre || self.currentTheme == .holyPanda || self.currentTheme == .cherryMXBlue {
                    bufferToPlay = self.mechanicalKeyUpBuffer
                } else {
                    basePitch += 600
                }
                volumeModifier *= 0.3
            }
            
            if isDown {
                let now = Date()
                self.recentKeyTimestamps.append(now)
                self.recentKeyTimestamps.removeAll { now.timeIntervalSince($0) > 2.0 }
                
                let wpmApprox = Double(self.recentKeyTimestamps.count) * 30.0 / 5.0
                let momentum = min(wpmApprox / 120.0, 1.0)
                
                volumeModifier *= Float(1.0 + (momentum * 0.2))
                basePitch += Float(momentum * 150.0)
            }
            
            let leftKeys: Set<Int64> = [50, 10, 0, 6, 12, 1, 13, 2, 14, 7, 3, 15, 8, 53, 48]
            let rightKeys: Set<Int64> = [32, 34, 38, 40, 37, 41, 39, 42, 36, 51, 35, 31, 46, 45, 43, 44, 47]
            
            var panValue: Float = 0.0
            if leftKeys.contains(keyCode) {
                panValue = -0.5
            } else if rightKeys.contains(keyCode) {
                panValue = 0.5
            } else if keyCode == 49 {
                panValue = 0.0
            } else {
                panValue = Float.random(in: -0.15...0.15)
            }
            
            let channel = self.channels[self.currentChannelIndex]
            self.currentChannelIndex = (self.currentChannelIndex + 1) % self.channelCount
            
            if self.isOrganicPitchEnabled {
                channel.pitch.pitch = basePitch + Float.random(in: -80...80)
            } else {
                channel.pitch.pitch = basePitch
            }
            
            channel.mixer.pan = panValue
            channel.player.volume = volumeModifier
            
            channel.player.scheduleBuffer(bufferToPlay ?? finalBuffer, at: nil, options: .interrupts)
            
            if !channel.player.isPlaying {
                channel.player.play()
            }
        }
    }
    
    func playErrorSound() {
        guard !isMuted && isErrorSoundEnabled else { return }
        // macOS Varsayılan Hata Sesi (System Alert Sound)
        // 0x07 (decimal 7) genellikle sistem bip sesidir, ancak kCFSoundID_UserPreferredAlert daha iyidir.
        AudioServicesPlaySystemSound(kSystemSoundID_UserPreferredAlert)
    }
    
    private func generateSynthBuffers() {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false) else { return }
        
        self.cherryMXBlueBuffer = createClickBuffer(format: format, type: .cherryMXBlue)
        self.cherryMXBrownBuffer = createClickBuffer(format: format, type: .cherryMXBrown)
        self.cherryMXRedBuffer = createClickBuffer(format: format, type: .cherryMXRed)
        self.topreBuffer = createClickBuffer(format: format, type: .topre)
        self.holyPandaBuffer = createClickBuffer(format: format, type: .holyPanda)
        self.gateronBlackInkBuffer = createClickBuffer(format: format, type: .gateronBlackInk)
        self.kailhBoxWhiteBuffer = createClickBuffer(format: format, type: .kailhBoxWhite)
        self.zealiosV2Buffer = createClickBuffer(format: format, type: .zealiosV2)
        self.alpacaLinearBuffer = createClickBuffer(format: format, type: .alpacaLinear)
        self.novelKeysCreamBuffer = createClickBuffer(format: format, type: .novelKeysCream)
        self.bucklingSpringBuffer = createClickBuffer(format: format, type: .bucklingSpring)
        
        self.mechanicalSpacebarBuffer = createClickBuffer(format: format, type: .mechanicalSpacebar)
        self.mechanicalEnterBuffer = createClickBuffer(format: format, type: .mechanicalEnter)
        self.mechanicalKeyUpBuffer = createClickBuffer(format: format, type: .mechanicalKeyUp)
        
        self.mechanicalBuffer = loadAudioFile(name: "mechanical", format: format) ?? createClickBuffer(format: format, type: .mechanical)
        self.mechanicalClickyBuffer = createClickBuffer(format: format, type: .mechanicalClicky)
        self.typewriterBuffer = loadAudioFile(name: "typewriter", format: format) ?? createClickBuffer(format: format, type: .typewriter)
        self.scifiBuffer = createClickBuffer(format: format, type: .scifi)
        self.arcadeBuffer = createClickBuffer(format: format, type: .arcade)
        self.waterDropBuffer = createClickBuffer(format: format, type: .waterDrop)
        self.glockenspielBuffer = createClickBuffer(format: format, type: .glockenspiel)
        self.woodenBlockBuffer = createClickBuffer(format: format, type: .woodenBlock)
        self.vinylScratchBuffer = createClickBuffer(format: format, type: .vinylScratch)
        self.bubblePopBuffer = createClickBuffer(format: format, type: .bubblePop)
        self.percussiveDjembeBuffer = createClickBuffer(format: format, type: .percussiveDjembe)
        self.alienBlasterBuffer = createClickBuffer(format: format, type: .alienBlaster)
        self.percussive808Buffer = createClickBuffer(format: format, type: .percussive808)
        self.laserGunBuffer = createClickBuffer(format: format, type: .laserGun)
        self.catMeowBuffer = createClickBuffer(format: format, type: .catMeow)
        self.rainDropBuffer = createClickBuffer(format: format, type: .rainDrop)
        self.digitalBeepBuffer = createClickBuffer(format: format, type: .digitalBeep)
        self.retroPhoneBuffer = createClickBuffer(format: format, type: .retroPhone)
        self.heartBeatBuffer = createClickBuffer(format: format, type: .heartBeat)
        self.spaceSweepBuffer = createClickBuffer(format: format, type: .spaceSweep)
        self.cameraClickBuffer = createClickBuffer(format: format, type: .cameraClick)
        self.coinCollectBuffer = createClickBuffer(format: format, type: .coinCollect)
        self.thunderZapBuffer = createClickBuffer(format: format, type: .thunderZap)
        self.forestWindBuffer = createClickBuffer(format: format, type: .forestWind)
        self.deepThudBuffer = createClickBuffer(format: format, type: .deepThud)
        self.heavyMetalBuffer = createClickBuffer(format: format, type: .heavyMetal)
        self.neonBeepBuffer = createClickBuffer(format: format, type: .neonBeep)
        self.natureWoodBuffer = createClickBuffer(format: format, type: .natureWood)
        self.subBassBuffer = createClickBuffer(format: format, type: .subBass)
        self.airRushBuffer = createClickBuffer(format: format, type: .airRush)
    }
    
    private func loadAudioFile(name: String, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds"),
              let file = try? AVAudioFile(forReading: url) else {
            return nil
        }
        
        let frameCount = AVAudioFrameCount(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        do {
            try file.read(into: buffer)
            return buffer
        } catch {
            return nil
        }
    }
    
    enum SynthType { case cherryMXBlue, cherryMXBrown, cherryMXRed, topre, holyPanda, gateronBlackInk, kailhBoxWhite, zealiosV2, alpacaLinear, novelKeysCream, bucklingSpring, mechanicalSpacebar, mechanicalEnter, mechanicalKeyUp, mechanical, mechanicalClicky, typewriter, scifi, arcade, waterDrop, glockenspiel, woodenBlock, vinylScratch, bubblePop, percussiveDjembe, alienBlaster, percussive808, laserGun, catMeow, rainDrop, digitalBeep, retroPhone, heartBeat, spaceSweep, cameraClick, coinCollect, thunderZap, forestWind, deepThud, heavyMetal, neonBeep, natureWood, subBass, airRush }
    
    private func createClickBuffer(format: AVAudioFormat, type: SynthType) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double
        switch type {
        case .cherryMXBlue: duration = 0.05
        case .cherryMXBrown: duration = 0.05
        case .cherryMXRed: duration = 0.04
        case .topre: duration = 0.06
        case .holyPanda: duration = 0.05
        case .gateronBlackInk: duration = 0.05
        case .kailhBoxWhite: duration = 0.04
        case .zealiosV2: duration = 0.05
        case .alpacaLinear: duration = 0.04
        case .novelKeysCream: duration = 0.05
        case .bucklingSpring: duration = 0.12
        case .mechanicalSpacebar: duration = 0.1
        case .mechanicalEnter: duration = 0.08
        case .mechanicalKeyUp: duration = 0.03
        case .mechanical: duration = 0.04
        case .mechanicalClicky: duration = 0.04
        case .typewriter: duration = 0.08
        case .scifi:      duration = 0.06
        case .arcade:     duration = 0.08
        case .waterDrop:  duration = 0.06
        case .glockenspiel: duration = 0.12
        case .woodenBlock: duration = 0.05
        case .vinylScratch: duration = 0.08
        case .bubblePop: duration = 0.05
        case .percussiveDjembe: duration = 0.08
        case .alienBlaster: duration = 0.10
        case .percussive808: duration = 0.20
        case .laserGun: duration = 0.15
        case .catMeow: duration = 0.25
        case .rainDrop: duration = 0.05
        case .digitalBeep: duration = 0.04
        case .retroPhone: duration = 0.12
        case .heartBeat: duration = 0.20
        case .spaceSweep: duration = 0.30
        case .cameraClick: duration = 0.04
        case .coinCollect: duration = 0.15
        case .thunderZap: duration = 0.08
        case .forestWind: duration = 0.20
        case .deepThud: duration = 0.12
        case .heavyMetal: duration = 0.15
        case .neonBeep: duration = 0.04
        case .natureWood: duration = 0.10
        case .subBass: duration = 0.25
        case .airRush: duration = 0.08
        }
        
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample: Float = 0.0
            
            switch type {
            case .cherryMXBlue:
                let attackEnv = Float(exp(-t * 2000.0))
                let bodyEnv = Float(exp(-t * 150.0))
                let noise = Float.random(in: -1.0...1.0)
                let click = (Float(sin(2.0 * .pi * 4500.0 * t)) * 0.6 + noise * 0.4) * attackEnv
                let body = Float(sin(2.0 * .pi * 300.0 * t)) * bodyEnv
                sample = (click * 1.5 + body * 0.5) * 1.3
            case .cherryMXBrown:
                let attackEnv = Float(exp(-t * 600.0))
                let bodyEnv = Float(exp(-t * 200.0))
                let noise = Float.random(in: -1.0...1.0)
                let bump = (Float(sin(2.0 * .pi * 800.0 * t)) * 0.5 + noise * 0.2) * attackEnv
                let body = Float(sin(2.0 * .pi * 220.0 * t)) * bodyEnv
                sample = (bump * 1.0 + body * 0.8) * 1.4
            case .cherryMXRed:
                let attackEnv = Float(exp(-t * 400.0))
                let bodyEnv = Float(exp(-t * 120.0))
                let noise = Float.random(in: -1.0...1.0)
                let linearHit = noise * attackEnv * 0.3
                let body = Float(sin(2.0 * .pi * 180.0 * t)) * bodyEnv
                sample = (linearHit + body * 0.9) * 1.2
            case .topre:
                let attackEnv = Float(exp(-t * 800.0))
                let bodyEnv = Float(exp(-t * 100.0))
                let thock = Float(sin(2.0 * .pi * 150.0 * t)) * bodyEnv
                let domeCollapse = Float(sin(2.0 * .pi * 400.0 * t)) * attackEnv
                sample = (thock * 1.0 + domeCollapse * 0.4) * 1.5
            case .holyPanda:
                let attackEnv = Float(exp(-t * 1000.0))
                let bodyEnv = Float(exp(-t * 180.0))
                let noise = Float.random(in: -1.0...1.0)
                let tactileBump = (Float(sin(2.0 * .pi * 1200.0 * t)) * 0.4 + noise * 0.2) * attackEnv
                let thock = Float(sin(2.0 * .pi * 200.0 * t)) * bodyEnv
                sample = (tactileBump * 0.8 + thock * 1.2) * 1.4
            case .gateronBlackInk:
                let attackEnv = Float(exp(-t * 300.0))
                let bodyEnv = Float(exp(-t * 90.0))
                let noise = Float.random(in: -1.0...1.0)
                let thock = Float(sin(2.0 * .pi * 140.0 * t)) * bodyEnv
                let clack = noise * attackEnv * 0.15
                sample = (thock * 1.4 + clack) * 1.3
            case .kailhBoxWhite:
                let attackEnv = Float(exp(-t * 3500.0))
                let bodyEnv = Float(exp(-t * 200.0))
                let noise = Float.random(in: -1.0...1.0)
                let sharpClick = (Float(sin(2.0 * .pi * 6000.0 * t)) * 0.7 + noise * 0.3) * attackEnv
                let body = Float(sin(2.0 * .pi * 400.0 * t)) * bodyEnv
                sample = (sharpClick * 1.8 + body * 0.6) * 1.2
            case .zealiosV2:
                let attackEnv = Float(exp(-t * 800.0))
                let bodyEnv = Float(exp(-t * 150.0))
                let noise = Float.random(in: -1.0...1.0)
                let crispBump = (Float(sin(2.0 * .pi * 1000.0 * t)) * 0.5 + noise * 0.2) * attackEnv
                let body = Float(sin(2.0 * .pi * 200.0 * t)) * bodyEnv
                sample = (crispBump * 1.2 + body * 1.0) * 1.3
            case .alpacaLinear:
                let attackEnv = Float(exp(-t * 500.0))
                let bodyEnv = Float(exp(-t * 120.0))
                let noise = Float.random(in: -1.0...1.0)
                let clack = (Float(sin(2.0 * .pi * 350.0 * t)) * 0.5 + noise * 0.2) * attackEnv
                let body = Float(sin(2.0 * .pi * 180.0 * t)) * bodyEnv
                sample = (clack * 1.0 + body * 0.8) * 1.2
            case .novelKeysCream:
                let attackEnv = Float(exp(-t * 400.0))
                let bodyEnv = Float(exp(-t * 100.0))
                let noise = Float.random(in: -1.0...1.0)
                let creamClack = (Float(sin(2.0 * .pi * 450.0 * t)) * 0.4 + noise * 0.2) * attackEnv
                let deepBody = Float(sin(2.0 * .pi * 160.0 * t)) * bodyEnv
                sample = (creamClack * 0.9 + deepBody * 1.1) * 1.3
            case .bucklingSpring:
                let attackEnv = Float(exp(-t * 2000.0))
                let springEnv = Float(exp(-t * 40.0))
                let bodyEnv = Float(exp(-t * 100.0))
                let noise = Float.random(in: -1.0...1.0)
                let metallicClick = (Float(sin(2.0 * .pi * 3000.0 * t)) * 0.6 + noise * 0.4) * attackEnv
                let springRing = Float(sin(2.0 * .pi * 800.0 * t) + sin(2.0 * .pi * 820.0 * t)) * springEnv * 0.3
                let body = Float(sin(2.0 * .pi * 200.0 * t)) * bodyEnv
                sample = (metallicClick * 1.5 + springRing + body * 0.8) * 1.2
            case .mechanicalSpacebar:
                let attackEnv = Float(exp(-t * 300.0))
                let bodyEnv = Float(exp(-t * 50.0))
                let noise = Float.random(in: -1.0...1.0)
                let thock = Float(sin(2.0 * .pi * 90.0 * t)) * bodyEnv
                let clack = (Float(sin(2.0 * .pi * 600.0 * t)) * 0.5 + noise * 0.3) * attackEnv
                sample = (thock * 1.5 + clack * 0.8) * 1.5
            case .mechanicalEnter:
                let attackEnv = Float(exp(-t * 400.0))
                let bodyEnv = Float(exp(-t * 80.0))
                let noise = Float.random(in: -1.0...1.0)
                let thock = Float(sin(2.0 * .pi * 120.0 * t)) * bodyEnv
                let clack = (Float(sin(2.0 * .pi * 800.0 * t)) * 0.5 + noise * 0.4) * attackEnv
                let metallicRing = Float(sin(2.0 * .pi * 2200.0 * t)) * Float(exp(-t * 40.0)) * 0.1
                sample = (thock * 1.2 + clack * 1.0 + metallicRing) * 1.4
            case .mechanicalKeyUp:
                let env = Float(exp(-t * 300.0))
                let noise = Float.random(in: -1.0...1.0) * 0.2
                let clack = Float(sin(2.0 * .pi * 1800.0 * t)) * env
                let spring = Float(sin(2.0 * .pi * 3000.0 * t)) * Float(exp(-t * 100.0)) * 0.1
                sample = (clack + noise + spring) * 0.5
            case .mechanical:
                // Sentetik geri dönüş thock
                let noise = Float.random(in: -1.0...1.0)
                let attackEnv = Float(exp(-t * 800.0))
                let bodyEnv = Float(exp(-t * 150.0))
                let freq1 = sin(2.0 * .pi * 120.0 * t)
                let freq2 = sin(2.0 * .pi * 250.0 * t)
                let freq3 = sin(2.0 * .pi * 3000.0 * t)
                let clickPart = (Float(freq3) * 0.2 + noise * 0.4) * attackEnv
                let thockPart = (Float(freq1) * 0.6 + Float(freq2) * 0.3 + noise * 0.1) * bodyEnv
                sample = (clickPart + thockPart) * 1.5
                
            case .mechanicalClicky:
                // Tiz ve keskin ses
                let noise = Float.random(in: -1.0...1.0)
                let attackEnv = Float(exp(-t * 1200.0))
                let freq = sin(2.0 * .pi * 3200.0 * t)
                sample = (Float(freq) * 0.7 + noise * 0.3) * attackEnv * 1.4
                
            case .typewriter:
                // Sentetik daktilo
                let noise = Float.random(in: -1.0...1.0)
                let impactEnv = Float(exp(-t * 600.0))
                let ringEnv = Float(exp(-t * 50.0))
                let ring1 = sin(2.0 * .pi * 1200.0 * t)
                let ring2 = sin(2.0 * .pi * 2400.0 * t)
                let ring3 = sin(2.0 * .pi * 3600.0 * t)
                let impact = noise * impactEnv
                let metallicRing = (Float(ring1) * 0.4 + Float(ring2) * 0.3 + Float(ring3) * 0.3) * ringEnv
                sample = (impact * 0.6 + metallicRing * 0.4) * 1.8
                
            case .scifi:
                // Lazer
                let env = Float(exp(-t * 80.0))
                let currentFreq = 500.0 + 2500.0 * exp(-t * 300.0)
                var osc = sin(2.0 * .pi * currentFreq * t)
                osc = osc > 0 ? 0.7 : -0.7
                let noise = Float.random(in: -1.0...1.0) * 0.1
                sample = (Float(osc) + noise) * env * 1.2
                
            case .arcade:
                // Bip bop 8-bit
                let env = Float(exp(-t * 40.0))
                let currentFreq = t < 0.02 ? 400.0 : 800.0
                var osc = sin(2.0 * .pi * currentFreq * t)
                osc = osc > 0 ? 0.8 : -0.8 // Square wave
                sample = Float(osc) * env * 0.5
                
            case .waterDrop:
                let env = Float(exp(-t * 60.0))
                let currentFreq = 300.0 + 800.0 * (t / duration)
                let osc = sin(2.0 * .pi * currentFreq * t)
                sample = Float(osc) * env * 1.5
                
            case .glockenspiel:
                let noise = Float.random(in: -1.0...1.0)
                let impactEnv = Float(exp(-t * 200.0))
                let ringEnv = Float(exp(-t * 10.0))
                let freq = sin(2.0 * .pi * 4200.0 * t)
                let freq2 = sin(2.0 * .pi * 6500.0 * t)
                let impact = noise * impactEnv
                let ring = (Float(freq) * 0.7 + Float(freq2) * 0.3) * ringEnv
                sample = (impact * 0.2 + ring * 0.8) * 1.2
                
            case .woodenBlock:
                let noise = Float.random(in: -1.0...1.0)
                let attackEnv = Float(exp(-t * 900.0))
                let bodyEnv = Float(exp(-t * 200.0))
                let freq = sin(2.0 * .pi * 800.0 * t)
                let thock = Float(freq) * bodyEnv
                let snap = noise * attackEnv
                sample = (thock * 0.8 + snap * 0.2) * 1.5
                
            case .vinylScratch:
                let noise = Float.random(in: -1.0...1.0)
                let env = Float(exp(-t * 50.0))
                let currentFreq = 2000.0 - (1800.0 * t / duration)
                let osc = sin(2.0 * .pi * currentFreq * t)
                let distorted = osc > 0 ? 0.9 : -0.9
                sample = (Float(distorted) * 0.5 + noise * 0.5) * env * 0.8
                
            case .bubblePop:
                let env = Float(exp(-t * 80.0))
                let currentFreq = 600.0 + 1200.0 * (t / duration)
                let osc = sin(2.0 * .pi * currentFreq * t)
                sample = Float(osc) * env * 1.6
                
            case .percussiveDjembe:
                let noise = Float.random(in: -1.0...1.0)
                let env = Float(exp(-t * 200.0))
                let freq = sin(2.0 * .pi * 180.0 * t) // bas ağırlıklı
                let freq2 = sin(2.0 * .pi * 300.0 * t) // düşük tiz
                let thump = (Float(freq) * 0.7 + Float(freq2) * 0.3) * env
                let snap = noise * Float(exp(-t * 600.0))
                sample = (thump * 0.9 + snap * 0.1) * 2.0
                
            case .alienBlaster:
                let noise = Float.random(in: -1.0...1.0)
                let env = Float(exp(-t * 40.0))
                let currentFreq = 3000.0 * exp(-t * 500.0) // çok hızlı çakılan lazer
                var osc = sin(2.0 * .pi * currentFreq * t)
                osc = osc > 0 ? 1.0 : -1.0 // sert distorsiyon
                sample = (Float(osc) * 0.6 + noise * 0.4) * env * 1.5
                
            case .percussive808:
                // Derin bir bas vuruşu (Sub-bass)
                let env = Float(exp(-t * 12.0))
                let freq = 60.0 * exp(-t * 5.0) // Frekans yavaşça düşer (Pitch drop)
                let osc = sin(2.0 * .pi * Double(freq) * t)
                sample = Float(osc) * env * 2.0
                
            case .laserGun:
                // Retro bilim kurgu silahı
                let env = Float(exp(-t * 15.0))
                let freq = 2000.0 - (1800.0 * (t / duration))
                let osc = sin(2.0 * .pi * freq * t)
                sample = Float(osc) * env * 1.5
                
            case .catMeow:
                // Kedicik (Matematiksel kedi sesi denemesi)
                let env = Float(sin(.pi * (t / duration))) // yükselip alçalan zarf
                let baseFreq = 400.0 + 200.0 * sin(2.0 * .pi * 5.0 * t) // vibrato
                let osc = sin(2.0 * .pi * baseFreq * t)
                sample = Float(osc) * env * 0.8
                
            case .rainDrop:
                let noise = Float.random(in: -1.0...1.0)
                let env = Float(exp(-t * 120.0))
                sample = noise * env * 1.5
                
            case .digitalBeep:
                let env = Float(exp(-t * 200.0))
                let osc = sin(2.0 * .pi * 2800.0 * t)
                sample = Float(osc > 0 ? 0.3 : -0.3) * env
                
            case .retroPhone:
                let env = Float(exp(-t * 15.0))
                let f1 = sin(2.0 * .pi * 350.0 * t)
                let f2 = sin(2.0 * .pi * 440.0 * t)
                sample = (Float(f1) + Float(f2)) * env * 1.2
                
            case .heartBeat:
                let env = Float(exp(-t * 8.0))
                let body = sin(2.0 * .pi * 60.0 * t)
                sample = Float(body) * env * 2.0
                
            case .spaceSweep:
                let env = Float(exp(-t * 3.0))
                let sweepFreq = 800.0 * exp(-t * 4.0)
                let osc = sin(2.0 * .pi * sweepFreq * t)
                sample = Float(osc) * env * 1.5
                
            case .cameraClick:
                let noise = Float.random(in: -1.0...1.0)
                let env = Float(exp(-t * 600.0))
                sample = noise * env * 2.0
                
            case .coinCollect:
                let env = Float(exp(-t * 15.0))
                let freq = 1200.0 + (t < 0.05 ? 0.0 : 400.0)
                let osc = sin(2.0 * .pi * freq * t)
                sample = Float(osc) * env * 0.8
                
            case .thunderZap:
                let noise = Float.random(in: -1.0...1.0)
                let env = Float(exp(-t * 60.0))
                let osc = sin(2.0 * .pi * 80.0 * t) // bas distorsiyonu
                sample = (Float(osc) * 0.5 + noise * 0.5) * env * 2.0
                
            case .forestWind:
                let noise = Float.random(in: -1.0...1.0)
                let env = Float(sin(.pi * (t / duration)))
                let freq = 200.0 + 100.0 * sin(2.0 * .pi * 2.0 * t)
                let osc = sin(2.0 * .pi * freq * t)
                sample = (Float(osc) * 0.3 + noise * 0.7) * env * 1.0
                
            case .deepThud:
                let env = Float(exp(-t * 10.0))
                let body = sin(2.0 * .pi * 45.0 * t)
                sample = Float(body) * env * 2.5
                
            case .heavyMetal:
                let noise = Float.random(in: -1.0...1.0)
                let env = Float(exp(-t * 25.0))
                let body = sin(2.0 * .pi * 200.0 * t)
                sample = (Float(body) * 0.4 + noise * 0.6) * env * 1.8
                
            case .neonBeep:
                let env = Float(exp(-t * 150.0))
                let f1 = sin(2.0 * .pi * 3200.0 * t)
                sample = Float(f1) * env * 0.6
                
            case .natureWood:
                let noise = Float.random(in: -1.0...1.0) * 0.2
                let env = Float(exp(-t * 100.0))
                let body = sin(2.0 * .pi * 350.0 * t)
                sample = (Float(body) + noise) * env * 1.4
                
            case .subBass:
                let env = Float(exp(-t * 6.0))
                let low = sin(2.0 * .pi * 35.0 * t)
                sample = Float(low) * env * 2.2
                
            case .airRush:
                let noise = Float.random(in: -1.0...1.0)
                let env = Float(exp(-t * 40.0))
                sample = noise * env * 0.9
            }
            
            // Satürasyon
            if sample > 1.0 { sample = 1.0 }
            if sample < -1.0 { sample = -1.0 }
            
            channelData[i] = sample
        }
        
        return buffer
    }
}
