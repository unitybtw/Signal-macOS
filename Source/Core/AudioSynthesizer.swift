import AVFoundation
import CoreAudio
import Combine

enum AudioTheme: CaseIterable {
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
        case .catMeow: return "Meow 🐱"
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
    @Published var currentTheme: AudioTheme = .mechanical
    @Published var isMuted: Bool = false
    @Published var isErrorSoundEnabled: Bool = true
    @Published var hasPermission: Bool = AXIsProcessTrusted()
    @Published var volume: Float = 0.5 {
        didSet {
            engine.mainMixerNode.outputVolume = volume
        }
    }
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let pitchEffect = AVAudioUnitTimePitch()

    // Synth Buffers
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
        
        // Periyodik izin kontrolü (Kullanıcı ayarlardan açarsa anında algılamak için)
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            let status = AXIsProcessTrusted()
            if status != self?.hasPermission {
                self?.hasPermission = status
                if status {
                    NotificationCenter.default.post(name: NSNotification.Name("RestartMonitor"), object: nil)
                }
            }
        }
        
        // --- Uygulama Açılış Sesi ---
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.playStartupSound()
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
        
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !playerNode.isPlaying { playerNode.play() }
    }
    
    private func setupEngine() {
        engine.attach(playerNode)
        engine.attach(pitchEffect)
        
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)
        
        if let fmt = format {
            engine.connect(playerNode, to: pitchEffect, format: fmt)
            engine.connect(pitchEffect, to: engine.mainMixerNode, format: fmt)
        }
        
        engine.mainMixerNode.outputVolume = volume
    }
    
    func start() {
        do {
            try engine.start()
            print("AudioEngine: Sentezleyici başlatıldı.")
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
    
    func playKeySound() {
        guard engine.isRunning && !isMuted else { return }
        
        let bufferToPlay: AVAudioPCMBuffer?
        switch currentTheme {
        case .mechanical: bufferToPlay = mechanicalBuffer
        case .mechanicalClicky: bufferToPlay = mechanicalClickyBuffer
        case .typewriter: bufferToPlay = typewriterBuffer
        case .scifi: bufferToPlay = scifiBuffer
        case .arcade: bufferToPlay = arcadeBuffer
        case .waterDrop: bufferToPlay = waterDropBuffer
        case .glockenspiel: bufferToPlay = glockenspielBuffer
        case .woodenBlock: bufferToPlay = woodenBlockBuffer
        case .vinylScratch: bufferToPlay = vinylScratchBuffer
        case .bubblePop: bufferToPlay = bubblePopBuffer
        case .percussiveDjembe: bufferToPlay = percussiveDjembeBuffer
        case .alienBlaster: bufferToPlay = alienBlasterBuffer
        case .percussive808: bufferToPlay = percussive808Buffer
        case .laserGun: bufferToPlay = laserGunBuffer
        case .catMeow: bufferToPlay = catMeowBuffer
        case .rainDrop: bufferToPlay = rainDropBuffer
        case .digitalBeep: bufferToPlay = digitalBeepBuffer
        case .retroPhone: bufferToPlay = retroPhoneBuffer
        case .heartBeat: bufferToPlay = heartBeatBuffer
        case .spaceSweep: bufferToPlay = spaceSweepBuffer
        case .cameraClick: bufferToPlay = cameraClickBuffer
        case .coinCollect: bufferToPlay = coinCollectBuffer
        case .thunderZap: bufferToPlay = thunderZapBuffer
        case .forestWind: bufferToPlay = forestWindBuffer
        case .deepThud: bufferToPlay = deepThudBuffer
        case .heavyMetal: bufferToPlay = heavyMetalBuffer
        case .neonBeep: bufferToPlay = neonBeepBuffer
        case .natureWood: bufferToPlay = natureWoodBuffer
        case .subBass: bufferToPlay = subBassBuffer
        case .airRush: bufferToPlay = airRushBuffer
        }
        
        guard let pcmBuffer = bufferToPlay else { return }
        
        pitchEffect.pitch = Float.random(in: -100...100)
        
        playerNode.scheduleBuffer(pcmBuffer, at: nil, options: .interrupts)
        
        if !playerNode.isPlaying {
            playerNode.play()
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
    
    enum SynthType { case mechanical, mechanicalClicky, typewriter, scifi, arcade, waterDrop, glockenspiel, woodenBlock, vinylScratch, bubblePop, percussiveDjembe, alienBlaster, percussive808, laserGun, catMeow, rainDrop, digitalBeep, retroPhone, heartBeat, spaceSweep, cameraClick, coinCollect, thunderZap, forestWind, deepThud, heavyMetal, neonBeep, natureWood, subBass, airRush }
    
    private func createClickBuffer(format: AVAudioFormat, type: SynthType) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double
        switch type {
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
