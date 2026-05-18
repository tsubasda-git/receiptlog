import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Receipt.date, order: .reverse) private var allReceipts: [Receipt]
    @State private var currentMonth: Date = Date()
    @Environment(FeatureGate.self) private var featureGate
    @State private var showSubscription = false

    private var monthReceipts: [Receipt] {
        allReceipts.filter { $0.date.isSameMonth(as: currentMonth) }
    }

    private var monthTotal: Int { monthReceipts.reduce(0) { $0 + $1.totalAmount } }

    private var prevMonthTotal: Int {
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) else { return 0 }
        return allReceipts.filter { $0.date.isSameMonth(as: prev) }.reduce(0) { $0 + $1.totalAmount }
    }

    private var categoryTotals: [(Category, Int)] {
        Category.allCases.compactMap { cat in
            let total = monthReceipts
                .filter { $0.category == cat.rawValue }
                .reduce(0) { $0 + $1.totalAmount }
            return total > 0 ? (cat, total) : nil
        }.sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 月ナビゲーション
                HStack {
                    Button { changeMonth(by: -1) } label: {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(currentMonth.monthYearString).font(.headline)
                    Spacer()
                    Button { changeMonth(by: 1) } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(Calendar.current.isDate(currentMonth, equalTo: Date(), toGranularity: .month))
                }
                .padding()
                .background(Color.receiptCard)

                if monthReceipts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.receiptSubtext)
                        Text("この月のデータがありません")
                            .foregroundStyle(Color.receiptSubtext)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.receiptBackground)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(spacing: 8) {
                                Text("¥\(monthTotal.formatted())")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundStyle(Color.receiptText)
                                let diff = monthTotal - prevMonthTotal
                                if diff != 0 {
                                    Text("\(diff > 0 ? "▲" : "▼")¥\(abs(diff).formatted()) 先月比")
                                        .font(.caption)
                                        .foregroundStyle(diff > 0 ? .red : .green)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.receiptCard)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            VStack(alignment: .leading, spacing: 12) {
                                Text("カテゴリ別").font(.headline)
                                ForEach(categoryTotals, id: \.0) { cat, total in
                                    HStack {
                                        Image(systemName: cat.icon).foregroundStyle(cat.color)
                                        Text(cat.rawValue)
                                        Spacer()
                                        Text("¥\(total.formatted())").fontWeight(.medium)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.receiptCard)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            if featureGate.isAvailable(.charts) {
                                CategoryChartView(data: categoryTotals)
                            } else {
                                Button(action: { showSubscription = true }) {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                        Text("グラフを見るにはプレミアムへ")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .padding()
                                    .background(Color.receiptAccent.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(Color.receiptAccent)
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color.receiptBackground)
                }
            }
            .navigationTitle("集計")
            .background(Color.receiptBackground)
            .sheet(isPresented: $showSubscription) { SubscriptionView() }
        }
    }

    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
}
