import SwiftUI

struct MenuView: View {
    @ObservedObject var audioSynthesizer: AudioSynthesizer
    
    // Uygulama istatistikleri için bildirim dinleyici
    @State private var keysPressed: Int = 0
    let pub = NotificationCenter.default.publisher(for: NSNotification.Name("KeyPressNotification"))

    var body: some View {
        VStack(spacing: 0) {
            // macOS stili Header (Control Center gibi minimal)
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Signal")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Uygulamayı Kapat")
            }
            .padding()
            
            Divider()
            
            // Ayarlar Listesi (Form benzeri native görünüm)
            VStack(alignment: .leading, spacing: 16) {
                // Tema Seçici (Native Picker)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ses Profili")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: Binding(
                        get: { audioSynthesizer.currentTheme },
                        set: { newTheme in audioSynthesizer.setTheme(newTheme) }
                    )) {
                        Text("Mekanik (M-Switch)").tag(AudioTheme.mechanical)
                        Text("Daktilo (Vintage)").tag(AudioTheme.typewriter)
                        Text("Sci-Fi (Terminal)").tag(AudioTheme.scifi)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                }
                
                // Volume Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Ses Seviyesi")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(audioSynthesizer.volume * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $audioSynthesizer.volume, in: 0...1)
                        .controlSize(.small)
                }
            }
            .padding()
            
            Divider()
            
            // Alt Bilgi Çubuğu (Native Status Bar stili)
            HStack {
                Label("\(keysPressed) vuruş", systemImage: "keyboard")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Label("Aktif", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding(10)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        }
        .frame(width: 280) // Standart popover genişliği
        .onReceive(pub) { _ in
            keysPressed += 1
        }
    }
}
