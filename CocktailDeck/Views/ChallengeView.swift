import SwiftUI

// 酒鬼挑战 Tab：单人经典 / 单人硬核 / 双人接力 × 6 / 8 / 10 杯。
// 发牌用每卡递增延迟的透明度＋位移动画；打勾计进度，全清出提示；
// 两套备选可换；当前菜单与打勾进度本地保存，重开接着喝。
struct ChallengeView: View {
    @Bindable var viewModel: DeckViewModel
    var onDetail: (Drink) -> Void

    @State private var mode: ChallengeMode = .classic
    @State private var tier = 6
    @State private var dealt = false

    private var state: ChallengeState? { viewModel.challenge }

    private func start() {
        let menus = ChallengeGenerator.generate(drinks: viewModel.allDrinks, mode: mode, tier: tier)
        viewModel.challenge = ChallengeState(
            mode: mode,
            tier: tier,
            menus: menus,
            currentIndex: 0,
            checked: []
        )
        viewModel.saveChallenge()
        dealt = false
        // 下一 runloop 再置 dealt，触发发牌动画。
        DispatchQueue.main.async { dealt = true }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("模式").font(.headline)
                Picker("模式", selection: $mode) {
                    ForEach(ChallengeMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Text("档位").font(.headline)
                Picker("档位", selection: $tier) {
                    Text("6 杯").tag(6)
                    Text("8 杯").tag(8)
                    Text("10 杯").tag(10)
                }
                .pickerStyle(.segmented)
                if mode == .duo {
                    Text("双人接力：每人 \(tier) 杯，A / B 轮流。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("发牌") { start() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                if let state {
                    currentMenuSection(state)
                } else {
                    Text("点“发牌”开始一局。经典按度数由低到高排，硬核偏中高度数＋偏难，双人 A / B 轮流。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("适量饮酒，开心最重要")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .onAppear {
            // 已有保存进度时直接亮牌，不用重发。
            if viewModel.challenge != nil {
                dealt = true
            }
        }
    }

    private func currentMenuSection(_ state: ChallengeState) -> some View {
        let drinks = state.currentMenu.compactMap { viewModel.drink(byId: $0) }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(state.mode.rawValue) · \(state.mode == .duo ? state.tier * 2 : state.tier) 杯")
                    .font(.headline)
                Spacer()
                Text("\(state.checkedCount) / \(state.currentMenu.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(state.checkedCount), total: Double(max(1, state.currentMenu.count)))

            if state.mode == .duo {
                let counts = state.duoCounts()
                HStack(spacing: 16) {
                    Text("A：\(counts.aChecked) / \(counts.aTotal)")
                    Text("B：\(counts.bChecked) / \(counts.bTotal)")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            if state.isComplete {
                Label("全清！这一局喝完了，悠着点。", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // 备选切换：三套牌（主牌＋两套备选）。
            if state.menus.count > 1 {
                HStack(spacing: 8) {
                    Text("牌组：").font(.subheadline)
                    ForEach(state.menus.indices, id: \.self) { index in
                        Button(index == 0 ? "主牌" : "备选 \(index)") {
                            viewModel.challenge?.currentIndex = index
                            viewModel.challenge?.checked = []
                            viewModel.saveChallenge()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(state.currentIndex == index ? .accentColor : .secondary)
                    }
                }
            }

            ForEach(Array(drinks.enumerated()), id: \.element.id) { index, drink in
                let checked = state.checked.contains(drink.id)
                challengeRow(drink, index: index, checked: checked, state: state)
                    .opacity(dealt ? 1 : 0)
                    .offset(y: dealt ? 0 : 16)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8)
                            .delay(Double(index) * 0.06),
                        value: dealt
                    )
            }

            Button("结束这一局", role: .destructive) {
                viewModel.clearChallenge()
                dealt = false
            }
            .buttonStyle(.bordered)
        }
    }

    private func challengeRow(_ drink: Drink, index: Int, checked: Bool, state: ChallengeState) -> some View {
        HStack(spacing: 10) {
            Button {
                if checked {
                    viewModel.challenge?.checked.remove(drink.id)
                } else {
                    viewModel.challenge?.checked.insert(drink.id)
                }
                viewModel.saveChallenge()
            } label: {
                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(checked ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Button {
                onDetail(drink)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        if state.mode == .duo {
                            Text(index % 2 == 0 ? "A" : "B")
                                .font(.caption.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }
                        Text(drink.name(for: viewModel.language))
                            .font(.subheadline.bold())
                            .strikethrough(checked)
                    }
                    Text(drink.baseSpirits.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            VerificationBadge(label: drink.verificationLabel)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
