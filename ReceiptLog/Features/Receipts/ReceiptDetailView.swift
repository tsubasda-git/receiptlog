import SwiftUI
import SwiftData

struct ReceiptDetailView: View {
    @Bindable var receipt: Receipt
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showEdit = false
    @State private var showSavedToast = false
    @State private var showFullImage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let data = receipt.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { showFullImage = true }
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption)
                                .padding(4)
                                .background(.black.opacity(0.4))
                                .foregroundStyle(.white)
                                .clipShape(Circle())
                                .padding(4)
                        }
                }
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "お店", value: receipt.storeName)
                    DetailRow(label: "日付", value: receipt.date.shortDateString)
                    DetailRow(label: "金額", value: "¥\(receipt.totalAmount.formatted())")
                    DetailRow(label: "カテゴリ", value: receipt.category)
                    if !receipt.notes.isEmpty {
                        DetailRow(label: "メモ", value: receipt.notes)
                    }
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
                HStack {
                    Button("編集") { showEdit = true }
                    Menu {
                        Button("削除", role: .destructive) { showDeleteAlert = true }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .alert("削除しますか？", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) {
                // dismiss先にしてからdelete（dismiss後にreceiptを参照するとクラッシュ）
                dismiss()
                Task { @MainActor in
                    modelContext.delete(receipt)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は元に戻せません")
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
                initialNotes: receipt.notes,
                onSave: { updated in
                    receipt.storeName = updated.storeName
                    receipt.totalAmount = updated.totalAmount
                    receipt.category = updated.category
                    receipt.date = updated.date
                    receipt.notes = updated.notes
                    showEdit = false
                    // シート閉じアニメーション完了後にトーストを出す
                    Task {
                        try? await Task.sleep(for: .milliseconds(400))
                        showSavedToast = true
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showFullImage) {
            if let data = receipt.imageData, let image = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                    Button(action: { showFullImage = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
            }
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
