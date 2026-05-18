import StoreKit
import Observation

enum StoreKitError: Error {
    case productNotFound
    case purchaseFailed
    case networkError
}

@Observable
final class StoreKitService {
    var isPremium: Bool = false
    var products: [Product] = []
    var isLoading: Bool = false

    static let monthlyProductID = "com.kbytsubasa.ReceiptLog.premium.monthly"
    static let yearlyProductID  = "com.kbytsubasa.ReceiptLog.premium.yearly"

    func loadProducts() async {
        do {
            products = try await Product.products(for: [
                Self.monthlyProductID,
                Self.yearlyProductID
            ])
        } catch {
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
        try await AppStore.sync()
        await checkCurrentEntitlements()
    }

    func checkCurrentEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.monthlyProductID ||
                   transaction.productID == Self.yearlyProductID {
                    isPremium = true
                    return
                }
            }
        }
    }
}
