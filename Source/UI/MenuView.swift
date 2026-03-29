import SwiftUI
import AppKit

struct MenuView: View {
    @ObservedObject var audioSynthesizer: AudioSynthesizer
    
    @State private var keysPressed: Int = 0
    @State private var recentKeystrokes: [Date] = []
    @State private var hasPermission: Bool = AXIsProcessTrusted()
    let pub = NotificationCenter.default.publisher(for: NSNotification.Name("KeyPressNotification"))

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.title2)
                    .foregroundColor(hasPermission && !audioSynthesizer.isMuted ? .accentColor : .gray)
                Text("Signal")
                    .font(.headline)
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
            
            Divider()
            
            // Ayarlar Listesi
            VStack(alignment: .leading, spacing: 20) {
                
                // İZİN UYARISI
                if !hasPermission {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("Accessibility Required", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.red)
                        Text("Signal needs key logging permission to play sounds.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Button("Open Settings") {
                            let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                            if let url = URL(string: urlString) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .controlSize(.small)
                        
                        Button("Check Permission") {
                            withAnimation {
                                let newStatus = AXIsProcessTrusted()
                                if newStatus && !hasPermission {
                                    NotificationCenter.default.post(name: NSNotification.Name("RestartMonitor"), object: nil)
                                }
                                hasPermission = newStatus
                            }
                        }
                        .controlSize(.small)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Tema Seçici
                VStack(alignment: .leading, spacing: 8) {
                    Text("Audio Profile")
                        .font(.system(size: 11, weight: .semibold))
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
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Spacer()
                        Text("\(Int(audioSynthesizer.volume * 100))%")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $audioSynthesizer.volume, in: 0...1)
                        .accentColor(hasPermission ? .accentColor : .gray)
                }
            }
            .padding(16)
            
            Divider()
            
            // Alt Bilgi Çubuğu
            HStack {
                Label("\(keysPressed)", systemImage: "keyboard")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                let wpm = (Double(recentKeystrokes.count) * 12.0) / 5.0
                Label("\(Int(wpm)) WPM", systemImage: "bolt.fill")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(wpm > 0 ? .orange : .gray)
                
                Spacer()
                
                let isReallyActive = hasPermission && !audioSynthesizer.isMuted
                Label(isReallyActive ? "Active" : "Silenced", systemImage: "circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isReallyActive ? .green : .red)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 260)
        .animation(.spring(), value: hasPermission)
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
        .onAppear {
            hasPermission = AXIsProcessTrusted()
        }
    }
}
