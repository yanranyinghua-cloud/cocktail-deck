import Foundation
import SwiftUI

enum DeckViewMode: String, CaseIterable {
    case card = "卡片"
    case list = "列表"
}

@Observable
final class DeckViewModel {
    var drinks: [Drink] = []
    var loadError: String?

    var searchText: String = ""
    var selectedBaseSpirit: String?
    var selectedLabel: VerificationLabel?
    var viewMode: DeckViewMode = .card

    // 三阶段新增：语言、自定义特调、英文配方对照、私人酒单、挑战进度。
    // 全部来自本地持久化（AppStore），牌堆本身只读内置数据，不改 drinks.json。
    var language: AppLanguage = AppStore.loadLanguage()
    var customDrinks: [CustomCocktail] = AppStore.loadCustoms()
    var englishRecipes: [String: EnglishRecipe] = [:]
    var menu: AppStore.MenuData = AppStore.loadMenu()
    var challenge: ChallengeState?

    init() {
        load()
        loadEnglishRecipes()
        challenge = AppStore.loadChallenge()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "drinks", withExtension: "json") else {
            loadError = "未找到 drinks.json，请把 phase1/drinks.json 放入 Resources 后重新编译。"
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let document = try decoder.decode(DrinksDocument.self, from: data)
            drinks = document.drinks
        } catch {
            // 不补占位数据：解析失败就如实报错，界面显示空态。
            loadError = "drinks.json 解析失败：\(error.localizedDescription)"
        }
    }

    private func loadEnglishRecipes() {
        guard let url = Bundle.main.url(forResource: "en", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        englishRecipes = (try? decoder.decode([String: EnglishRecipe].self, from: data)) ?? [:]
    }

    // MARK: - 牌堆（含自定义）

    /// 内置 1123 款＋用户自定义（按保存时间倒序在前？不：牌堆按原顺序，
    /// 自定义追加在末尾；作品集 Tab 才是倒序展示）。
    var allDrinks: [Drink] {
        drinks + customDrinks.map { $0.asDrink() }
    }

    var allBaseSpirits: [String] {
        let spirits = allDrinks.flatMap { $0.baseSpirits }
        return Array(Set(spirits)).sorted()
    }

    func drink(byId id: String) -> Drink? {
        allDrinks.first { $0.id == id }
    }

    func englishRecipe(for drink: Drink) -> EnglishRecipe? {
        englishRecipes[drink.id]
    }

    /// EN 模式下该酒款是否有英文配方（无则显示中文原文＋说明）。
    func hasEnglishRecipe(for drink: Drink) -> Bool {
        englishRecipes[drink.id] != nil
    }

    var filteredDrinks: [Drink] {
        allDrinks.filter { drink in
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let ingredientNames = (drink.ingredients ?? []).map { $0.name }
                let haystack = ([drink.nameEn, drink.nameZh ?? ""] + drink.aliases
                    + drink.baseSpirits + drink.mixers + ingredientNames)
                    .joined(separator: " ").lowercased()
                guard haystack.contains(query) else { return false }
            }
            if let spirit = selectedBaseSpirit {
                guard drink.baseSpirits.contains(spirit) else { return false }
            }
            if let label = selectedLabel {
                guard drink.verificationLabel == label else { return false }
            }
            return true
        }
    }

    var hasActiveFilters: Bool {
        selectedBaseSpirit != nil || selectedLabel != nil || !searchText.isEmpty
    }

    func clearFilters() {
        searchText = ""
        selectedBaseSpirit = nil
        selectedLabel = nil
    }

    // MARK: - 语言

    func setLanguage(_ language: AppLanguage) {
        self.language = language
        AppStore.saveLanguage(language)
    }

    // MARK: - 自定义特调

    func addCustom(_ custom: CustomCocktail) {
        customDrinks.append(custom)
        AppStore.saveCustoms(customDrinks)
    }

    func updateCustom(_ custom: CustomCocktail) {
        if let index = customDrinks.firstIndex(where: { $0.id == custom.id }) {
            customDrinks[index] = custom
            AppStore.saveCustoms(customDrinks)
        }
    }

    func deleteCustom(id: String) {
        customDrinks.removeAll { $0.id == id }
        AppStore.saveCustoms(customDrinks)
        // 同步清出酒单，避免酒单指向已删的特调。
        menu.drinkIds.removeAll { $0 == "custom-\(id)" }
        AppStore.saveMenu(menu)
    }

    // MARK: - 私人酒单

    var menuDrinks: [Drink] {
        menu.drinkIds.compactMap { drink(byId: $0) }
    }

    func isInMenu(_ drink: Drink) -> Bool {
        menu.drinkIds.contains(drink.id)
    }

    func toggleMenu(_ drink: Drink) {
        if let index = menu.drinkIds.firstIndex(of: drink.id) {
            menu.drinkIds.remove(at: index)
        } else {
            menu.drinkIds.append(drink.id)
        }
        AppStore.saveMenu(menu)
    }

    func saveMenuTitle(_ title: String) {
        menu.title = title
        AppStore.saveMenu(menu)
    }

    // MARK: - 挑战

    func saveChallenge() {
        AppStore.saveChallenge(challenge)
    }

    func clearChallenge() {
        challenge = nil
        AppStore.saveChallenge(nil)
    }
}
