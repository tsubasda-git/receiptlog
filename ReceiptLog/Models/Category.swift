import SwiftUI

enum Category: String, CaseIterable, Identifiable {
    case food          = "食費"
    case daily         = "日用品"
    case transport     = "交通費"
    case dining        = "外食"
    case entertainment = "娯楽"
    case medical       = "医療"
    case other         = "その他"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food:          return "cart.fill"
        case .daily:         return "bag.fill"
        case .transport:     return "tram.fill"
        case .dining:        return "fork.knife"
        case .entertainment: return "gamecontroller.fill"
        case .medical:       return "cross.fill"
        case .other:         return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food:          return Color(hex: "#4CAF50")
        case .daily:         return Color(hex: "#2196F3")
        case .transport:     return Color(hex: "#FF9800")
        case .dining:        return Color(hex: "#E91E63")
        case .entertainment: return Color(hex: "#9C27B0")
        case .medical:       return Color(hex: "#F44336")
        case .other:         return Color(hex: "#9E9589")
        }
    }
}
