import Vision
import UIKit

enum OCRError: Error {
    case recognitionFailed
    case noTextFound
    case invalidImage
}

struct OCRResult: Equatable {
    var storeName: String
    var totalAmount: Int?
    var date: Date
    var rawText: String
}

actor OCRService {
    func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["ja-JP", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results, !observations.isEmpty else {
            throw OCRError.noTextFound
        }

        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        let fullText = lines.joined(separator: "\n")

        let storeName = OCRService.extractStoreName(from: lines)
        let totalAmount = OCRService.extractAmount(from: fullText)
        let date = OCRService.extractDate(from: fullText) ?? Date()

        return OCRResult(
            storeName: storeName,
            totalAmount: totalAmount,
            date: date,
            rawText: fullText
        )
    }

    private static let storeNameBlacklist: [String] = [
        "レシート", "領収書", "お買い上げ", "ありがとう", "またお越し",
        "合計", "税込", "税抜", "小計", "お会計", "おつり", "お釣り",
        "現金", "クレジット", "電子マネー", "Suica", "PayPay",
        "TEL", "FAX", "〒", "営業時間", "定休日"
    ]

    static func extractStoreName(from lines: [String]) -> String {
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.count >= 2 else { continue }
            let isBlacklisted = storeNameBlacklist.contains { trimmed.contains($0) }
            guard !isBlacklisted else { continue }
            let hasOnlyDigitsAndPunctuation = trimmed.allSatisfy { $0.isNumber || "/-:.,￥¥ ".contains($0) }
            guard !hasOnlyDigitsAndPunctuation else { continue }
            return trimmed
        }
        return ""
    }

    static func extractAmount(from text: String) -> Int? {
        let patterns = [
            "税込合計[\\s\u{3000}：:]*[¥￥]?([0-9,]+)",
            "ご請求額[\\s\u{3000}：:]*[¥￥]?([0-9,]+)",
            "お支払い金額[\\s\u{3000}：:]*[¥￥]?([0-9,]+)",
            "合計[\\s\u{3000}：:]*[¥￥]?([0-9,]+)",
            "お会計[\\s\u{3000}：:]*[¥￥]?([0-9,]+)",
            "TOTAL[\\s]*[¥￥]?([0-9,]+)",
            "SUBTOTAL[\\s]*[¥￥]?([0-9,]+)",
            "[¥￥]([0-9,]+)"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let amountStr = String(text[range]).replacingOccurrences(of: ",", with: "")
                return Int(amountStr)
            }
        }
        return nil
    }

    static func extractDate(from text: String) -> Date? {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ja_JP")

        // 西暦: YYYY/MM/DD or YYYY-MM-DD
        let westernPatterns = [
            "(\\d{4})[/\\-](\\d{1,2})[/\\-](\\d{1,2})",
            "(\\d{2})[/\\-](\\d{1,2})[/\\-](\\d{1,2})"
        ]
        for pattern in westernPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let r1 = Range(match.range(at: 1), in: text),
               let r2 = Range(match.range(at: 2), in: text),
               let r3 = Range(match.range(at: 3), in: text) {
                let y = Int(text[r1]) ?? 0
                var components = DateComponents()
                components.year  = y < 100 ? 2000 + y : y
                components.month = Int(text[r2])
                components.day   = Int(text[r3])
                if let date = calendar.date(from: components) { return date }
            }
        }

        // 元号: 令和/平成/昭和 元年 or N年M月D日（「元」= 1年に対応）
        let japanesePattern = "(令和|平成|昭和)(元|\\d{1,2})年(\\d{1,2})月(\\d{1,2})日"
        if let regex = try? NSRegularExpression(pattern: japanesePattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let r1 = Range(match.range(at: 1), in: text),
           let r2 = Range(match.range(at: 2), in: text),
           let r3 = Range(match.range(at: 3), in: text),
           let r4 = Range(match.range(at: 4), in: text) {
            let era = String(text[r1])
            let nStr = String(text[r2])
            let n = nStr == "元" ? 1 : (Int(nStr) ?? 1)
            let month = Int(text[r3]) ?? 1
            let day = Int(text[r4]) ?? 1
            let baseYear: Int
            switch era {
            case "令和": baseYear = 2018 + n
            case "平成": baseYear = 1988 + n
            case "昭和": baseYear = 1925 + n
            default:     baseYear = 2024
            }
            var components = DateComponents()
            components.year = baseYear
            components.month = month
            components.day = day
            if let date = calendar.date(from: components) { return date }
        }

        return nil
    }
}
