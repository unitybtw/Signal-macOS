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
        let size = hostingController.sizeThatFits(in: NSSize(width: 260, height: 1000))
        popover.contentSize = NSSize(width: 260, height: size.height)
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
                button.title = "Signal" // Geri dönüş (Yedek metin)
            }
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Klavye dinlemeyi ve ses sentezlemeyi başlat
        audioSynthesizer.start()
        
        // Dinleyiciye basma olayı gelince sentezleyiciye aktar
        keyEventMonitor.onKeyEvent = { [weak self] event, isDown in
            guard let self = self else { return }
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            
            // OPTİMİZASYON: Ses sentezini Main Thread dışına alarak SIFIR GECİKME (Zero-latency) sağla
            self.audioSynthesizer.playKeySound(keyCode: keyCode, isDown: isDown)
            
            // Sadece tuşa basıldığında (down) hata seslerini çal ve arayüzü güncelle
            if isDown {
                if keyCode == 53 { // 53 = ESC key
                    self.audioSynthesizer.playErrorSound()
                }
                
                // Arayüz güncellemelerini sadece popover açıkken Main Thread'de yap (CPU Optimizasyonu)
                if self.popover.isShown {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("KeyPressNotification"), object: event)
                    }
                }
            }
        }
        
        keyEventMonitor.onMouseEvent = { [weak self] event, isLeft, location in
            guard let self = self else { return }
            self.audioSynthesizer.playMouseSound(isLeft: isLeft, location: location)
        }
        
        // Kullanıcı sonradan izin verirse dinleyiciyi (EventTap) yeniden başlat
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RestartMonitor"), object: nil, queue: .main) { [weak self] _ in
            self?.keyEventMonitor.stop()
            self?.keyEventMonitor.start()
        }
        
        keyEventMonitor.start()
        
        // Uygulama aktifken gereksiz "basso/funk" sesleri (macOS System Error Beep) çıkmasını engellemek için yerel event yutucu
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Eğer Command gibi modifier tuşları yoksa, event'i yutarak sistemin "bip" demesini engelle.
            return nil
        }
        
        // SMART AUTO-MUTE: Toplantı veya Medya uygulamaları açıldığında otomatik sessize al
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] notification in
            guard let self = self, let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            
            let blacklistedBundleIDs = [
                "us.zoom.xos", "com.microsoft.teams", "com.microsoft.teams2",
                "com.apple.FaceTime", "com.cisco.webexmeetingsapp", "com.skype.skype",
                "com.apple.QuickTimePlayerX", "com.colliderli.iina", "org.videolan.vlc"
            ]
            
            if let bundleID = app.bundleIdentifier, blacklistedBundleIDs.contains(bundleID) {
                self.audioSynthesizer.isSmartMutedActive = true
            } else {
                self.audioSynthesizer.isSmartMutedActive = false
            }
        }
        
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
            
            let muteItem = NSMenuItem(title: audioSynthesizer.isMuted ? "Unmute Sounds" : "Mute Sounds", action: #selector(toggleMute), keyEquivalent: "")
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
        
        // .minY popover'ın her zaman menü bar ikonunu merkezleyerek aşağı açılmasını sağlar.
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }

    func closePopover(_ sender: Any?) {
        popover.performClose(sender)
    }

    // NSPopoverDelegate: Pencerenin kopup (detach) ekran ortasına gitmesini engeller
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return false
    }
    
    func popoverDidShow(_ notification: Notification) {
        audioSynthesizer.isPopoverVisible = true
    }
    
    func popoverDidClose(_ notification: Notification) {
        audioSynthesizer.isPopoverVisible = false
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
