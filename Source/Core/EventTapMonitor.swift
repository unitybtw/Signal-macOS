import Cocoa
import CoreGraphics

class EventTapMonitor {
    var onKeyDown: ((CGEvent) -> Void)?
    private var eventPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        // macOS Erişilebilirlik iznini kontrol et (Yoksak pop-up çıkar)
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("Uyarı: Signal'ın tuş vuruşlarını dinlemek için Erişilebilirlik iznine ihtiyacı var.")
        }

        // Sadece KeyDown eventlerini dinle (Flagleri dinlemiyoruz şimdilik sessiz olması için)
        // Eğer her tuş bırakılıp basıldığında (veya Shift basıldığında) ses çıkması isteniyorsa flagsChanged eklenebilir.
        let eventMask = (1 << CGEventType.keyDown.rawValue)

        // Callback closure tanımı (C fonksiyonu işaretçisi yerine statik metod üzerinden yönlendirme)
        eventPort = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if let refcon = refcon {
                    let monitor = Unmanaged<EventTapMonitor>.fromOpaque(refcon).takeUnretainedValue()
                    if type == .keyDown {
                        monitor.onKeyDown?(event)
                    }
                }
                // Event'i sisteme ve diğer uygulamalara olduğu gibi geçir
                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        if let port = eventPort {
            // Run loop'a ekle (arka planda dinlemek için)
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
            if let source = runLoopSource {
                CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
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
        }
    }
}
