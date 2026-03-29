import Cocoa
import SwiftUI

@main
struct SignalAppBootstrap {
    static var delegate: AppDelegate?
    
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory) // Uygulamayı Dock'tan gizle ve menüye sabitle
        self.delegate = AppDelegate()
        app.delegate = self.delegate
        app.run()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    
    // Core Dependencies
    let eventMonitor = EventTapMonitor()
    let audioSynthesizer = AudioSynthesizer()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Popover ve SwiftUI View ayarları
        let contentView = MenuView(audioSynthesizer: audioSynthesizer)

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 380)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        // Siberpunk temasına uyumlu olması için tamamen saydam ve dark denemesi
        popover.appearance = NSAppearance(named: .vibrantDark)
        self.popover = popover

        // Menü çubuğu ikonu
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = self.statusBarItem.button {
            if let image = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: "Signal") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "🎛️ Signal" // Geri dönüş (Yedek metin)
            }
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Klavye dinlemeyi ve ses sentezlemeyi başlat
        audioSynthesizer.start()
        
        
        // Dinleyiciye basma olayı gelince sentezleyiciye aktar
        eventMonitor.onKeyDown = { [weak self] event in
            DispatchQueue.main.async {
                self?.audioSynthesizer.playKeySound()
                NotificationCenter.default.post(name: NSNotification.Name("KeyPressNotification"), object: nil)
            }
        }
        
        // Kullanıcı sonradan izin verirse dinleyiciyi (EventTap) yeniden başlat
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RestartMonitor"), object: nil, queue: .main) { [weak self] _ in
            self?.eventMonitor.stop()
            self?.eventMonitor.start()
        }
        
        eventMonitor.start()
    }

    @objc func togglePopover(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            let menu = NSMenu()
            
            let muteItem = NSMenuItem(title: audioSynthesizer.isMuted ? "▶️ Sesleri Aç" : "⏸️ Devre Dışı Bırak", action: #selector(toggleMute), keyEquivalent: "")
            muteItem.target = self
            menu.addItem(muteItem)
            
            menu.addItem(NSMenuItem.separator())
            
            let quitItem = NSMenuItem(title: "Signal'den Çık", action: #selector(quitApp), keyEquivalent: "q")
            quitItem.target = self
            menu.addItem(quitItem)
            
            // Popover açıksa kapat
            if self.popover.isShown {
                self.popover.performClose(sender)
            }
            
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 5), in: sender)
        } else {
            if self.popover.isShown {
                self.popover.performClose(sender)
            } else {
                self.popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.minY)
                self.popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    @objc func toggleMute() {
        audioSynthesizer.isMuted.toggle()
        // İkonu sessize alındığında gri yapmak için (Opsiyonel)
        if let button = self.statusBarItem.button {
            button.alphaValue = audioSynthesizer.isMuted ? 0.3 : 1.0
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
