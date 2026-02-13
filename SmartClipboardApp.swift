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
    var eventMonitor: Any?
    
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
        // Register Command + Control + V (V is 9 in keycode)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let commandKey = event.modifierFlags.contains(.command)
            let controlKey = event.modifierFlags.contains(.control)
            let vKey = event.keyCode == 9 // 'V' key
            
            if commandKey && controlKey && vKey {
                self?.toggleWindow()
            }
        }
        
        // Also monitor local events if the app is focused
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let commandKey = event.modifierFlags.contains(.command)
            let controlKey = event.modifierFlags.contains(.control)
            let vKey = event.keyCode == 9
            
            if commandKey && controlKey && vKey {
                self?.toggleWindow()
                return nil // Swallow the event
            }
            return event
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
