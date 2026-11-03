import SwiftUI

// 推荐 Tab：今日推荐 / 按聚会 / 按手头材料三段。
// 今日推荐按日期固定（午夜更换），“换一杯”按偏移量循环，不随机跳变；
// 按聚会只出前 6 款与匹配理由，人数不参与打分；
// 按手头材料三档排序，缺 1–2 样且有替代才进“替代后能做”。
struct RecommendView: View {
    @Bindable var viewModel: DeckViewModel
    var onDetail: (Drink) -> Void

    @State private var section = 0
    @State private var dailyOffset = 0
    @State private var scene: Recommendation.PartyScene = .gathering
    @State private var people: Recommendation.PeopleTier = .threeFive
    @State private var mood: Recommendation.PartyMood = .cozy
    @State private var checkedBases: Set<String> = []
    @State private var checkedMixers: Set<String> = []

    private var baseOptions: [String] {
        viewModel.allBaseSpirits.filter { $0 != "多基酒" && $0 != "利口酒为主" }
    }

    /// 常用辅料精选清单（不直接拿全量 mixers 字段，那里约 200 个值且中英混杂）。
    private let mixerOptions: [String] = [
        "苏打水", "汤力水", "可乐", "姜汁啤酒", "姜汁汽水",
        "柠檬汁", "青柠汁", "橙汁", "菠萝汁", "西柚汁", "蔓越莓汁", "番茄汁", "苹果汁",
        "糖浆", "蜂蜜", "石榴糖浆", "蛋清", "奶油", "牛奶", "咖啡",
        "苦精", "味美思", "薄荷", "黄瓜", "姜", "椰奶", "红茶", "柠檬水",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("推荐方式", selection: $section) {
                    Text("今日推荐").tag(0)
                    Text("按聚会").tag(1)
                    Text("按手头材料").tag(2)
                }
                .pickerStyle(.segmented)

                switch section {
                case 0: dailySection
                case 1: partySection
                default: materialsSection
                }
            }
            .padding(16)
        }
    }

    // MARK: - 今日推荐

    private var dailySection: some View {
        let picks = Recommendation.dailyPicks(
            drinks: viewModel.allDrinks,
            date: Date(),
            offset: dailyOffset
        )
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日推荐")
                    .font(.headline)
                Spacer()
                Button("换一杯") { dailyOffset += 1 }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            Text("每天固定一款，午夜更换；备选两款供换着喝。")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let main = picks.first {
                DrinkCardView(
                    drink: main,
                    language: viewModel.language,
                    isInMenu: viewModel.isInMenu(main),
                    onDetail: { onDetail(main) },
                    onToggleMenu: { viewModel.toggleMenu(main) }
                )
            }
            if picks.count > 1 {
                Text("备选")
                    .font(.headline)
                ForEach(Array(picks.dropFirst()), id: \.id) { drink in
                    Button {
                        onDetail(drink)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(drink.name(for: viewModel.language))
                                    .font(.subheadline.bold())
                                Text(drink.baseSpirits.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VerificationBadge(label: drink.verificationLabel)
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 按聚会

    private var partySection: some View {
        let hits = Recommendation.partyTop(
            drinks: viewModel.allDrinks,
            scene: scene,
            mood: mood
        )
        return VStack(alignment: .leading, spacing: 12) {
            Text("场景").font(.headline)
            chipRow(Recommendation.PartyScene.allCases, selection: $scene) { $0.rawValue }
            Text("人数").font(.headline)
            chipRow(Recommendation.PeopleTier.allCases, selection: $people) { $0.rawValue }
            Text("氛围").font(.headline)
            chipRow(Recommendation.PartyMood.allCases, selection: $mood) { $0.rawValue }

            if people == .sixTen || people == .overTen {
                Label(
                    "6 人以上：请按人数成倍放大用量、做大份批次，不要按单杯量出。",
                    systemImage: "person.3"
                )
                .font(.caption)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Text("为你选了 \(hits.count) 款（按场景风味亲和＋氛围修正叠加打分）")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(hits, id: \.drink.id) { hit in
                Button {
                    onDetail(hit.drink)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(hit.drink.name(for: viewModel.language))
                                .font(.subheadline.bold())
                            Spacer()
                            VerificationBadge(label: hit.drink.verificationLabel)
                        }
                        Text(hit.drink.baseSpirits.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !hit.reasons.isEmpty {
                            Text("因为：" + hit.reasons.joined(separator: "、"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func chipRow<T: Hashable>(
        _ options: [T],
        selection: Binding<T>,
        title: (T) -> String
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let selected = selection.wrappedValue == option
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Text(title(option))
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selected ? Color.accentColor : Color.secondary.opacity(0.12))
                            .foregroundStyle(selected ? Color.white : Color.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 按手头材料

    private var materialsSection: some View {
        let hits = Recommendation.materialsMatch(
            drinks: viewModel.allDrinks,
            checkedBases: checkedBases,
            checkedMixers: checkedMixers
        )
        return VStack(alignment: .leading, spacing: 12) {
            Text("手头基酒（多选）").font(.headline)
            FlowChips(options: baseOptions, selection: $checkedBases)
            Text("手头辅料（多选）").font(.headline)
            FlowChips(options: mixerOptions, selection: $checkedMixers)
            if checkedBases.isEmpty && checkedMixers.isEmpty {
                Text("勾选你手头的材料，牌堆会按可做程度排序。水、盐、冰算常备，不用勾。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(
                [Recommendation.MaterialTier.ready, .substitutable, .missing],
                id: \.self
            ) { tier in
                let group = hits.filter { $0.tier == tier }
                if !group.isEmpty {
                    Text("\(tier.rawValue)（\(group.count) 款）")
                        .font(.headline)
                    ForEach(group.prefix(30), id: \.drink.id) { hit in
                        Button {
                            onDetail(hit.drink)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(hit.drink.name(for: viewModel.language))
                                        .font(.subheadline.bold())
                                    Spacer()
                                    VerificationBadge(label: hit.drink.verificationLabel)
                                }
                                if hit.missing.isEmpty {
                                    Text("材料齐全")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(hit.missing, id: \.name) { item in
                                        HStack(alignment: .top, spacing: 4) {
                                            Text("缺 \(item.name)")
                                            if let sub = item.substitute {
                                                Text("→ 可用 \(sub)")
                                            }
                                            if let note = item.tasteNote {
                                                Text("（\(note)）")
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    if group.count > 30 {
                        Text("还有 \(group.count - 30) 款未列出，换关键词或多勾材料再筛。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct FlowChips: View {
    let options: [String]
    @Binding var selection: Set<String>

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76))], spacing: 8) {
            ForEach(options, id: \.self) { option in
                let selected = selection.contains(option)
                Button {
                    if selected {
                        selection.remove(option)
                    } else {
                        selection.insert(option)
                    }
                } label: {
                    Text(option)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(selected ? Color.accentColor : Color.secondary.opacity(0.12))
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
