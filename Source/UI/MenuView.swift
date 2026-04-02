import SwiftUI
import AppKit

struct RecentKey: Identifiable {
    let id = UUID()
    let char: String
}

struct MenuView: View {
    @ObservedObject var audioSynthesizer: AudioSynthesizer
    @Namespace private var selectionNamespace
    
    @State private var keysPressed: Int = 0
    @State private var recentKeystrokes: [Date] = []
    @State private var keyHistory: [RecentKey] = []
    @State private var audioPulseActive: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    let pub = NotificationCenter.default.publisher(for: NSNotification.Name("KeyPressNotification"))

    var body: some View {
        let wpmCount = Double(recentKeystrokes.count)
        let wpm = (wpmCount * 12.0) / 5.0
        let accentColor = wpm >= 100 ? Color.red : (wpm >= 60 ? Color.orange : Color.blue)

        VStack(spacing: 0) {
            // --- HEADER ---
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.title3)
                    .foregroundColor(audioSynthesizer.hasPermission && !audioSynthesizer.isMuted ? .accentColor : .gray)
                    .scaleEffect(audioPulseActive ? 1.2 : 1.0)
                
                Text("Signal")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .shadow(color: .accentColor.opacity(audioPulseActive ? 0.4 : 0), radius: 6)
                    .scaleEffect(audioPulseActive ? 1.05 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: audioPulseActive)
                
                Spacer()
                
                if !audioSynthesizer.hasPermission {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                        .opacity(audioPulseActive ? 0.5 : 1.0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
            
            Divider()
            
            // --- MAIN CONTENT ---
            VStack(alignment: .leading, spacing: 18) {
                // İZİN VEYA TUŞ GEÇMİŞİ AKTİVİTESİ (Sabit Yükseklik)
                VStack(alignment: .leading, spacing: 0) {
                    if !audioSynthesizer.hasPermission {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Accessibility Required")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Please allow 'Signal' in Settings.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Button("Settings") {
                                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                                }
                                .controlSize(.small)
                                
                                Button("Check") {
                                    withAnimation(.spring()) {
                                        audioSynthesizer.hasPermission = AXIsProcessTrusted()
                                    }
                                }
                                .controlSize(.small)
                            }
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(8)
                        .transition(.opacity)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Live History")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            HStack(spacing: 6) {
                                ForEach(keyHistory) { key in
                                    Text(key.char)
                                        .font(.system(size: 11, design: .monospaced))
                                        .frame(width: 20, height: 20)
                                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.06)))
                                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
                                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                                }
                                
                                if keyHistory.isEmpty {
                                    Text("Type something...")
                                        .font(.system(size: 11))
                                        .italic()
                                        .foregroundColor(Color.secondary.opacity(0.5))
                                }
                                Spacer()
                            }
                            .frame(height: 24)
                        }
                        .padding(.vertical, 10)
                        .transition(.opacity)
                    }
                }
                .frame(height: 85, alignment: .top)
                
                // SES PROFİLİ SEÇİCİ
                VStack(alignment: .leading, spacing: 8) {
                    Text("Audio Profile")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(AudioTheme.allCases, id: \.self) { theme in
                                    let isSelected = audioSynthesizer.currentTheme == theme
                                    Button(action: {
                                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.2)) {
                                            audioSynthesizer.setTheme(theme)
                                            proxy.scrollTo(theme, anchor: .center)
                                        }
                                    }) {
                                        Text(theme.displayName)
                                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? .primary : .primary.opacity(0.6))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(
                                                ZStack {
                                                    if isSelected {
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .fill(Color(NSColor.controlBackgroundColor))
                                                            .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.05), lineWidth: 0.5))
                                                            .matchedGeometryEffect(id: "segmentSelection", in: selectionNamespace)
                                                    } else {
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .fill(Color.clear)
                                                    }
                                                }
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .id(theme)
                                }
                            }
                            .padding(4)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                        }
                    }
                }
                
                // VOLUME & AYARLAR
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Volume")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        HStack(spacing: 2) {
                            ForEach(0..<4) { index in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(audioSynthesizer.isMuted ? Color.gray : Color.blue)
                                    .frame(width: 2, height: audioPulseActive ? CGFloat.random(in: 4...12) : 2)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: audioPulseActive)
                            }
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: audioSynthesizer.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                            .onTapGesture {
                                withAnimation { audioSynthesizer.isMuted.toggle() }
                            }
                        
                        Slider(value: $audioSynthesizer.volume, in: 0...1)
                            .accentColor(.blue)
                        
                        Text("\(Int(audioSynthesizer.volume * 100))%")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 32)
                    }
                    
                    HStack {
                        Label("Sys. Error Sound", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary.opacity(0.8))
                        
                        Spacer()
                        
                        Toggle("", isOn: $audioSynthesizer.isErrorSoundEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                            .labelsHidden()
                            .controlSize(.small)
                    }
                }
            }
            .padding(16)
            
            Divider()
            
            // --- FOOTER ---
            VStack(spacing: 6) {
                HStack {
                    Label("\(keysPressed)", systemImage: "keyboard")
                        .font(.system(size: 9, design: .monospaced))
                    
                    Spacer()
                    
                    Label("\(Int(wpm)) WPM", systemImage: "bolt.fill")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(wpm >= 100 ? .red : (wpm >= 60 ? .orange : .secondary))
                        .scaleEffect(audioPulseActive ? 1.05 : 1.0)
                        .shadow(color: wpm >= 60 ? (wpm >= 100 ? Color.red : Color.orange).opacity(0.3) : Color.clear, radius: 2)
                    
                    Spacer()
                    
                    let isReallyActive = audioSynthesizer.hasPermission && !audioSynthesizer.isMuted
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isReallyActive ? .green : .red)
                            .frame(width: 6, height: 6)
                            .scaleEffect(audioPulseActive ? 1.3 : 1.0)
                        
                        Text(isReallyActive ? "Active" : "Silenced")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Signal v2.0")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.7))
                    
                    Spacer()
                    
                    Text("Right-click for credits")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            .contextMenu {
                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://github.com/unitybtw")!)
                }) {
                    Text("Developer: Siraç Göktuğ Şimşek")
                }
                Divider()
                Text("Version 2.0.0 (Stable)")
            }
        }
        .background(
            ZStack {
                Circle()
                    .fill(accentColor.opacity(audioPulseActive ? (wpm / 150.0 + 0.05) : 0.02))
                    .blur(radius: audioPulseActive ? 50 : 70)
                    .frame(width: 200, height: 200)
                    .offset(x: audioPulseActive ? CGFloat.random(in: -30...30) : 0, 
                            y: audioPulseActive ? CGFloat.random(in: -30...30) : 0)
                    .animation(.easeInOut(duration: 0.5), value: audioPulseActive)
            }
        )
        .background(VisualEffectView(material: .popover, blendingMode: .withinWindow))
        .frame(width: 260)
        .onReceive(pub) { _ in
            let newKey = RecentKey(char: "•") 
            withAnimation(.spring()) {
                keyHistory.append(newKey)
                if keyHistory.count > 5 { keyHistory.removeFirst() }
            }
            
            audioPulseActive = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                audioPulseActive = false
            }
            
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
