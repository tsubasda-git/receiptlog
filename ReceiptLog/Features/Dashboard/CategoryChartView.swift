import SwiftUI
import Charts

struct CategoryChartView: View {
    let data: [(Category, Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("カテゴリ別グラフ")
                .font(.headline)
            Chart(data, id: \.0) { cat, total in
                SectorMark(
                    angle: .value("金額", total),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(cat.color)
                .annotation(position: .overlay) {
                    Text(cat.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.receiptCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
