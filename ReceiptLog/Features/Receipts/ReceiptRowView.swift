import SwiftUI

struct ReceiptRowView: View {
    let receipt: Receipt

    var body: some View {
        HStack {
            Image(systemName: "doc.text.fill")
                .foregroundStyle(Color.receiptAccent)
                .frame(width: 36, height: 36)
                .background(Color.receiptAccent.opacity(0.1))
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
