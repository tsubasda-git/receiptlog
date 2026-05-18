import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    static let receiptBackground = Color(hex: "#FAF7F2")
    static let receiptCard       = Color(hex: "#FFFFFF")
    static let receiptAccent     = Color(hex: "#C0623A")
    static let receiptSubtext    = Color(hex: "#9E9589")
    static let receiptText       = Color(hex: "#2C2926")
    static let receiptBorder     = Color(hex: "#EDE8E0")
}
