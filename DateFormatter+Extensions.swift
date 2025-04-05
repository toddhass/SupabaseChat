import Foundation

extension DateFormatter {
    static let messageTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let messageDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

extension Date {
    func formatted() -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            return "Today at \(DateFormatter.messageTimeFormatter.string(from: self))"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday at \(DateFormatter.messageTimeFormatter.string(from: self))"
        } else {
            return DateFormatter.fullDateFormatter.string(from: self)
        }
    }
}
