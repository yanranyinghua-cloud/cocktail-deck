import SwiftUI

// 主界面：5 个 Tab——牌堆 / 推荐 / 酒单 / 作品集 / 挑战，各 Tab 自带导航栈。
// 语言切换（中文 / EN）放在每个 Tab 的工具栏，一键切换、选择本地记住；
// 牌堆保留原有搜索筛选、卡片/列表双视图、点图翻面、详情弹窗与底部适量饮酒提示。
struct ContentView: View {
    @State private var viewModel = DeckViewModel()
    @State private var detailDrink: Drink?
    @State private var showCustomForm = false

    var body: some View {
        TabView {
            deckTab
                .tabItem { Label("牌堆", systemImage: "square.stack") }
            NavigationStack {
                RecommendView(viewModel: viewModel, onDetail: { detailDrink = $0 })
                    .navigationTitle("推荐")
                    .toolbar { languagePicker }
            }
            .tabItem { Label("推荐", systemImage: "sparkles") }
            NavigationStack {
                MenuView(viewModel: viewModel, onDetail: { detailDrink = $0 })
                    .navigationTitle("私人酒单")
                    .toolbar { languagePicker }
            }
            .tabItem { Label("酒单", systemImage: "wineglass") }
            NavigationStack {
                CollectionView(viewModel: viewModel, onDetail: { detailDrink = $0 })
                    .navigationTitle("我的作品集")
                    .toolbar {
                        languagePicker
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showCustomForm = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
            }
            .tabItem { Label("作品集", systemImage: "star") }
            NavigationStack {
                ChallengeView(viewModel: viewModel, onDetail: { detailDrink = $0 })
                    .navigationTitle("酒鬼挑战")
                    .toolbar { languagePicker }
            }
            .tabItem { Label("挑战", systemImage: "party.popper") }
        }
        .sheet(item: $detailDrink) { drink in
            DrinkDetailView(
                drink: drink,
                language: viewModel.language,
                englishRecipe: viewModel.englishRecipe(for: drink),
                isInMenu: viewModel.isInMenu(drink),
                onToggleMenu: { viewModel.toggleMenu(drink) }
            )
        }
        .sheet(isPresented: $showCustomForm) {
            CustomFormView(viewModel: viewModel)
        }
    }

    private var languagePicker: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Picker("语言", selection: Binding(
                get: { viewModel.language },
                set: { viewModel.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(language.rawValue).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 110)
        }
    }

    private var deckTab: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchFilterBar(viewModel: viewModel)

                if let error = viewModel.loadError {
                    ContentUnavailableView(
                        "数据未就绪",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if viewModel.filteredDrinks.isEmpty {
                    ContentUnavailableView(
                        "没有匹配的酒款",
                        systemImage: "magnifyingglass",
                        description: Text("换个关键词，或清除筛选条件再试。")
                    )
                } else {
                    switch viewModel.viewMode {
                    case .card:
                        cardPager
                    case .list:
                        DrinkListView(
                            drinks: viewModel.filteredDrinks,
                            language: viewModel.language,
                            englishRecipes: viewModel.englishRecipes,
                            menuIds: Set(viewModel.menu.drinkIds),
                            onToggleMenu: { viewModel.toggleMenu($0) }
                        )
                    }
                }

                // 适量饮酒提示：上架后必须保留，见 PHASE_PLAN.md 约束清单。
                Text("适量饮酒，开心最重要")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
            .navigationTitle("调酒卡片")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("视图", selection: $viewModel.viewMode) {
                        ForEach(DeckViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                languagePicker
            }
        }
    }

    private var cardPager: some View {
        TabView {
            ForEach(viewModel.filteredDrinks) { drink in
                DrinkCardView(
                    drink: drink,
                    language: viewModel.language,
                    isInMenu: viewModel.isInMenu(drink),
                    onDetail: { detailDrink = drink },
                    onToggleMenu: { viewModel.toggleMenu(drink) }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }
}
