import SwiftUI
import AppKit
import Combine

class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    private var pasteboard = NSPasteboard.general
    private var changeCount: Int
    private var timer: AnyCancellable?
    
    init() {
        self.changeCount = pasteboard.changeCount
        loadItems()
        startMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkClipboard()
            }
    }
    
    private func checkClipboard() {
        if pasteboard.changeCount != changeCount {
            changeCount = pasteboard.changeCount
            if let str = pasteboard.string(forType: .string), !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                addItem(str)
            }
        }
    }
    
    private func addItem(_ content: String) {
        // Don't add if it's the same as the last item (unless it's different in pinning status, but we check content)
        if let first = items.first, first.content == content {
            return
        }
        
        // Remove duplicate if it exists elsewhere in the list
        if let index = items.firstIndex(where: { $0.content == content }) {
            let item = items.remove(at: index)
            var newItem = item
            newItem.timestamp = Date()
            items.insert(newItem, at: 0)
        } else {
            let newItem = ClipboardItem(content: content, timestamp: Date())
            items.insert(newItem, at: 0)
        }
        
        sortItems() // Ensure pinned items stay at top after adding new content
        
        // Limit history size (e.g., 50 items)
        if items.count > 50 {
            // Keep pinned items, remove oldest unpinned
            let pinnedCount = items.filter { $0.isPinned }.count
            if items.count > pinnedCount + 50 {
                if let lastUnpinnedIndex = items.lastIndex(where: { !$0.isPinned }) {
                    items.remove(at: lastUnpinnedIndex)
                }
            }
        }
        
        saveItems()
    }
    
    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func togglePin(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isPinned.toggle()
            // Re-sort: pinned items at top
            sortItems()
            saveItems()
        }
    }
    
    func editItem(_ item: ClipboardItem, newContent: String) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].content = newContent
            saveItems()
        }
    }
    
    func clearAll() {
        items.removeAll { !$0.isPinned }
        saveItems()
    }
    
    func copyToClipboard(_ item: ClipboardItem, autoPaste: Bool = true) {
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        self.changeCount = pasteboard.changeCount
        
        if autoPaste {
            simulatePaste()
        }
    }
    
    private func simulatePaste() {
        // Hide the app first so the focus returns to the previous app
        NSApp.hide(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let source = CGEventSource(stateID: .combinedSessionState)
            // Command + V
            let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            vDown?.flags = .maskCommand
            let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            vUp?.flags = .maskCommand
            
            vDown?.post(tap: .cgAnnotatedSessionEventTap)
            vUp?.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
    
    private func sortItems() {
        items.sort { (a, b) -> Bool in
            if a.isPinned != b.isPinned {
                return a.isPinned
            }
            return a.timestamp > b.timestamp
        }
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "ClipboardHistory")
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: "ClipboardHistory"),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            self.items = decoded
            sortItems()
        }
    }
}
