import StoreKit
import Observation

enum StoreKitError: Error {
    case productNotFound
    case purchaseFailed
    case networkError
}

@MainActor
@Observable
final class StoreKitService {
    var isPremium: Bool = false
    var products: [Product] = []
    var isLoading: Bool = false
    var loadError: String?

    private var transactionListenerTask: Task<Void, Never>?

    static let monthlyProductID = "com.kbytsubasa.ReceiptLog.premium.monthly"
    static let yearlyProductID  = "com.kbytsubasa.ReceiptLog.premium.yearly"

    init() {
        startTransactionListener()
    }

    private func startTransactionListener() {
        transactionListenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.checkCurrentEntitlements()
                }
            }
        }
    }

    func loadProducts() async {
        loadError = nil
        do {
            products = try await Product.products(for: [
                Self.monthlyProductID,
                Self.yearlyProductID
            ])
        } catch {
            loadError = "商品情報を読み込めませんでした"
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws {
        isLoading = true
        defer { isLoading = false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                isPremium = true
            case .unverified:
                throw StoreKitError.purchaseFailed
            }
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        try await AppStore.sync()
        await checkCurrentEntitlements()
    }

    func checkCurrentEntitlements() async {
        var hasPremium = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               (transaction.productID == Self.monthlyProductID ||
                transaction.productID == Self.yearlyProductID),
               transaction.revocationDate == nil {
                hasPremium = true
            }
        }
        isPremium = hasPremium
    }
}
