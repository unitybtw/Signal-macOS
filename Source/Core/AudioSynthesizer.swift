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
        
        // player -> pitch -> mixer
        engine.connect(playerNode, to: pitchEffect, format: nil)
        engine.connect(pitchEffect, to: engine.mainMixerNode, format: nil)
        
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
        
        self.mechanicalBuffer = createClickBuffer(format: format, type: .mechanical)
        self.typewriterBuffer = createClickBuffer(format: format, type: .typewriter)
        self.scifiBuffer = createClickBuffer(format: format, type: .scifi)
    }
    
    enum SynthType { case mechanical, typewriter, scifi }
    
    private func createClickBuffer(format: AVAudioFormat, type: SynthType) -> AVAudioPCMBuffer? {
        // Çok kısa bir sample süresi (0.05 saniye = ~2205 frame @ 44.1kHz)
        let sampleRate = format.sampleRate
        let duration: Double = (type == .scifi) ? 0.08 : 0.04
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        
        for i in 0..<Int(frameCount) {
            let time = Double(i) / sampleRate
            var sample: Float = 0.0
            
            // Envelope (Hızlı saldırı, hızlı sönümleme) - Tık sesi!
            let attackTime: Double = 0.002
            let decayTime: Double = duration - attackTime
            let envelope: Float
            if time < attackTime {
                envelope = Float(time / attackTime)
            } else {
                envelope = Float(1.0 - (time - attackTime) / decayTime)
            }
            
            switch type {
            case .mechanical:
                // Çift tıklama etkisi (Anahtar basımı ve dibe vurma) + Beyaz Gürültü (Plastik tok sesi)
                let noise = Float.random(in: -1.0...1.0)
                let freq: Float = time < 0.01 ? 1200 : 400
                let osc = sin(2.0 * .pi * freq * Float(time))
                sample = (osc * 0.3 + noise * 0.7)
                
            case .typewriter:
                // Metalik çınlama (Metallic ping): Yüksek frekans ve daha sert gürültü
                let noise = Float.random(in: -1.0...1.0)
                let freq: Float = 3000
                let ping = sin(2.0 * .pi * freq * Float(time))
                sample = (ping * 0.5 + noise * 0.5)
                
            case .scifi:
                // Lazer/Elektronik blip: Frekansı hızla düşen bir sinüs dalgası (Sweep down)
                let startFreq: Float = 2500
                let endFreq: Float = 400
                let currentFreq = startFreq - ((startFreq - endFreq) * Float(time / duration))
                let osc = sin(2.0 * .pi * currentFreq * Float(time))
                // Hafif kare dalga karakteri ver
                sample = osc > 0 ? 0.8 : -0.8
            }
            
            channelData[i] = sample * envelope
        }
        
        return buffer
    }
}
