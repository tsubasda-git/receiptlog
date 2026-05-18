import SwiftUI
import SwiftData

struct ReceiptListView: View {
    let switchToScan: () -> Void

    @Query(sort: \Receipt.date, order: .reverse) private var allReceipts: [Receipt]
    @Environment(\.modelContext) private var modelContext
    @State private var currentMonth: Date = Date()
    @State private var receiptToDelete: Receipt?
    @State private var searchText: String = ""

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var monthReceipts: [Receipt] {
        allReceipts.filter { $0.date.isSameMonth(as: currentMonth) }
    }

    private var searchResults: [Receipt] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return allReceipts.filter { receipt in
            receipt.storeName.localizedCaseInsensitiveContains(query) ||
            receipt.category.localizedCaseInsensitiveContains(query)
        }
    }

    private var monthTotal: Int {
        monthReceipts.reduce(0) { $0 + $1.totalAmount }
    }

    private var displayedGrouped: [(Date, [Receipt])] {
        let source = isSearching ? searchResults : monthReceipts
        let grouped = Dictionary(grouping: source) { receipt -> Date in
            Calendar.current.startOfDay(for: receipt.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !isSearching {
                    HStack {
                        Button { changeMonth(by: -1) } label: {
                            Image(systemName: "chevron.left")
                        }
                        .accessibilityLabel("前の月")
                        Spacer()
                        VStack {
                            Text(currentMonth.monthYearString)
                                .font(.headline)
                            Text("¥\(monthTotal.formatted())")
                                .font(.subheadline)
                                .foregroundStyle(Color.receiptAccent)
                        }
                        Spacer()
                        Button { changeMonth(by: 1) } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(Calendar.current.isDate(currentMonth, equalTo: Date(), toGranularity: .month))
                        .accessibilityLabel("次の月")
                    }
                    .padding()
                    .background(Color.receiptCard)
                }

                if isSearching && searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.receiptSubtext)
                        Text("「\(searchText)」の検索結果はありません")
                            .foregroundStyle(Color.receiptSubtext)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.receiptBackground)
                } else if !isSearching && monthReceipts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.receiptSubtext)
                        Text("まだレシートがありません")
                            .foregroundStyle(Color.receiptSubtext)
                        Button(action: switchToScan) {
                            Label("レシートをスキャン", systemImage: "camera.fill")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.receiptAccent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.receiptBackground)
                } else {
                    List {
                        ForEach(displayedGrouped, id: \.0) { date, receipts in
                            Section(header: Text(date.shortDateString).foregroundStyle(Color.receiptSubtext)) {
                                ForEach(receipts) { receipt in
                                    NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                                        ReceiptRowView(receipt: receipt)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button("削除", role: .destructive) {
                                            receiptToDelete = receipt
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color.receiptBackground)
                }
            }
            .navigationTitle("レシート")
            .background(Color.receiptBackground)
            .searchable(text: $searchText, prompt: "店名・カテゴリで検索")
            .alert("削除しますか？", isPresented: Binding(
                get: { receiptToDelete != nil },
                set: { if !$0 { receiptToDelete = nil } }
            )) {
                Button("削除", role: .destructive) {
                    if let receipt = receiptToDelete {
                        modelContext.delete(receipt)
                    }
                    receiptToDelete = nil
                }
                Button("キャンセル", role: .cancel) {
                    receiptToDelete = nil
                }
            } message: {
                Text("この操作は元に戻せません")
            }
        }
    }

    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
}
