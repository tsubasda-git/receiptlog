import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(StoreKitService.self) private var storeKit
    @Environment(\.modelContext) private var modelContext
    @State private var showSubscription = false
    @State private var showDeleteAlert = false

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
                    Label("CSV書き出し", systemImage: "doc.text")
                        .foregroundStyle(storeKit.isPremium ? Color.receiptText : Color.receiptSubtext)
                        .overlay(alignment: .trailing) {
                            if !storeKit.isPremium {
                                Image(systemName: "lock.fill").foregroundStyle(Color.receiptSubtext)
                            }
                        }
                    Button("すべてのデータを削除", role: .destructive) { showDeleteAlert = true }
                }

                Section("サポート") {
                    Link("プライバシーポリシー", destination: URL(string: "https://tsubasda-git.github.io/receiptlog/privacy.html")!)
                    Link("利用規約", destination: URL(string: "https://tsubasda-git.github.io/receiptlog/privacy.html")!)
                    Button("購入を復元") {
                        Task { try? await storeKit.restorePurchases() }
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
                    try? modelContext.delete(model: Receipt.self)
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この操作は元に戻せません")
            }
        }
    }
}
