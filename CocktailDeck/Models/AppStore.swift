import Foundation

// 本地持久化：只用 UserDefaults＋JSONEncoder，不用 SwiftData。
// 键名固定四个：自定义特调 / 私人酒单 / 挑战进度 / 语言选择。
// 保存失败静默（读不到就回落默认值），绝不因为持久化失败而崩溃或丢牌堆。
enum AppStore {
    private static let customsKey = "cocktaildeck.customs.v1"
    private static let menuKey = "cocktaildeck.menu.v1"
    private static let challengeKey = "cocktaildeck.challenge.v1"
    private static let languageKey = "cocktaildeck.language.v1"

    struct MenuData: Codable {
        var title: String
        var drinkIds: [String]
    }

    // MARK: - 自定义特调

    static func loadCustoms() -> [CustomCocktail] {
        guard let data = UserDefaults.standard.data(forKey: customsKey) else { return [] }
        return (try? JSONDecoder().decode([CustomCocktail].self, from: data)) ?? []
    }

    static func saveCustoms(_ customs: [CustomCocktail]) {
        guard let data = try? JSONEncoder().encode(customs) else { return }
        UserDefaults.standard.set(data, forKey: customsKey)
    }

    // MARK: - 私人酒单

    static func loadMenu() -> MenuData {
        guard let data = UserDefaults.standard.data(forKey: menuKey),
              let decoded = try? JSONDecoder().decode(MenuData.self, from: data) else {
            return MenuData(title: "我的私人酒单", drinkIds: [])
        }
        return decoded
    }

    static func saveMenu(_ menu: MenuData) {
        guard let data = try? JSONEncoder().encode(menu) else { return }
        UserDefaults.standard.set(data, forKey: menuKey)
    }

    // MARK: - 挑战进度

    static func loadChallenge() -> ChallengeState? {
        guard let data = UserDefaults.standard.data(forKey: challengeKey) else { return nil }
        return try? JSONDecoder().decode(ChallengeState.self, from: data)
    }

    static func saveChallenge(_ state: ChallengeState?) {
        guard let state else {
            UserDefaults.standard.removeObject(forKey: challengeKey)
            return
        }
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: challengeKey)
    }

    // MARK: - 语言选择

    static func loadLanguage() -> AppLanguage {
        guard let raw = UserDefaults.standard.string(forKey: languageKey),
              let language = AppLanguage(rawValue: raw) else {
            return .chinese
        }
        return language
    }

    static func saveLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
    }
}
