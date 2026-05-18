//
//  ReceiptLogApp.swift
//  ReceiptLog
//
//  Created by 小林翼颯 on 2026/05/18.
//

import SwiftUI
import SwiftData

@main
struct ReceiptLogApp: App {
    @State private var storeKitService: StoreKitService
    @State private var featureGate: FeatureGate

    init() {
        let sk = StoreKitService()
        _storeKitService = State(initialValue: sk)
        _featureGate = State(initialValue: FeatureGate(storeKitService: sk))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeKitService)
                .environment(featureGate)
                .task { await storeKitService.checkCurrentEntitlements() }
        }
        .modelContainer(for: Receipt.self)
    }
}
