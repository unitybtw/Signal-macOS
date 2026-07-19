import Cocoa
import CoreGraphics

class EventTapMonitor {
    var onKeyEvent: ((CGEvent, Bool) -> Void)?
    var onMouseEvent: ((CGEvent, Bool, Bool, CGPoint) -> Void)?
    private var eventPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    fileprivate var lastFlags: UInt64 = 0 // Modifier keys state tracking

    func start() {
        // macOS Erişilebilirlik iznini kontrol et (Yoksak pop-up çıkar)
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("Uyarı: Signal'ın tuş vuruşlarını dinlemek için Erişilebilirlik iznine ihtiyacı var.")
        }

        // KeyDown, KeyUp, MouseDown, FlagsChanged (Modifier tuşları) ve SystemDefined (Medya tuşları) eventlerini dinle
        let maskKeyDown = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let maskKeyUp = CGEventMask(1 << CGEventType.keyUp.rawValue)
        let maskFlagsChanged = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        let maskLeftMouseDown = CGEventMask(1 << CGEventType.leftMouseDown.rawValue)
        let maskLeftMouseUp = CGEventMask(1 << CGEventType.leftMouseUp.rawValue)
        let maskRightMouseDown = CGEventMask(1 << CGEventType.rightMouseDown.rawValue)
        let maskRightMouseUp = CGEventMask(1 << CGEventType.rightMouseUp.rawValue)
        let maskSystemDefined = CGEventMask(1 << 14) // NX_SYSDEFINED = 14

        let eventMask = maskKeyDown | maskKeyUp | maskFlagsChanged | maskLeftMouseDown | maskLeftMouseUp | maskRightMouseDown | maskRightMouseUp | maskSystemDefined

        // Callback closure tanımı
        eventPort = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if let refcon = refcon {
                    let monitor = Unmanaged<EventTapMonitor>.fromOpaque(refcon).takeUnretainedValue()
                    
                    if type == .keyDown || type == .keyUp {
                        let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
                        if !isRepeat {
                            let isDown = (type == .keyDown)
                            monitor.onKeyEvent?(event, isDown)
                        }
                    } else if type == .flagsChanged {
                        // Modifier tuş basım/çekim kontrolü
                        let currentFlags = event.flags.rawValue
                        let isDown = currentFlags > monitor.lastFlags
                        monitor.lastFlags = currentFlags
                        monitor.onKeyEvent?(event, isDown)
                    } else if type.rawValue == 14 { // NX_SYSDEFINED
                        // Media keys (Volume, Brightness vb.)
                        // customKeyMacEventData1 alanını CGEvent'ten alamıyorsak NSEvent'e çevirelim
                        if let nsEvent = NSEvent(cgEvent: event) {
                            let data1 = nsEvent.data1
                            let isDown = (((data1 & 0xFFFF0000) >> 16) & 0x0A) == 0x0A
                            if isDown {
                                monitor.onKeyEvent?(event, true)
                            } else {
                                monitor.onKeyEvent?(event, false)
                            }
                        }
                    } else if type == .leftMouseDown || type == .rightMouseDown || type == .leftMouseUp || type == .rightMouseUp {
                        let isLeft = (type == .leftMouseDown || type == .leftMouseUp)
                        let isDown = (type == .leftMouseDown || type == .rightMouseDown)
                        monitor.onMouseEvent?(event, isLeft, isDown, event.location)
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
