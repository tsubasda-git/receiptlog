import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(StoreKitService.self) private var storeKit
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Receipt.date, order: .reverse) private var allReceipts: [Receipt]
    @State private var showSubscription = false
    @State private var showDeleteAlert = false
    @State private var showRestoreToast = false
    @State private var restoreMessage = ""
    @State private var deleteError = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if storeKit.isPremium {
                        Label("プレミアム利用中", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Color.receiptAccent)
                    } else {
                        Button(action: { showSubscription = true }) {
                            Label("プレミアムにアップグレード", systemImage: "star.fill")
                                .foregroundStyle(Color.receiptAccent)
                        }
                    }
                }

                Section("データ") {
                    if storeKit.isPremium {
                        ShareLink(
                            item: generateCSV(),
                            preview: SharePreview("ReceiptLog.csv", icon: Image(systemName: "doc.text"))
                        ) {
                            Label("CSV書き出し", systemImage: "doc.text")
                                .foregroundStyle(Color.receiptText)
                        }
                    } else {
                        Button(action: { showSubscription = true }) {
                            HStack {
                                Label("CSV書き出し", systemImage: "doc.text")
                                    .foregroundStyle(Color.receiptSubtext)
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(Color.receiptSubtext)
                            }
                        }
                    }
                    Button("すべてのデータを削除", role: .destructive) { showDeleteAlert = true }
                }

                Section("サポート") {
                    Link("プライバシーポリシー", destination: URL(string: "https://tsubasda-git.github.io/receiptlog/privacy.html")!)
                    Link("利用規約", destination: URL(string: "https://tsubasda-git.github.io/receiptlog/terms.html")!)
                    Button("購入を復元") {
                        Task {
                            do {
                                try await storeKit.restorePurchases()
                                restoreMessage = storeKit.isPremium
                                    ? "✓ 復元しました"
                                    : "復元できる購入が見つかりませんでした"
                            } catch {
                                restoreMessage = "復元に失敗しました"
                            }
                            showRestoreToast = true
                        }
                    }
                }

                Section {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(Color.receiptSubtext)
                    }
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
            .alert("全データを削除しますか？", isPresented: $showDeleteAlert) {
                Button("削除", role: .destructive) {
                    do {
                        try modelContext.delete(model: Receipt.self)
                    } catch {
                        deleteError = true
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この操作は元に戻せません")
            }
            .alert("削除エラー", isPresented: $deleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("データの削除に失敗しました")
            }
            .toast(isPresented: $showRestoreToast, message: restoreMessage)
        }
    }

    private func generateCSV() -> String {
        var csv = "日付,店名,金額,カテゴリ,メモ\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        for receipt in allReceipts {
            let date = dateFormatter.string(from: receipt.date)
            let store = receipt.storeName.replacingOccurrences(of: ",", with: "、")
            let category = receipt.category
            let notes = receipt.notes
                .replacingOccurrences(of: ",", with: "、")
                .replacingOccurrences(of: "\n", with: " ")
            csv += "\(date),\(store),\(receipt.totalAmount),\(category),\(notes)\n"
        }
        return csv
    }
}
