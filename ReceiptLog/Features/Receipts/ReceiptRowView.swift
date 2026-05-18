import SwiftUI

struct ReceiptRowView: View {
    let receipt: Receipt

    private var category: Category? {
        Category(rawValue: receipt.category)
    }

    var body: some View {
        HStack {
            Image(systemName: category?.icon ?? "doc.text.fill")
                .foregroundStyle(category?.color ?? Color.receiptAccent)
                .frame(width: 36, height: 36)
                .background((category?.color ?? Color.receiptAccent).opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(receipt.storeName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.receiptText)
                Text(receipt.category)
                    .font(.caption)
                    .foregroundStyle(Color.receiptSubtext)
            }

            Spacer()

            Text("¥\(receipt.totalAmount.formatted())")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.receiptAccent)
        }
        .padding(.vertical, 4)
    }
}
