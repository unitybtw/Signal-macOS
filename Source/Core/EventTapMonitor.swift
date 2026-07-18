import Cocoa
import CoreGraphics

class EventTapMonitor {
    var onKeyEvent: ((CGEvent, Bool) -> Void)?
    private var eventPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        // macOS Erişilebilirlik iznini kontrol et (Yoksak pop-up çıkar)
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("Uyarı: Signal'ın tuş vuruşlarını dinlemek için Erişilebilirlik iznine ihtiyacı var.")
        }

        // Sadece KeyDown ve KeyUp eventlerini dinle
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        // Callback closure tanımı (C fonksiyonu işaretçisi yerine statik metod üzerinden yönlendirme)
        eventPort = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if let refcon = refcon {
                    let monitor = Unmanaged<EventTapMonitor>.fromOpaque(refcon).takeUnretainedValue()
                    if type == .keyDown || type == .keyUp {
                        let isDown = (type == .keyDown)
                        monitor.onKeyEvent?(event, isDown)
                    }
                }
                // Event'i sisteme ve diğer uygulamalara olduğu gibi geçir
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        if let port = eventPort {
            // Run loop'a ekle (arka planda dinlemek için)
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
            if let source = runLoopSource {
                CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
                CGEvent.tapEnable(tap: port, enable: true)
                print("EventTap Monitor: Başarıyla başlatıldı.")
            }
        } else {
            print("Hata: EventTap oluşturulamadı. Muhtemelen Erişilebilirlik izni yok veya Sandbox devrede.")
        }
    }

    func stop() {
        if let port = eventPort {
            CGEvent.tapEnable(tap: port, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            CFMachPortInvalidate(port)
            eventPort = nil
            runLoopSource = nil
        }
    }
}
