import Foundation
import SwiftData

@Model
final class Receipt {
    var id: UUID
    var date: Date
    var storeName: String
    var totalAmount: Int
    var category: String
    var imageData: Data?
    var createdAt: Date
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        storeName: String,
        totalAmount: Int,
        category: String = Category.other.rawValue,
        imageData: Data? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.storeName = storeName
        self.totalAmount = totalAmount
        self.category = category
        self.imageData = imageData
        self.createdAt = Date()
        self.notes = notes
    }
}
