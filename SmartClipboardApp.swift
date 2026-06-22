import SwiftUI
import AppKit

@main
struct SmartClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var eventTap: CFMachPort?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set app as accessory (hides from dock, runs in background)
        NSApp.setActivationPolicy(.accessory)

        // Create the window
        let contentView = ContentView()

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window?.center()
        window?.setFrameAutosaveName("SmartClipboard Window")
        window?.contentView = NSHostingView(rootView: contentView)
        window?.title = "SmartClipboard"
        window?.isReleasedWhenClosed = false
        window?.level = .floating // Keep on top

        setupGlobalShortcut()
    }

    func setupGlobalShortcut() {
        // Use CGEvent tap for reliable global hotkey capture
        let eventMask = (1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()

            if type == .keyDown {
                let flags = event.flags
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

                // Command + Control + V
                let commandControl: CGEventFlags = [.maskCommand, .maskControl]
                if flags.contains(commandControl) && keyCode == 9 {
                    DispatchQueue.main.async {
                        appDelegate.toggleWindow()
                    }
                    return nil // Swallow the event
                }
            }

            return Unmanaged.passUnretained(event)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: selfPtr
        )

        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    func toggleWindow() {
        if let window = window {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}
