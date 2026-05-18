import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(StoreKitService.self) private var storeKit
    @Environment(\.dismiss) private var dismiss
    @State private var showPurchaseToast = false
    @State private var showRestoreToast = false
    @State private var restoreMessage = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.receiptAccent)
                        Text("プレミアムプラン")
                            .font(.title2.bold())
                        Text("グラフ・CSV書き出しが使えるようになります")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.receiptSubtext)
                    }

                    if storeKit.isLoading && storeKit.products.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let error = storeKit.loadError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    } else if storeKit.products.isEmpty {
                        Text("商品情報を取得できませんでした。\nネットワーク接続を確認してください。")
                            .foregroundStyle(Color.receiptSubtext)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    } else {
                        HStack(spacing: 12) {
                            ForEach(storeKit.products, id: \.id) { product in
                                PlanCard(product: product, isDisabled: storeKit.isLoading) {
                                    Task {
                                        do {
                                            try await storeKit.purchase(product)
                                            if storeKit.isPremium {
                                                showPurchaseToast = true
                                                Task {
                                                    try? await Task.sleep(for: .milliseconds(1500))
                                                    dismiss()
                                                }
                                            }
                                        } catch StoreKitError.purchaseFailed {
                                            errorMessage = "購入できませんでした。もう一度お試しください。"
                                            showErrorAlert = true
                                        } catch StoreKitError.pending {
                                            errorMessage = "購入の承認待ちです。保護者の方に確認してください（Ask to Buy）。"
                                            showErrorAlert = true
                                        } catch {
                                            // userCancelled は無視
                                        }
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("無料プランでできること").font(.caption).foregroundStyle(Color.receiptSubtext)
                        Text("✅ レシートスキャン（無制限）\n✅ 一覧表示\n✅ 月次合計確認")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

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
                    .disabled(storeKit.isLoading)
                    .font(.footnote)
                    .foregroundStyle(Color.receiptSubtext)

                    // App Store審査要件：サブスクリプション免責事項
                    VStack(spacing: 6) {
                        Text("サブスクリプションについて")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.receiptSubtext)
                        Text("""
                        • 購入の確認後、Apple IDアカウントに料金が請求されます
                        • サブスクリプションは現在の期間終了の24時間前までにキャンセルしない限り、自動的に更新されます
                        • 更新料金は期間終了の24時間以内に請求されます
                        • 購入後はApp Store > Apple ID > サブスクリプションから管理・キャンセルできます
                        """)
                        .font(.caption2)
                        .foregroundStyle(Color.receiptSubtext)
                        .multilineTextAlignment(.leading)

                        HStack(spacing: 16) {
                            Link("プライバシーポリシー", destination: URL(string: "https://tsubasda-git.github.io/receiptlog/privacy.html")!)
                            Link("利用規約", destination: URL(string: "https://tsubasda-git.github.io/receiptlog/terms.html")!)
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.receiptAccent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .background(Color.receiptBackground)
            .navigationTitle("プレミアムへアップグレード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task { await storeKit.loadProducts() }
            .toast(isPresented: $showPurchaseToast, message: "🎉 プレミアムへようこそ！")
            .toast(isPresented: $showRestoreToast, message: restoreMessage)
            .alert("購入エラー", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
}

struct PlanCard: View {
    let product: Product
    let isDisabled: Bool
    let onPurchase: () -> Void
    var isRecommended: Bool { product.id.contains("yearly") }
    var periodText: String { isRecommended ? "毎年自動更新" : "毎月自動更新" }

    var body: some View {
        VStack(spacing: 12) {
            if isRecommended {
                Text("2ヶ月分お得").font(.caption).foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Color.receiptAccent).clipShape(Capsule())
            } else {
                Spacer().frame(height: 20)
            }
            Text(isRecommended ? "年額" : "月額").font(.caption).foregroundStyle(Color.receiptSubtext)
            Text(product.displayPrice).font(.title3.bold())
            Text(periodText).font(.caption2).foregroundStyle(Color.receiptSubtext)
            Button(action: onPurchase) {
                if isDisabled {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                } else {
                    Text("購入")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.receiptAccent)
            .disabled(isDisabled)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isRecommended ? Color.receiptAccent.opacity(0.08) : Color.receiptCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(isRecommended ? RoundedRectangle(cornerRadius: 16).stroke(Color.receiptAccent, lineWidth: 2) : nil)
    }
}
