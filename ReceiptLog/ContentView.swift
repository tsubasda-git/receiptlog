import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ScanView()
                .tabItem { Label("スキャン", systemImage: "camera.fill") }
                .tag(0)
            ReceiptListView(switchToScan: { selectedTab = 0 })
                .tabItem { Label("一覧", systemImage: "list.bullet.rectangle") }
                .tag(1)
            DashboardView()
                .tabItem { Label("集計", systemImage: "chart.pie.fill") }
                .tag(2)
            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(Color.receiptAccent)
        .fullScreenCover(isPresented: Binding(
            get: { !hasLaunchedBefore },
            set: { _ in }
        )) {
            OnboardingView()
        }
    }
}
