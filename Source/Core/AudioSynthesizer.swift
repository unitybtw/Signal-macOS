import AVFoundation
import CoreAudio
import Combine

enum AudioTheme {
    case mechanical
    case mechanicalClicky
    case typewriter
    case scifi
    case arcade
    case waterDrop
}

class AudioSynthesizer: ObservableObject {
    @Published var currentTheme: AudioTheme = .mechanical
    @Published var isMuted: Bool = false
    @Published var volume: Float = 0.5 {
        didSet {
            engine.mainMixerNode.outputVolume = volume
        }
    }
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    // Pitch shift for slight randomization
    private let pitchEffect = AVAudioUnitTimePitch()

    // 6 farklı synth buffer
    private var mechanicalBuffer: AVAudioPCMBuffer?
    private var mechanicalClickyBuffer: AVAudioPCMBuffer?
    private var typewriterBuffer: AVAudioPCMBuffer?
    private var scifiBuffer: AVAudioPCMBuffer?
    private var arcadeBuffer: AVAudioPCMBuffer?
    private var waterDropBuffer: AVAudioPCMBuffer?
    
    init() {
        setupEngine()
        generateSynthBuffers()
    }
    
    private func setupEngine() {
        engine.attach(playerNode)
        engine.attach(pitchEffect)
        
        // Formatı açıkça belirlemezsek hoparlörün Stereo (2 kanal) formatını alır ve
        // Mono (1 kanal) buffer yüklemeye çalıştığımızda (scheduleBuffer) uygulama ÇÖKER!
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)
        
        // player -> pitch -> mixer (Zorunlu format ile)
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
        // UI'daki Picker değişikliğini algılar
        currentTheme = theme
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
        }
        
        guard let pcmBuffer = bufferToPlay else { return }
        
        // Sesi biraz rastgeleleştir (Makineleşmeyi önlemek için)
        pitchEffect.pitch = Float.random(in: -100...100)
        
        // Sadece arka arkaya hızlıca basıldığında buffer'ı anında çal.
        playerNode.scheduleBuffer(pcmBuffer, at: nil, options: .interrupts)
        
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    // ==========================================
    // MARK: - AUDIO SYNTHESIS GENERATORS
    // ==========================================
    
    private func generateSynthBuffers() {
        // Standart format: 44.1kHz, 1 kanal (Mono) The Float32 format
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false) else { return }
        
        // Önce gerçek .wav dosyalarını okumayı dener. Eğer dosya yoksa/hatalıysa sentetik matematik formülüne düşer.
        self.mechanicalBuffer = loadAudioFile(name: "mechanical", format: format) ?? createClickBuffer(format: format, type: .mechanical)
        self.mechanicalClickyBuffer = createClickBuffer(format: format, type: .mechanicalClicky)
        self.typewriterBuffer = loadAudioFile(name: "typewriter", format: format) ?? createClickBuffer(format: format, type: .typewriter)
        self.scifiBuffer = createClickBuffer(format: format, type: .scifi)
        self.arcadeBuffer = createClickBuffer(format: format, type: .arcade)
        self.waterDropBuffer = createClickBuffer(format: format, type: .waterDrop)
    }
    
    private func loadAudioFile(name: String, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        // macOS bundle içerisindeki Sounds klasörünü oku
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
    
    enum SynthType { case mechanical, mechanicalClicky, typewriter, scifi, arcade, waterDrop }
    
    private func createClickBuffer(format: AVAudioFormat, type: SynthType) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        // Her ses için süreler farklı (0.04 - 0.1 sn arası)
        let duration: Double
        switch type {
        case .mechanical: duration = 0.04
        case .mechanicalClicky: duration = 0.04
        case .typewriter: duration = 0.08
        case .scifi:      duration = 0.06
        case .arcade:     duration = 0.08
        case .waterDrop:  duration = 0.06
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
                // Su damlası
                let env = Float(exp(-t * 60.0))
                // frekans lineer olarak artar
                let currentFreq = 300.0 + 800.0 * (t / duration)
                let osc = sin(2.0 * .pi * currentFreq * t)
                sample = Float(osc) * env * 1.5
            }
            
            // Satürasyon
            if sample > 1.0 { sample = 1.0 }
            if sample < -1.0 { sample = -1.0 }
            
            channelData[i] = sample
        }
        
        return buffer
    }
}
