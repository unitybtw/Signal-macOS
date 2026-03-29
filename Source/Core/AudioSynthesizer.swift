import AVFoundation
import CoreAudio
import Combine

enum AudioTheme {
    case mechanical
    case typewriter
    case scifi
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

    // 3 farklı synth buffer (Memory'de tutacağız, gecikme sıfır olacak)
    private var mechanicalBuffer: AVAudioPCMBuffer?
    private var typewriterBuffer: AVAudioPCMBuffer?
    private var scifiBuffer: AVAudioPCMBuffer?
    
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
        engine.connect(playerNode, to: pitchEffect, format: format)
        engine.connect(pitchEffect, to: engine.mainMixerNode, format: format)
        
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
        case .typewriter: bufferToPlay = typewriterBuffer
        case .scifi: bufferToPlay = scifiBuffer
        }
        
        guard let pcmBuffer = bufferToPlay else { return }
        
        // Sesi biraz rastgeleleştir (Makineleşmeyi önlemek için)
        // Mekanik klavyelerde her tuş slightly farklı ton çıkartır.
        pitchEffect.pitch = Float.random(in: -100...100)
        
        // Node'u durdurmaya gerek yok, scheduleBuffer üzerine yazmayı / sıraya koymayı yönetir
        // playerNode.stop() // if we stop it interrupts too harshly
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
        self.typewriterBuffer = loadAudioFile(name: "typewriter", format: format) ?? createClickBuffer(format: format, type: .typewriter)
        self.scifiBuffer = loadAudioFile(name: "scifi", format: format) ?? createClickBuffer(format: format, type: .scifi)
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
    
    enum SynthType { case mechanical, typewriter, scifi }
    
    private func createClickBuffer(format: AVAudioFormat, type: SynthType) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        // Her ses için süreler farklı (0.04 - 0.1 sn arası)
        let duration: Double
        switch type {
        case .mechanical: duration = 0.04
        case .typewriter: duration = 0.08
        case .scifi:      duration = 0.06
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
                // --- GERÇEKÇİ MEKANİK "THOCK" ---
                // Kalın plastik gövde ve tok bir vuruş hissi.
                let noise = Float.random(in: -1.0...1.0)
                
                // Attack (Keskin plastik çarpması)
                let attackEnv = Float(exp(-t * 800.0)) // Çok hızlı sönümlenen darbe
                let bodyEnv = Float(exp(-t * 150.0))   // Gövde rezonansı
                
                // Rezonans frekansları (Thock hissi için düşük frekans ağırlıklı)
                let freq1 = sin(2.0 * .pi * 120.0 * t) // Alt gövde tok sesi (Bass)
                let freq2 = sin(2.0 * .pi * 250.0 * t) // Orta sertlik
                let freq3 = sin(2.0 * .pi * 3000.0 * t) // Switch'in plastik çarpma click'i
                
                // Karışım: Bass rezonansları gövde zarfı ile, click ve gürültü darbe zarfı ile filtreleniyor
                let clickPart = (Float(freq3) * 0.2 + noise * 0.4) * attackEnv
                let thockPart = (Float(freq1) * 0.6 + Float(freq2) * 0.3 + noise * 0.1) * bodyEnv
                
                sample = (clickPart + thockPart) * 1.5
                
            case .typewriter:
                // --- VINTAGE DAKTİLO ---
                // Metalik, yaylı ve çınlamalı bir ses.
                let noise = Float.random(in: -1.0...1.0)
                
                // Daktilo tırnağının metale çarpması ve yay çınlaması
                let impactEnv = Float(exp(-t * 600.0))
                let ringEnv = Float(exp(-t * 50.0)) // Uzun metalik çınlama
                
                // Metal çınlama frekansları (birlikte uyumsuz harmonikler oluşturur)
                let ring1 = sin(2.0 * .pi * 1200.0 * t)
                let ring2 = sin(2.0 * .pi * 2400.0 * t)
                let ring3 = sin(2.0 * .pi * 3600.0 * t)
                
                let impact = noise * impactEnv
                let metallicRing = (Float(ring1) * 0.4 + Float(ring2) * 0.3 + Float(ring3) * 0.3) * ringEnv
                
                sample = (impact * 0.6 + metallicRing * 0.4) * 1.8
                
            case .scifi:
                // --- SİBERPUNK / SCİ-Fİ ---
                // Frekansı hızla düşen (Pew) dijital lazerimsi sinyal.
                let env = Float(exp(-t * 80.0))
                
                // Frekans 3000'den 500'e üstel olarak çok hızlı düşer
                let currentFreq = 500.0 + 2500.0 * exp(-t * 300.0)
                var osc = sin(2.0 * .pi * currentFreq * t)
                
                // Kare dalga efekti (Dijital distorsiyon / retro oyun tarzı)
                osc = osc > 0 ? 0.7 : -0.7
                
                // Hafif bir beyaz gürültü ekle ki tamamen "beep" gibi olmasın, daha havalı olsun
                let noise = Float.random(in: -1.0...1.0) * 0.1
                
                sample = (Float(osc) + noise) * env * 1.2
            }
            
            // Satürasyon (Çok yüksek sinyalleri yumuşakça bastırmak için - Distortion engeller)
            if sample > 1.0 { sample = 1.0 }
            if sample < -1.0 { sample = -1.0 }
            
            channelData[i] = sample
        }
        
        return buffer
    }
}
