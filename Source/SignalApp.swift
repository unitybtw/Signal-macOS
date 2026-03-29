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

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var eventMonitor: Any? // Mouse clicks monitor
    
    // Core Dependencies
    let keyEventMonitor = EventTapMonitor()
    let audioSynthesizer = AudioSynthesizer()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Popover ve SwiftUI View ayarları
        let contentView = MenuView(audioSynthesizer: audioSynthesizer)

        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        let hostingController = NSHostingController(rootView: contentView)
        popover.contentViewController = hostingController
        
        // Sistemin açık/koyu modunu otomatik takip etmesi için özel görünümü kaldırıyoruz
        popover.appearance = nil
        self.popover = popover

        // Menü çubuğu ikonu - SABİT GENİŞLİK (Konum hatasını önler)
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: 28)
        
        if let button = self.statusBarItem.button {
            button.imagePosition = .imageOnly // Sadece ikon, metin yok (Hizalamayı korur)
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
        keyEventMonitor.onKeyDown = { [weak self] event in
            DispatchQueue.main.async {
                self?.audioSynthesizer.playKeySound()
                NotificationCenter.default.post(name: NSNotification.Name("KeyPressNotification"), object: event)
            }
        }
        
        // Kullanıcı sonradan izin verirse dinleyiciyi (EventTap) yeniden başlat
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RestartMonitor"), object: nil, queue: .main) { [weak self] _ in
            self?.keyEventMonitor.stop()
            self?.keyEventMonitor.start()
        }
        
        keyEventMonitor.start()
        
        // DIŞARI TIKLANDIĞINDA KAPATMA MONİTÖRÜ
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let self = self, self.popover.isShown {
                self.closePopover(event)
            }
        }
    }

    @objc func togglePopover(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            let menu = NSMenu()
            
            let muteItem = NSMenuItem(title: audioSynthesizer.isMuted ? "▶️ Unmute Sounds" : "⏸️ Mute Sounds", action: #selector(toggleMute), keyEquivalent: "")
            muteItem.target = self
            menu.addItem(muteItem)
            
            menu.addItem(NSMenuItem.separator())
            
            let quitItem = NSMenuItem(title: "Quit Signal", action: #selector(quitApp), keyEquivalent: "q")
            quitItem.target = self
            menu.addItem(quitItem)
            
            if self.popover.isShown {
                self.popover.performClose(sender)
            }
            
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 5), in: sender)
        } else {
            if self.popover.isShown {
                self.closePopover(sender)
            } else {
                showPopover(sender)
            }
        }
    }

    func showPopover(_ sender: NSStatusBarButton) {
        NSApp.activate(ignoringOtherApps: true)
        // .minY refers to the bottom edge of the button
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }

    func closePopover(_ sender: Any?) {
        popover.performClose(sender)
    }

    // NSPopoverDelegate: Pencerenin kopup (detach) ekran ortasına gitmesini engeller
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return false
    }
    
    @objc func toggleMute() {
        audioSynthesizer.isMuted.toggle()
        if let button = self.statusBarItem.button {
            button.alphaValue = audioSynthesizer.isMuted ? 0.3 : 1.0
        }
    }
    
    @objc func quitApp() {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        NSApplication.shared.terminate(nil)
    }
}
