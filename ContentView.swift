import SwiftUI

struct ContentView: View {
    @StateObject var manager = ClipboardManager()
    @State private var searchText = ""
    @State private var editingItem: ClipboardItem?
    @State private var editContent: String = ""
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return manager.items
        } else {
            return manager.items.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Menu {
                    Button("Remove unpinned items.") {
                        manager.clearAll()
                    }
                    Divider()
                    Button("Quit") {
                        NSApp.terminate(nil)
                    }
                } label: {
                    // Image(systemName: "gearshape")
                        // .foregroundColor(.gray)
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .frame(width: 20)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // List
            List {
                ForEach(filteredItems) { item in
                    ClipboardRow(item: item, 
                                 onCopy: { manager.copyToClipboard(item) },
                                 onPin: { manager.togglePin(item) },
                                 onDelete: { manager.deleteItem(item) },
                                 onEdit: { 
                                     editingItem = item
                                     editContent = item.content
                                 })
                }
            }
            .listStyle(PlainListStyle())
        }
        .frame(minWidth: 400, minHeight: 500)
        .sheet(item: $editingItem) { item in
            EditView(content: $editContent, onSave: {
                manager.editItem(item, newContent: editContent)
                editingItem = nil
            }, onCancel: {
                editingItem = nil
            })
        }
    }
}

struct ClipboardRow: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.content)
                    .lineLimit(2)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 10))
                }
            }
            
            HStack {
                Text(item.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isHovered {
                    HStack(spacing: 8) {
                        Button(action: onCopy) {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("複製")
                        
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("編輯")
                        
                        Button(action: onPin) {
                            Image(systemName: item.isPinned ? "pin.slash" : "pin")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(item.isPinned ? "取消置頂" : "置頂")
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("刪除")
                    }
                    .font(.system(size: 12))
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .onHover { hover in
            isHovered = hover
        }
        .onTapGesture(count: 2) {
            onCopy()
        }
    }
}

struct EditView: View {
    @Binding var content: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("編輯內容")
                .font(.headline)
            
            TextEditor(text: $content)
                .frame(minHeight: 100)
                .border(Color.gray.opacity(0.2))
            
            HStack {
                Button("取消", action: onCancel)
                Spacer()
                Button("儲存", action: onSave)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
