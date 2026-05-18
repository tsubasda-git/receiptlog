import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, description: String, color: Color)] = [
        (
            icon: "camera.viewfinder",
            title: "撮るだけで完了",
            description: "レシートを撮影するだけで\n金額・店名・日付を自動読み取り",
            color: Color.receiptAccent
        ),
        (
            icon: "tag.fill",
            title: "カテゴリで整理",
            description: "食費・交通費・外食など\n7カテゴリで自動分類。後から変更もOK",
            color: .blue
        ),
        (
            icon: "chart.pie.fill",
            title: "月次集計で把握",
            description: "今月いくら使ったか一目瞭然。\nカテゴリ別グラフでお金の流れを確認",
            color: .green
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(
                        icon: pages[index].icon,
                        title: pages[index].title,
                        description: pages[index].description,
                        iconColor: pages[index].color
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasLaunchedBefore = true
                }
            }) {
                Text(currentPage < pages.count - 1 ? "次へ" : "はじめる")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.receiptAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Color.receiptBackground)
    }
}

struct OnboardingPageView: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(iconColor)
            Text(title)
                .font(.title.bold())
                .foregroundStyle(Color.receiptText)
            Text(description)
                .font(.body)
                .foregroundStyle(Color.receiptSubtext)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
