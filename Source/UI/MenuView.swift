import SwiftUI
import AppKit

struct MenuView: View {
    @ObservedObject var audioSynthesizer: AudioSynthesizer
    
    @State private var keysPressed: Int = 0
    @State private var recentKeystrokes: [Date] = []
    let pub = NotificationCenter.default.publisher(for: NSNotification.Name("KeyPressNotification"))

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.title2)
                    .foregroundColor(audioSynthesizer.hasPermission && !audioSynthesizer.isMuted ? .accentColor : .gray)
                Text("Signal")
                    .font(.headline)
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
            
            Divider()
            
            // Ayarlar Listesi
            VStack(alignment: .leading, spacing: 18) {
                
                // İZİN UYARISI
                if !audioSynthesizer.hasPermission {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Accessibility Required")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        
                        Text("Please allow 'Signal' in Settings.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button("Open Settings") {
                                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                            }
                            .controlSize(.small)
                            
                            Button("Check") {
                                audioSynthesizer.hasPermission = AXIsProcessTrusted()
                            }
                            .controlSize(.small)
                        }
                    }
                    .padding(10)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(10)
                }
                
                // Tema Seçici
                VStack(alignment: .leading, spacing: 8) {
                    Text("Audio Profile")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Picker("", selection: Binding(
                        get: { audioSynthesizer.currentTheme },
                        set: { newTheme in audioSynthesizer.setTheme(newTheme) }
                    )) {
                        Group {
                            Text("Mech (Linear)").tag(AudioTheme.mechanical)
                            Text("Mech (Clicky)").tag(AudioTheme.mechanicalClicky)
                            Text("Typewriter").tag(AudioTheme.typewriter)
                            Text("Sci-Fi").tag(AudioTheme.scifi)
                            Text("Arcade").tag(AudioTheme.arcade)
                            Text("Plop (Water)").tag(AudioTheme.waterDrop)
                            Text("Glockenspiel").tag(AudioTheme.glockenspiel)
                            Text("Wooden Block").tag(AudioTheme.woodenBlock)
                            Text("Vinyl Scratch").tag(AudioTheme.vinylScratch)
                            Text("Bubble Pop").tag(AudioTheme.bubblePop)
                        }
                        Group {
                            Text("Percussive Djembe").tag(AudioTheme.percussiveDjembe)
                            Text("Alien Blaster").tag(AudioTheme.alienBlaster)
                            Text("Sub 808").tag(AudioTheme.percussive808)
                            Text("Laser Gun").tag(AudioTheme.laserGun)
                            Text("Cat Meow").tag(AudioTheme.catMeow)
                        }
                    }
                    .pickerStyle(MenuPickerStyle()) 
                    .labelsHidden()
                }
                
                // Volume
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Volume")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(audioSynthesizer.volume * 100))%")
                            .font(.system(size: 10, design: .monospaced))
                    }
                    
                    Slider(value: $audioSynthesizer.volume, in: 0...1)
                }
            }
            .padding(16)
            
            // PENCERE BU HARİKADAN SONRA ÇAPASINI KAYBETMEZ
            Spacer(minLength: 0)
            
            Divider()
            
            // Alt Bilgi Çubuğu
            HStack {
                Label("\(keysPressed)", systemImage: "keyboard")
                    .font(.system(size: 10, design: .monospaced))
                
                Spacer()
                
                let wpmCount = Double(recentKeystrokes.count)
                let wpm = (wpmCount * 12.0) / 5.0
                Label("\(Int(wpm)) WPM", systemImage: "bolt.fill")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(wpm > 0 ? .orange : .gray)
                
                Spacer()
                
                let isReallyActive = audioSynthesizer.hasPermission && !audioSynthesizer.isMuted
                Label(isReallyActive ? "Active" : "Silenced", systemImage: "circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isReallyActive ? (audioSynthesizer.hasPermission ? .green : .orange) : .red)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 260, height: 380) // Sabit yükseklik, kesin konum!
        .onReceive(pub) { _ in
            keysPressed += 1
            let now = Date()
            recentKeystrokes.append(now)
            recentKeystrokes.removeAll { now.timeIntervalSince($0) > 5.0 }
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            let now = Date()
            recentKeystrokes.removeAll { now.timeIntervalSince($0) > 5.0 }
        }
    }
}
