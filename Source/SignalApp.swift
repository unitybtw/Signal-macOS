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
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.appearance = NSAppearance(named: .vibrantDark)
        self.popover = popover

        // Menü çubuğu ikonu
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = self.statusBarItem.button {
            // SF Symbol desteği
            if let image = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: "Signal") {
                image.isTemplate = true
                button.image = image
            } else {
                // macOS versiyonu veya SF Symbol hatası olursa default emoji kullan
                button.title = "🎛️ Signal"
            }
            button.action = #selector(togglePopover(_:))
            button.target = self
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
        
        eventMonitor.start()
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = self.statusBarItem.button {
            if self.popover.isShown {
                self.popover.performClose(sender)
            } else {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
}
