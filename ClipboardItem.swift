import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var content: String
    var timestamp: Date
    var isPinned: Bool = false
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.content == rhs.content
    }
}
