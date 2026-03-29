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
    
    let pub = NotificationCenter.default.publisher(for: NSNotification.Name("KeyPressNotification"))

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.title3)
                    .foregroundColor(audioSynthesizer.hasPermission && !audioSynthesizer.isMuted ? .accentColor : .gray)
                Text("Signal")
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
                
                if !audioSynthesizer.hasPermission {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(14)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                
                // İZİN UYARISI
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
                                withAnimation {
                                    audioSynthesizer.hasPermission = AXIsProcessTrusted()
                                }
                            }
                            .controlSize(.small)
                        }
                    }
                    .padding(10)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(10)
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
                                    .transition(.scale.combined(with: .opacity))
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
                }
                
                // SÜRÜKLENEBİLİR GERÇEK APPLE STYLE LIQUID GLASS
                VStack(alignment: .leading, spacing: 10) {
                    Text("Audio Profile")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            ZStack(alignment: .leading) {
                                // Arkaplan Kanalı
                                Capsule()
                                    .fill(Color.primary.opacity(0.05))
                                    .frame(height: 32)
                                
                                HStack(spacing: 0) {
                                    ForEach(AudioTheme.allCases, id: \.self) { theme in
                                        let isSelected = audioSynthesizer.currentTheme == theme
                                        
                                        Text(theme.displayName)
                                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? .white : .primary.opacity(0.6))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.4)) {
                                                    audioSynthesizer.setTheme(theme)
                                                    proxy.scrollTo(theme, anchor: .center)
                                                }
                                            }
                                            .background(
                                                ZStack {
                                                    if isSelected {
                                                        Capsule()
                                                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                                                            .matchedGeometryEffect(id: "liquidSelection", in: selectionNamespace)
                                                            .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 2)
                                                            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
                                                    }
                                                }
                                            )
                                            .id(theme)
                                    }
                                }
                            }
                            .padding(4)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        // Sürükleme ile ses seçme mantığı
                                        let x = value.location.x
                                        let segmentWidth: CGFloat = 80 // Tahmini genişlik, GeometryReader ile daha kesin yapılabilir
                                        let index = Int(x / segmentWidth)
                                        let themes = AudioTheme.allCases
                                        if index >= 0 && index < themes.count {
                                            let theme = themes[index]
                                            if theme != audioSynthesizer.currentTheme {
                                                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                                                    audioSynthesizer.setTheme(theme)
                                                    proxy.scrollTo(theme, anchor: .center)
                                                }
                                            }
                                        }
                                    }
                            )
                        }
                    }
                }
                
                // Volume
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Volume")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Spacer()
                        Text("\(Int(audioSynthesizer.volume * 100))%")
                            .font(.system(size: 10, design: .monospaced))
                    }
                    
                    Slider(value: $audioSynthesizer.volume, in: 0...1)
                }
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
