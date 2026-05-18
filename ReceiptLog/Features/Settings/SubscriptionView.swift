import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(StoreKitService.self) private var storeKit
    @Environment(\.dismiss) private var dismiss
    @State private var showPurchaseToast = false
    @State private var showRestoreToast = false
    @State private var restoreMessage = ""

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
                        Text("商品情報を読み込んでいます...")
                            .foregroundStyle(Color.receiptSubtext)
                            .font(.caption)
                    } else {
                        HStack(spacing: 12) {
                            ForEach(storeKit.products, id: \.id) { product in
                                PlanCard(product: product, isDisabled: storeKit.isLoading) {
                                    Task {
                                        do {
                                            try await storeKit.purchase(product)
                                            if storeKit.isPremium {
                                                showPurchaseToast = true
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                                            }
                                        } catch {
                                            // userCancelled は無視、その他は将来的にアラート表示
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

                    Text("サブスクリプションは自動更新されます。キャンセルはApp Store設定から行えます。")
                        .font(.caption2)
                        .foregroundStyle(Color.receiptSubtext)
                        .multilineTextAlignment(.center)
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
