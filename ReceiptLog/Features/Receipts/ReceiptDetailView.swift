import SwiftUI
import SwiftData

struct ReceiptDetailView: View {
    @Bindable var receipt: Receipt
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showEdit = false
    @State private var showSavedToast = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let data = receipt.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "お店", value: receipt.storeName)
                    DetailRow(label: "日付", value: receipt.date.shortDateString)
                    DetailRow(label: "金額", value: "¥\(receipt.totalAmount.formatted())")
                    DetailRow(label: "カテゴリ", value: receipt.category)
                }
                .padding()
                .background(Color.receiptCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .background(Color.receiptBackground)
        .navigationTitle(receipt.storeName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("編集") { showEdit = true }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button("削除", role: .destructive) { showDeleteAlert = true }
            }
        }
        .alert("削除しますか？", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) {
                modelContext.delete(receipt)
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        }
        .sheet(isPresented: $showEdit) {
            OCRConfirmView(
                ocrResult: OCRResult(
                    storeName: receipt.storeName,
                    totalAmount: receipt.totalAmount,
                    date: receipt.date,
                    rawText: ""
                ),
                capturedImage: receipt.imageData.flatMap { UIImage(data: $0) },
                onSave: { updated in
                    receipt.storeName = updated.storeName
                    receipt.totalAmount = updated.totalAmount
                    receipt.category = updated.category
                    receipt.date = updated.date
                    showEdit = false
                    showSavedToast = true
                }
            )
        }
        .toast(isPresented: $showSavedToast, message: "✓ 保存しました")
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(Color.receiptSubtext)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }
}
