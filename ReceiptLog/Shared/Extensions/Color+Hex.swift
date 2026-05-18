import SwiftUI
import UIKit

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

    // MARK: – Dark Mode 対応アダプティブカラー
    static let receiptBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1) // ウォームダーク
            : UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1) // クリーム
    })
    static let receiptCard = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.15, blue: 0.13, alpha: 1) // ダークカード
            : UIColor.white
    })
    static let receiptText = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.94, green: 0.93, blue: 0.91, alpha: 1) // ウォームライト
            : UIColor(red: 0.17, green: 0.16, blue: 0.15, alpha: 1) // ダークブラウン
    })
    static let receiptSubtext = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.55, green: 0.53, blue: 0.50, alpha: 1)
            : UIColor(red: 0.62, green: 0.58, blue: 0.54, alpha: 1)
    })
    static let receiptAccent = Color(hex: "#C0623A") // テラコッタ（固定）
    static let receiptBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.24, green: 0.22, blue: 0.20, alpha: 1)
            : UIColor(red: 0.93, green: 0.91, blue: 0.88, alpha: 1)
    })
}
