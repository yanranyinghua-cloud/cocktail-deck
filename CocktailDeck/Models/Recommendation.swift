import Foundation

// 推荐引擎：纯函数，不碰网络与用户数据，只算分排序。
// 口径说明：
// - 今日推荐用日期做种子，当天固定、全天同一款，午夜更换；
// - 按聚会用风味/酒精度/气泡/难度加权打分，三组（场景×人数×氛围）叠加取前 6，
//   人数不参与打分，6 人以上只出放大用量的提示，不编造具体倍数；
// - 按手头材料按“缺几样”分三档，缺 1–2 样且都有替代才进“替代后能做”。

// MARK: - 确定性随机（日期种子）

struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func nextInt(_ upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }

    /// 确定性洗牌：同一种子同一顺序。
    mutating func shuffled<T>(_ array: [T]) -> [T] {
        var result = array
        guard result.count > 1 else { return result }
        for i in stride(from: result.count - 1, through: 1, by: -1) {
            result.swapAt(i, nextInt(i + 1))
        }
        return result
    }
}

// MARK: - 今日推荐

enum Recommendation {
    /// 当天 3 款：主推＋2 个备选。offset 每点一次“换一杯”加 1，顺序跟着走。
    static func dailyPicks(drinks: [Drink], date: Date, offset: Int) -> [Drink] {
        guard !drinks.isEmpty else { return [] }
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let seed = UInt64((parts.year ?? 2026) * 372 + (parts.month ?? 1) * 31 + (parts.day ?? 1))
            &* 2654435761 &+ UInt64(max(0, offset)) &* 40503
        var rng = SeededRNG(seed: seed)
        let order = rng.shuffled(drinks)
        return [order[0], order[1 % order.count], order[2 % order.count]]
    }

    // MARK: - 按聚会

    enum PartyScene: String, CaseIterable {
        case gathering = "朋友小聚"
        case birthday = "生日派对"
        case date = "约会氛围"
        case nightcap = "餐后小酌"
        case barbecue = "烧烤夜宵"
        case solo = "独酌放松"
        case beginner = "新手友好"
    }

    enum PeopleTier: String, CaseIterable {
        case oneTwo = "1–2人"
        case threeFive = "3–5人"
        case sixTen = "6–10人"
        case overTen = "10人以上"
    }

    enum PartyMood: String, CaseIterable {
        case lively = "热闹嗨场"
        case cozy = "温馨松弛"
        case romantic = "微醺浪漫"
        case light = "清爽轻负担"
    }

    /// 场景风味亲和：风味名 → 加分。
    private static let sceneFlavors: [PartyScene: [(String, Int)]] = [
        .gathering: [("清爽", 2), ("果香", 2), ("酸甜", 1)],
        .birthday: [("果香", 3), ("热带", 2), ("甜润", 1)],
        .date: [("甜润", 2), ("花香", 2), ("奶香", 1)],
        .nightcap: [("浓烈", 2), ("咖啡", 2), ("苦甜", 2), ("草本", 1)],
        .barbecue: [("清爽", 2), ("辛辣", 2), ("酸甜", 1), ("果香", 1)],
        .solo: [("浓烈", 3), ("烟熏", 2), ("草本", 1)],
        .beginner: [("清爽", 1)],
    ]

    /// 氛围修正：风味、酒精度、气泡加分。
    private static let moodFlavors: [PartyMood: [(String, Int)]] = [
        .lively: [("果香", 1)],
        .cozy: [("甜润", 2), ("奶香", 1)],
        .romantic: [("花香", 2), ("甜润", 1)],
        .light: [("清爽", 3)],
    ]

    struct PartyHit {
        let drink: Drink
        let score: Int
        let reasons: [String]
    }

    static func partyTop(
        drinks: [Drink],
        scene: PartyScene,
        mood: PartyMood
    ) -> [PartyHit] {
        let scored: [PartyHit] = drinks.map { drink in
            var score = 0
            var reasons: [String] = []
            for (flavor, points) in sceneFlavors[scene] ?? [] where drink.flavors.contains(flavor) {
                score += points
                reasons.append(flavor)
            }
            for (flavor, points) in moodFlavors[mood] ?? [] where drink.flavors.contains(flavor) {
                score += points
                if !reasons.contains(flavor) { reasons.append(flavor) }
            }
            let strength = drink.filterTags?.strength ?? ""
            switch scene {
            case .birthday where drink.filterTags?.fizz == true:
                score += 2; reasons.append("含气泡")
            case .date where strength == "低":
                score += 2; reasons.append("低酒精度")
            case .beginner where drink.filterTags?.difficulty == "易":
                score += 3; reasons.append("难度易")
            case .beginner where strength == "低":
                score += 2; reasons.append("低酒精度")
            default:
                break
            }
            switch mood {
            case .lively where drink.filterTags?.fizz == true:
                score += 2; if !reasons.contains("含气泡") { reasons.append("含气泡") }
            case .lively where strength == "高":
                score += 1; reasons.append("高酒精度")
            case .cozy where strength == "低":
                score += 1; reasons.append("低酒精度")
            case .romantic where strength == "低":
                score += 2; reasons.append("低酒精度")
            case .light where strength == "低" || strength == "无酒精":
                score += 2; reasons.append("低酒精度")
            default:
                break
            }
            return PartyHit(drink: drink, score: score, reasons: Array(reasons.prefix(3)))
        }
        return scored
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                return $0.drink.id < $1.drink.id
            }
            .prefix(6)
            .map { $0 }
    }

    // MARK: - 按手头材料

    enum MaterialTier: String {
        case ready = "能直接做"
        case substitutable = "替代后能做"
        case missing = "还差几样"
    }

    struct MissingItem {
        let name: String
        let substitute: String?
        let tasteNote: String?
    }

    struct MaterialHit {
        let drink: Drink
        let tier: MaterialTier
        let missing: [MissingItem]
    }

    /// 常备品：不计入缺失。
    private static let pantryStaples: Set<String> = ["水", "盐", "冰", "碎冰", "方糖", "白砂糖", "糖"]

    /// “多基酒”“利口酒为主”是分类标记，不是可采购的单品，不直接计入缺失；
    /// 这类酒款的主基酒从配料名里的烈酒关键词推导，推导不出时才把标记本身计为缺失。
    private static let flagBases: Set<String> = ["多基酒", "利口酒为主"]

    /// 配料名里的烈酒关键词 → 基酒分类。
    private static let spiritKeywords: [(keyword: String, base: String)] = [
        ("波本", "威士忌"), ("黑麦", "威士忌"), ("威士忌", "威士忌"), ("whisky", "威士忌"), ("whiskey", "威士忌"),
        ("金酒", "金酒"), ("gin", "金酒"),
        ("伏特加", "伏特加"), ("vodka", "伏特加"),
        ("朗姆", "朗姆"), ("rum", "朗姆"),
        ("龙舌兰", "龙舌兰"), ("tequila", "龙舌兰"),
        ("梅斯卡尔", "梅斯卡尔"), ("mezcal", "梅斯卡尔"),
        ("白兰地", "白兰地"), ("干邑", "干邑 / 白兰地"), ("cognac", "干邑 / 白兰地"),
        ("白酒", "白酒"),
        ("雪莉", "雪莉"), ("sherry", "雪莉"),
        ("campari", "利口酒"), ("aperol", "利口酒"), ("amaro", "利口酒"),
        ("味美思", "味美思"), ("vermouth", "味美思"),
    ]

    /// 英文辅料同义词 → 中文规范名（尽力匹配；匹配不上的生僻辅料如实计为缺失）。
    private static let mixerSynonyms: [String: String] = [
        "egg": "蛋", "egg white": "蛋清", "egg yolk": "蛋黄",
        "lemon juice": "柠檬汁", "lime juice": "青柠汁", "orange juice": "橙汁",
        "pineapple juice": "菠萝汁", "grapefruit juice": "西柚汁", "cranberry juice": "蔓越莓汁",
        "tomato juice": "番茄汁", "apple juice": "苹果汁", "lemonade": "柠檬水",
        "soda water": "苏打水", "soda": "苏打水", "tonic water": "汤力水", "tonic": "汤力水",
        "cola": "可乐", "ginger beer": "姜汁啤酒", "ginger ale": "姜汁汽水",
        "cream": "奶油", "half-and-half": "奶油", "milk": "牛奶",
        "coffee": "咖啡", "honey": "蜂蜜", "syrup": "糖浆", "simple syrup": "糖浆",
        "grenadine": "石榴糖浆", "bitters": "苦精", "vermouth": "味美思",
        "triple sec": "橙味利口酒", "sugar": "糖", "salt": "盐", "ice": "冰",
        "mint": "薄荷", "cucumber": "黄瓜", "ginger": "姜",
    ]

    /// 常见替代：只收有把握的条目；没有替代的缺失项不进“替代后能做”。
    static let substitutions: [String: (substitute: String, note: String)] = [
        "青柠汁": ("柠檬汁", "酸度相近，少一分青柠香"),
        "柠檬汁": ("青柠汁", "酸度相近，多一分青柠香"),
        "姜汁啤酒": ("姜汁汽水", "姜味淡一些、更甜"),
        "姜汁汽水": ("姜汁啤酒＋少许糖浆", "姜味浓一些"),
        "糖浆": ("蜂蜜水（蜂蜜＋温水 1:1）", "带一点花香"),
        "蜂蜜": ("糖浆", "少花香"),
        "蛋": ("鹰嘴豆水", "打发相近，无蛋腥"),
        "蛋清": ("鹰嘴豆水", "打发相近，无蛋腥"),
        "蛋白": ("鹰嘴豆水", "打发相近，无蛋腥"),
        "苏打水": ("汤力水", "带苦味，需减糖"),
        "汤力水": ("苏打水", "少苦味和奎宁香"),
        "蔓越莓汁": ("石榴汁", "颜色相近，更涩"),
        "菠萝汁": ("橙汁＋少许柠檬汁", "热带感弱一些"),
        "橙汁": ("菠萝汁", "更甜更浓"),
        "金酒": ("无酒精金酒或杜松子风味草本茶", "草本香在，少烈度"),
        "朗姆": ("甘蔗汁", "甜润在，少灼热"),
        "伏特加": ("苏打水", "仅补体积，风味大减"),
        "威士忌": ("无酒精威士忌风味饮料", "烟熏木香弱"),
        "白兰地": ("葡萄汁＋红茶", "果香在，少醇厚"),
        "龙舌兰": ("龙舌兰糖浆＋青柠", "甜润在，少烈性"),
        "梅斯卡尔": ("烟熏草本茶", "烟熏在，弱一些"),
        "白酒": ("无酒精米香风味饮料", "糟香弱"),
        "利口酒": ("同风味无酒精利口酒", "甜度和香气接近，少酒劲"),
        "味美思": ("无酒精味美思或草本加味茶", "草本香在，弱一些"),
        "苦精": ("草本苦味茶", "用量极少，风味近似"),
        "香槟": ("无酒精起泡白葡萄汁", "气泡还在，少酒香"),
        "起泡酒": ("无酒精起泡白葡萄汁", "气泡还在，少酒香"),
        "葡萄酒": ("无酒精葡萄酒", "果香在，酒体薄"),
        "啤酒": ("无酒精啤酒", "风味接近，少酒劲"),
        "奶油": ("牛奶＋少许黄油", "醇厚感弱一些"),
        "牛奶": ("淡奶油兑水", "更醇厚"),
    ]

    /// 归一化：小写去空格；“A / B”类复合分类拆成两部分，任一部分对上即算有。
    /// 注意数据里斜杠有半角 / 与全角 ／ 两种写法，都拆。
    static func normalizedParts(_ raw: String) -> [String] {
        raw.replacingOccurrences(of: "／", with: "/")
            .split(separator: "/").map {
                $0.trimmingCharacters(in: .whitespaces).lowercased()
            }.filter { !$0.isEmpty }
    }

    private static func canonicalMixer(_ raw: String) -> String {
        let key = raw.trimmingCharacters(in: .whitespaces).lowercased()
        return mixerSynonyms[key] ?? raw.trimmingCharacters(in: .whitespaces)
    }

    static func missingItems(
        for drink: Drink,
        checkedBases: Set<String>,
        checkedMixers: Set<String>
    ) -> [MissingItem] {
        var missing: [MissingItem] = []
        let checkedBaseParts = Set(checkedBases.flatMap { normalizedParts($0) })
        let checkedMixerParts = Set(checkedMixers.flatMap { normalizedParts($0) })

        for base in drink.baseSpirits {
            if flagBases.contains(base) {
                // 从配料名推导主基酒。
                let derived = spiritKeywords.compactMap { entry -> String? in
                    let hit = (drink.ingredients ?? []).contains {
                        $0.name.lowercased().contains(entry.keyword.lowercased())
                    }
                    return hit ? entry.base : nil
                }
                if derived.isEmpty {
                    missing.append(MissingItem(name: base, substitute: nil, tasteNote: nil))
                } else {
                    for need in Set(derived) where !checkedBaseParts.contains(need.lowercased()) {
                        let sub = substitutions[need]
                        missing.append(MissingItem(name: need, substitute: sub?.substitute, tasteNote: sub?.note))
                    }
                }
                continue
            }
            let parts = normalizedParts(base)
            let satisfied = parts.contains { checkedBaseParts.contains($0) }
            if !satisfied {
                let sub = substitutions[base]
                missing.append(MissingItem(name: base, substitute: sub?.substitute, tasteNote: sub?.note))
            }
        }

        for mixer in drink.mixers {
            let canonical = canonicalMixer(mixer)
            if pantryStaples.contains(canonical) { continue }
            let parts = normalizedParts(canonical)
            let satisfied = parts.contains { checkedMixerParts.contains($0) }
                || checkedMixerParts.contains(canonical.lowercased())
            if !satisfied {
                let sub = substitutions[canonical] ?? substitutions[mixer]
                missing.append(MissingItem(name: canonical, substitute: sub?.substitute, tasteNote: sub?.note))
            }
        }

        // 去重（同名缺失只留一条）。
        var seen: Set<String> = []
        return missing.filter { seen.insert($0.name).inserted }
    }

    static func materialsMatch(
        drinks: [Drink],
        checkedBases: Set<String>,
        checkedMixers: Set<String>
    ) -> [MaterialHit] {
        drinks.map { drink in
            let missing = missingItems(for: drink, checkedBases: checkedBases, checkedMixers: checkedMixers)
            let tier: MaterialTier
            if missing.isEmpty {
                tier = .ready
            } else if missing.count <= 2 && missing.allSatisfy({ $0.substitute != nil }) {
                tier = .substitutable
            } else {
                tier = .missing
            }
            return MaterialHit(drink: drink, tier: tier, missing: missing)
        }.sorted {
            let order: [MaterialTier: Int] = [.ready: 0, .substitutable: 1, .missing: 2]
            if order[$0.tier] != order[$1.tier] { return order[$0.tier]! < order[$1.tier]! }
            if $0.missing.count != $1.missing.count { return $0.missing.count < $1.missing.count }
            return $0.drink.id < $1.drink.id
        }
    }
}
