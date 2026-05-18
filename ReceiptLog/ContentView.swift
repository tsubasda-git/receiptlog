import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ScanView()
                .tabItem { Label("スキャン", systemImage: "camera.fill") }
            ReceiptListView()
                .tabItem { Label("一覧", systemImage: "list.bullet.rectangle") }
            DashboardView()
                .tabItem { Label("集計", systemImage: "chart.pie.fill") }
            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
        }
        .tint(Color.receiptAccent)
    }
}
