import Foundation

// 酒鬼挑战：纯本地玩法，不联网、不计分、不排名。
// 单人经典：随机抽，度数由低到高排；单人硬核：偏中高度数＋偏难；
// 双人接力：每人一档（6/8/10 杯按人算），A/B 轮流发牌。
// 三套牌一次生成（主牌＋两套备选），进度（打勾）随状态一起持久化。
enum ChallengeMode: String, Codable, CaseIterable {
    case classic = "单人经典"
    case hard = "单人硬核"
    case duo = "双人接力"
}

struct ChallengeState: Codable {
    var mode: ChallengeMode
    var tier: Int
    var menus: [[String]]
    var currentIndex: Int
    var checked: Set<String>

    var currentMenu: [String] {
        guard menus.indices.contains(currentIndex) else { return [] }
        return menus[currentIndex]
    }

    var checkedCount: Int {
        currentMenu.filter { checked.contains($0) }.count
    }

    var isComplete: Bool {
        !currentMenu.isEmpty && checkedCount == currentMenu.count
    }

    /// 双人接力：偶数位归 A，奇数位归 B。
    func duoCounts() -> (aChecked: Int, aTotal: Int, bChecked: Int, bTotal: Int) {
        var aChecked = 0, aTotal = 0, bChecked = 0, bTotal = 0
        for (index, id) in currentMenu.enumerated() {
            if index % 2 == 0 {
                aTotal += 1
                if checked.contains(id) { aChecked += 1 }
            } else {
                bTotal += 1
                if checked.contains(id) { bChecked += 1 }
            }
        }
        return (aChecked, aTotal, bChecked, bTotal)
    }
}

enum ChallengeGenerator {
    static func strengthRank(_ strength: String?) -> Int {
        switch strength {
        case "无酒精": return -1
        case "低": return 0
        case "中": return 1
        case "中高": return 2
        case "高": return 3
        default: return 4
        }
    }

    static func difficultyRank(_ difficulty: String?) -> Int {
        switch difficulty {
        case "易": return 0
        case "中": return 1
        case "难": return 2
        default: return 1
        }
    }

    /// 生成三套牌：主牌＋两套备选（备选尽量避开主牌的酒款）。
    static func generate(drinks: [Drink], mode: ChallengeMode, tier: Int) -> [[String]] {
        let count = mode == .duo ? tier * 2 : tier
        func pick(from pool: [Drink], excluding used: Set<String>) -> [String] {
            let available = pool.filter { !used.contains($0.id) }
            let source = available.isEmpty ? pool : available
            switch mode {
            case .hard:
                return source
                    .sorted {
                        let a = strengthRank($0.filterTags?.strength) * 2 + difficultyRank($0.filterTags?.difficulty)
                        let b = strengthRank($1.filterTags?.strength) * 2 + difficultyRank($1.filterTags?.difficulty)
                        if a != b { return a > b }
                        return $0.id < $1.id
                    }
                    .prefix(max(count * 3, count))
                    .shuffled()
                    .prefix(count)
                    .map { $0.id }
            case .duo:
                return source.shuffled().prefix(count).map { $0.id }
            case .classic:
                return []
            }
        }
        // 经典模式单独处理：先抽再按度数由低到高排。
        if mode == .classic {
            let pool = drinks
            let main = pool.shuffled().prefix(count).map { $0.id }
            let mainSorted = main.sorted { strengthRank(drinkStrength($0, in: drinks)) < strengthRank(drinkStrength($1, in: drinks)) }
            var used = Set(main)
            var menus = [mainSorted]
            for _ in 0..<2 {
                let alt = pool.filter { !used.contains($0.id) }.shuffled().prefix(count).map { $0.id }
                let altSorted = alt.sorted { strengthRank(drinkStrength($0, in: drinks)) < strengthRank(drinkStrength($1, in: drinks)) }
                menus.append(altSorted)
                used.formUnion(alt)
            }
            return menus
        }
        let main = pick(from: drinks, excluding: [])
        var used = Set(main)
        var menus = [main]
        for _ in 0..<2 {
            let alt = pick(from: drinks, excluding: used)
            menus.append(alt)
            used.formUnion(alt)
        }
        return menus
    }

    private static func drinkStrength(_ id: String, in drinks: [Drink]) -> String? {
        drinks.first { $0.id == id }?.filterTags?.strength
    }
}
