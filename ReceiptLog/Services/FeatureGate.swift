import Observation

@Observable
final class FeatureGate {
    private let storeKitService: StoreKitService

    init(storeKitService: StoreKitService) {
        self.storeKitService = storeKitService
    }

    var isPremium: Bool { storeKitService.isPremium }

    enum PremiumFeature {
        case charts
        case csvExport
        case iCloudSync
    }

    func isAvailable(_ feature: PremiumFeature) -> Bool {
        isPremium
    }
}
