import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(StoreKitService.self) private var storeKit
    @Environment(\.dismiss) private var dismiss
    @State private var showToast = false

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

                    HStack(spacing: 12) {
                        ForEach(storeKit.products, id: \.id) { product in
                            PlanCard(product: product) {
                                Task {
                                    try? await storeKit.purchase(product)
                                    if storeKit.isPremium {
                                        showToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
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
                        Task { try? await storeKit.restorePurchases() }
                    }
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
            .toast(isPresented: $showToast, message: "🎉 プレミアムへようこそ！")
        }
    }
}

struct PlanCard: View {
    let product: Product
    let onPurchase: () -> Void
    var isRecommended: Bool { product.id.contains("yearly") }

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
            Button("購入", action: onPurchase)
                .buttonStyle(.borderedProminent)
                .tint(Color.receiptAccent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isRecommended ? Color.receiptAccent.opacity(0.08) : Color.receiptCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(isRecommended ? RoundedRectangle(cornerRadius: 16).stroke(Color.receiptAccent, lineWidth: 2) : nil)
    }
}
