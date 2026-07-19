import AVFoundation

struct SoundPack {
    let genericR0: AVAudioPCMBuffer?
    let genericR1: AVAudioPCMBuffer?
    let genericR2: AVAudioPCMBuffer?
    let genericR3: AVAudioPCMBuffer?
    let genericR4: AVAudioPCMBuffer?
    
    let space: AVAudioPCMBuffer?
    let enter: AVAudioPCMBuffer?
    let backspace: AVAudioPCMBuffer?
    let releaseGeneric: AVAudioPCMBuffer?
    let releaseSpace: AVAudioPCMBuffer?
    let releaseEnter: AVAudioPCMBuffer?
    let releaseBackspace: AVAudioPCMBuffer?
    
    static func load(folderName: String, format: AVAudioFormat) -> SoundPack? {
        // Here we will load files from Resources/Sounds/Real/folderName
        let loadBuffer: (String) -> AVAudioPCMBuffer? = { name in
            let exts = ["wav", "mp3", "ogg"]
            for ext in exts {
                if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Sounds/Real/\(folderName)"),
                   let file = try? AVAudioFile(forReading: url),
                   let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length)) {
                    do {
                        try file.read(into: buffer)
                        return buffer
                    } catch { continue }
                }
            }
            return nil
        }
        
        let genericR0 = loadBuffer("GENERIC_R0") ?? loadBuffer("a") ?? loadBuffer("GENERIC")
        let genericR1 = loadBuffer("GENERIC_R1") ?? genericR0
        let genericR2 = loadBuffer("GENERIC_R2") ?? genericR0
        let genericR3 = loadBuffer("GENERIC_R3") ?? genericR0
        let genericR4 = loadBuffer("GENERIC_R4") ?? genericR0
        
        let space = loadBuffer("SPACE") ?? loadBuffer("space") ?? genericR0
        let enter = loadBuffer("ENTER") ?? loadBuffer("enter") ?? genericR0
        let backspace = loadBuffer("BACKSPACE") ?? loadBuffer("backspace") ?? genericR0
        
        // release folders might not exist, but we try
        let releaseGeneric = loadBuffer("release/GENERIC")
        let releaseSpace = loadBuffer("release/SPACE")
        let releaseEnter = loadBuffer("release/ENTER")
        let releaseBackspace = loadBuffer("release/BACKSPACE")
        
        return SoundPack(
            genericR0: genericR0,
            genericR1: genericR1,
            genericR2: genericR2,
            genericR3: genericR3,
            genericR4: genericR4,
            space: space,
            enter: enter,
            backspace: backspace,
            releaseGeneric: releaseGeneric,
            releaseSpace: releaseSpace,
            releaseEnter: releaseEnter,
            releaseBackspace: releaseBackspace
        )
    }
}
