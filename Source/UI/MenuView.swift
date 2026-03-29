import SwiftUI
import AppKit

struct MenuView: View {
    @ObservedObject var audioSynthesizer: AudioSynthesizer
    
    @State private var keysPressed: Int = 0
    @State private var hasPermission: Bool = AXIsProcessTrusted()
    let pub = NotificationCenter.default.publisher(for: NSNotification.Name("KeyPressNotification"))

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.title2)
                    .foregroundColor(hasPermission ? .accentColor : .red)
                Text("Signal")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Uygulamayı Kapat")
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
            
            Divider()
            
            // Ayarlar Listesi
            VStack(alignment: .leading, spacing: 20) {
                
                // İZİN UYARISI
                if !hasPermission {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("Erişilebilirlik İzni Gerekli", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.red)
                        Text("Klavye seslerinin çalışması için Signal'e tuş dinleme izni vermelisiniz.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Button("Ayarları Aç") {
                            let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                            if let url = URL(string: urlString) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .controlSize(.small)
                        .padding(.top, 4)
                        
                        Button("İzni Kontrol Et") {
                            let newStatus = AXIsProcessTrusted()
                            if newStatus && !hasPermission {
                                NotificationCenter.default.post(name: NSNotification.Name("RestartMonitor"), object: nil)
                            }
                            hasPermission = newStatus
                        }
                        .controlSize(.small)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Tema Seçici
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ses Profili")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Picker("Ses Profili", selection: Binding(
                        get: { audioSynthesizer.currentTheme },
                        set: { newTheme in audioSynthesizer.setTheme(newTheme) }
                    )) {
                        Text("Mekanik").tag(AudioTheme.mechanical)
                        Text("Daktilo").tag(AudioTheme.typewriter)
                        Text("Sci-Fi").tag(AudioTheme.scifi)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                }
                
                // Volume
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Ses Seviyesi")
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
                Label("\(keysPressed) strikes", systemImage: "keyboard")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Label(hasPermission ? "Aktif" : "Sessiz", systemImage: "circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(hasPermission ? .green : .red)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 260)
        .onReceive(pub) { _ in
            keysPressed += 1
        }
        .onAppear {
            hasPermission = AXIsProcessTrusted()
        }
    }
}
