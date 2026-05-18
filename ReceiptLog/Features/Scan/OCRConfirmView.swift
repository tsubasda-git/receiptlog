import SwiftUI

struct OCRConfirmView: View {
    let ocrResult: OCRResult
    let capturedImage: UIImage?
    let onSave: (Receipt) -> Void

    @State private var storeName: String
    @State private var totalAmount: String
    @State private var date: Date
    @State private var selectedCategory: Category = .other
    @Environment(\.dismiss) private var dismiss

    init(ocrResult: OCRResult, capturedImage: UIImage?, onSave: @escaping (Receipt) -> Void) {
        self.ocrResult = ocrResult
        self.capturedImage = capturedImage
        self.onSave = onSave
        _storeName   = State(initialValue: ocrResult.storeName)
        _totalAmount = State(initialValue: ocrResult.totalAmount.map { String($0) } ?? "")
        _date        = State(initialValue: ocrResult.date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(spacing: 16) {
                        FormField(title: "🏪 お店", placeholder: "店名を入力", text: $storeName)
                        DatePicker("📅 日付", selection: $date, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ja_JP"))

                        VStack(alignment: .leading) {
                            Text("💴 合計金額")
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("¥")
                                TextField("0", text: $totalAmount)
                                    .keyboardType(.numberPad)
                            }
                        }

                        VStack(alignment: .leading) {
                            Text("🏷️ カテゴリ")
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                ForEach(Category.allCases) { cat in
                                    Button(action: { selectedCategory = cat }) {
                                        Text(cat.rawValue)
                                            .font(.caption)
                                            .padding(.vertical, 6)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedCategory == cat ? Color.receiptAccent : Color.receiptBorder)
                                            .foregroundStyle(selectedCategory == cat ? .white : Color.receiptText)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.receiptCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("保存") { save() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.receiptAccent)
                        .frame(maxWidth: .infinity)
                        .controlSize(.large)
                }
                .padding()
            }
            .background(Color.receiptBackground)
            .navigationTitle("確認・編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let amount = Int(totalAmount) ?? 0
        var imageData: Data?
        if let image = capturedImage {
            let resized = image.preparingThumbnail(of: CGSize(width: 1024, height: 1024))
            imageData = (resized ?? image).jpegData(compressionQuality: 0.8)
        }
        let receipt = Receipt(
            date: date,
            storeName: storeName.isEmpty ? "不明" : storeName,
            totalAmount: amount,
            category: selectedCategory.rawValue,
            imageData: imageData
        )
        onSave(receipt)
    }
}

struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
