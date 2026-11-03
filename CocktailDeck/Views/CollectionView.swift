import SwiftUI

// 我的作品集 Tab：自定义特调按保存时间倒序，带保存日期与集内搜索，
// 行点开就地展开（复用详情体），可编辑、可删除。
struct CollectionView: View {
    @Bindable var viewModel: DeckViewModel
    var onDetail: (Drink) -> Void

    @State private var query = ""
    @State private var expandedId: String?
    @State private var editing: CustomCocktail?

    private var sortedCustoms: [CustomCocktail] {
        viewModel.customDrinks.sorted { $0.createdAt > $1.createdAt }
    }

    private var filtered: [CustomCocktail] {
        guard !query.isEmpty else { return sortedCustoms }
        let q = query.lowercased()
        return sortedCustoms.filter { custom in
            let haystack = ([custom.nameEn, custom.nameZh ?? ""]
                + custom.ingredients.map { $0.name }
                + custom.baseSpirits + custom.flavors)
                .joined(separator: " ").lowercased()
            return haystack.contains(q)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("在作品集里搜", text: $query)
                    .textInputAutocapitalization(.never)
            }
            .padding(10)
            .background(Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(16)

            if filtered.isEmpty {
                ContentUnavailableView(
                    viewModel.customDrinks.isEmpty ? "还没有自己的特调" : "没有匹配的特调",
                    systemImage: "star",
                    description: Text(
                        viewModel.customDrinks.isEmpty
                        ? "点右上角“＋”写第一款，保存后它会进牌堆并带“我的特调”徽章。"
                        : "换个关键词再试。"
                    )
                )
            } else {
                List(filtered) { custom in
                    let drink = custom.asDrink()
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            withAnimation {
                                expandedId = (expandedId == custom.id) ? nil : custom.id
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(drink.name(for: viewModel.language))
                                        .font(.headline)
                                    Text("保存于 \(Self.dateFormatter.string(from: custom.createdAt))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VerificationBadge(label: .custom)
                                Image(systemName: expandedId == custom.id ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if expandedId == custom.id {
                            DrinkDetailBody(
                                drink: drink,
                                language: viewModel.language,
                                isInMenu: viewModel.isInMenu(drink),
                                onToggleMenu: { viewModel.toggleMenu(drink) }
                            )
                            .padding(.top, 4)
                            HStack(spacing: 12) {
                                Button("编辑") { editing = custom }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                Button("删除", role: .destructive) {
                                    viewModel.deleteCustom(id: custom.id)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                Spacer()
                                Button("查看详情") { onDetail(drink) }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $editing) { custom in
            CustomFormView(viewModel: viewModel, editing: custom)
        }
    }
}
