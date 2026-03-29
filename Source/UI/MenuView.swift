import SwiftUI

struct MenuView: View {
    @ObservedObject var audioSynthesizer: AudioSynthesizer
    
    // Uygulama istatistikleri için bildirim dinleyici
    @State private var keysPressed: Int = 0
    let pub = NotificationCenter.default.publisher(for: NSNotification.Name("KeyPressNotification"))

    var body: some View {
        VStack(spacing: 0) {
                // Header (Control Center style)
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
                .help("Terminate Application")
            }
            .padding()
            
            Divider()
            
            // Settings List (Form-like native look)
            VStack(alignment: .leading, spacing: 16) {
                // Theme Picker (Native Picker)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Audio Profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: Binding(
                        get: { audioSynthesizer.currentTheme },
                        set: { newTheme in audioSynthesizer.setTheme(newTheme) }
                    )) {
                        Text("Mechanical (M-Switch)").tag(AudioTheme.mechanical)
                        Text("Typewriter (Vintage)").tag(AudioTheme.typewriter)
                        Text("Sci-Fi (Terminal)").tag(AudioTheme.scifi)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                }
                
                // Volume Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Volume Level")
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
            
            // Bottom Information Bar (Native Status Bar style)
            HStack {
                Label("\(keysPressed) strikes", systemImage: "keyboard")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Label("Active", systemImage: "circle.fill")
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
