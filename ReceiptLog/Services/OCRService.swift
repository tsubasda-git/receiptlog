import Vision
import UIKit

enum OCRError: Error {
    case recognitionFailed
    case noTextFound
    case invalidImage
}

struct OCRResult {
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

        let storeName = lines.first(where: { $0.count > 2 }) ?? ""
        let totalAmount = OCRService.extractAmount(from: fullText)
        let date = OCRService.extractDate(from: fullText) ?? Date()

        return OCRResult(
            storeName: storeName,
            totalAmount: totalAmount,
            date: date,
            rawText: fullText
        )
    }

    static func extractAmount(from text: String) -> Int? {
        let patterns = [
            "合計[\\s\u{3000}]*[¥￥]?([0-9,]+)",
            "お会計[\\s\u{3000}]*([0-9,]+)",
            "[¥￥]([0-9,]+)",
            "TOTAL[\\s]*[¥￥]?([0-9,]+)"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let amountStr = String(text[range]).replacingOccurrences(of: ",", with: "")
                return Int(amountStr)
            }
        }
        return nil
    }

    static func extractDate(from text: String) -> Date? {
        let patterns = [
            "(\\d{4})[/\\-](\\d{1,2})[/\\-](\\d{1,2})",
            "(\\d{2})[/\\-](\\d{1,2})[/\\-](\\d{1,2})"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                var calendar = Calendar.current
                calendar.locale = Locale(identifier: "ja_JP")
                var components = DateComponents()
                if let r1 = Range(match.range(at: 1), in: text),
                   let r2 = Range(match.range(at: 2), in: text),
                   let r3 = Range(match.range(at: 3), in: text) {
                    let y = Int(text[r1]) ?? 0
                    components.year  = y < 100 ? 2000 + y : y
                    components.month = Int(text[r2])
                    components.day   = Int(text[r3])
                    return calendar.date(from: components)
                }
            }
        }
        return nil
    }
}
