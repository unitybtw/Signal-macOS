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
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.title3)
                    .foregroundColor(audioSynthesizer.hasPermission && !audioSynthesizer.isMuted ? .accentColor : .gray)
                    .scaleEffect(audioPulseActive ? 1.2 : 1.0)
                
                Text("Signal")
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
                
                if !audioSynthesizer.hasPermission {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                        .opacity(audioPulseActive ? 0.5 : 1.0)
                }
            }
            .padding(14)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
            .transition(.move(edge: .top).combined(with: .opacity))
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                
                // İZİN UYARISI (ANIMATED)
                if !audioSynthesizer.hasPermission {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Accessibility Required")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Allow 'Signal' in Settings.")
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
                    .padding(10)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(10)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                } else {
                    // --- CANLI TUŞ GEÇMİŞİ ---
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Live History")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        HStack(spacing: 8) {
                            ForEach(keyHistory) { key in
                                Text(key.char)
                                    .font(.system(size: 11, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.1)))
                                    .transition(.scale(scale: 0.5, anchor: .center).combined(with: .opacity))
                            }
                            
                            if keyHistory.isEmpty {
                                Text("Type something...")
                                    .font(.system(size: 11))
                                    .italic()
                                    .foregroundColor(Color.secondary.opacity(0.5))
                            }
                            
                            Spacer()
                        }
                        .frame(height: 30)
                    }
                    .transition(.opacity)
                }
                
                // ANTIGRAVITY SEÇİMİ: PREMİUM PURE GLASS SEÇİCİ
                VStack(alignment: .leading, spacing: 10) {
                    Text("Audio Profile")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(AudioTheme.allCases, id: \.self) { theme in
                                    let isSelected = audioSynthesizer.currentTheme == theme
                                    
                                    Button(action: {
                                        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.75, blendDuration: 0.3)) {
                                            audioSynthesizer.setTheme(theme)
                                            proxy.scrollTo(theme, anchor: .center)
                                        }
                                    }) {
                                        Text(theme.displayName)
                                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? .white : .primary.opacity(0.8))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                ZStack {
                                                    if isSelected {
                                                        Capsule()
                                                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                            .matchedGeometryEffect(id: "pureGlassSelection", in: selectionNamespace)
                                                            .shadow(color: .blue.opacity(0.4), radius: 8, y: 2)
                                                            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
                                                    } else {
                                                        Capsule()
                                                            .fill(Color.primary.opacity(0.04))
                                                    }
                                                }
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .id(theme)
                                }
                            }
                            .padding(4)
                        }
                    }
                }
                }
                
                // Dynamic Audio Pulse Waveform
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Volume")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        // Audio Pulse Bars
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(audioSynthesizer.isMuted ? Color.gray : Color.blue)
                                    .frame(width: 2, height: audioPulseActive ? CGFloat.random(in: 4...16) : 2)
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
                            .frame(width: 35)
                    }
                }
                .padding(.bottom, 6)
            }
            .padding(16)
            
            Divider()
            
            // Alt Bilgi Çubuğu
            HStack {
                Label("\(keysPressed)", systemImage: "keyboard")
                    .font(.system(size: 9, design: .monospaced))
                
                Spacer()
                
                let wpmCount = Double(recentKeystrokes.count)
                let wpm = (wpmCount * 12.0) / 5.0
                Label("\(Int(wpm)) WPM", systemImage: "bolt.fill")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(wpm > 0 ? .orange : .secondary)
                
                Spacer()
                
                let isReallyActive = audioSynthesizer.hasPermission && !audioSynthesizer.isMuted
                Circle()
                    .fill(isReallyActive ? .green : .red)
                    .frame(width: 6, height: 6)
                Text(isReallyActive ? "Active" : "Silenced")
                    .font(.system(size: 9, weight: .bold))
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        }
        .frame(width: 250)
        .onReceive(pub) { _ in
            let newKey = RecentKey(char: "•") 
            withAnimation(.spring()) {
                keyHistory.append(newKey)
                if keyHistory.count > 5 { keyHistory.removeFirst() }
            }
            
            // Pulse Effect
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
