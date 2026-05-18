import SwiftUI
import Charts

struct MonthlyBarChartView: View {
    let data: [(String, Int)]

    var body: some View {
        Chart {
            ForEach(data, id: \.0) { label, total in
                BarMark(
                    x: .value("月", label),
                    y: .value("支出", total)
                )
                .foregroundStyle(Color.receiptAccent.gradient)
                .cornerRadius(4)
            }
        }
        .frame(height: 160)
        .chartYAxis {
            AxisMarks(format: .currency(code: "JPY").locale(Locale(identifier: "ja_JP")))
        }
    }
}
