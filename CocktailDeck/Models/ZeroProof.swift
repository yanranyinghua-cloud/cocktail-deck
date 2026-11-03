import Foundation

// 无酒精版：含酒精材料按 1:1 等量替换为无酒精风味液体/果汁/草本茶，
// 杯型与装饰不变，逐项列出对照与口感差异。替换表只收有把握的通用项；
// 匹配不上的含酒精材料用“同量无酒精风味饮料”兜底并如实标注，不编造品牌。
struct ZeroProofSubstitution {
    let original: String
    let replacement: String
    let note: String
}

struct ZeroProofVersion {
    let ingredients: [Ingredient]
    let substitutions: [ZeroProofSubstitution]
    let tasteNotes: [String]

    var hasSubstitutions: Bool { !substitutions.isEmpty }
}

enum ZeroProof {
    /// 配料名里的含酒精关键词（中英文都查，因为合并数据里混有 Campari、Aperol 等原文名）。
    private static let alcoholKeywords: [String] = [
        "朗姆", "金酒", "伏特加", "威士忌", "波本", "黑麦",
        "白兰地", "干邑", "龙舌兰", "梅斯卡尔", "利口酒",
        "苦艾酒", "味美思", "香槟", "葡萄酒", "起泡酒",
        "啤酒", "白酒", "清酒", "烧酒", "苦精",
        "campari", "aperol", "amaro", "chartreuse", "夏翠丝",
        "maraschino", "triple sec", "vermouth", "whisky", "whiskey",
        "gin", "rum", "vodka", "tequila", "mezcal", "brandy", "cognac",
    ]

    /// 关键词 →（替代品，口感差异）。按关键词在配料名中出现的先后取最具体的匹配：
    /// 先查长关键词与品类词，再 fallback 通用兜底。
    private static let replacements: [(keyword: String, replacement: String, note: String)] = [
        ("香槟", "无酒精起泡白葡萄汁", "气泡还在，少酒香"),
        ("起泡酒", "无酒精起泡白葡萄汁", "气泡还在，少酒香"),
        ("白葡萄酒", "无酒精葡萄酒", "果香在，酒体薄"),
        ("葡萄酒", "无酒精葡萄酒", "果香在，酒体薄"),
        ("朗姆", "甘蔗汁", "甜润在，少灼热"),
        ("金酒", "无酒精金酒或杜松子风味草本茶", "草本香在，少烈度"),
        ("伏特加", "苏打水", "仅补体积，风味大减"),
        ("威士忌", "无酒精威士忌风味饮料", "烟熏木香弱"),
        ("波本", "无酒精威士忌风味饮料", "烟熏木香弱"),
        ("黑麦", "无酒精威士忌风味饮料", "烟熏木香弱"),
        ("白兰地", "葡萄汁＋红茶", "果香在，少醇厚"),
        ("干邑", "葡萄汁＋红茶", "果香在，少醇厚"),
        ("龙舌兰", "龙舌兰糖浆＋青柠", "甜润在，少烈性"),
        ("梅斯卡尔", "烟熏草本茶", "烟熏在，弱一些"),
        ("橙味利口酒", "橙汁＋橙皮", "橙香在，少酒劲"),
        ("咖啡利口酒", "冷萃咖啡", "咖啡香在，少甜润"),
        ("campari", "无酒精苦味开胃饮料", "苦甜在，少酒劲"),
        ("aperol", "无酒精橙味开胃饮料", "橙香苦甜在，少酒劲"),
        ("amaro", "草本苦味茶", "草本苦味在，弱一些"),
        ("夏翠丝", "草本苦味茶", "草本香在，弱一些"),
        ("chartreuse", "草本苦味茶", "草本香在，弱一些"),
        ("maraschino", "樱桃汁", "樱桃香在，少醇厚"),
        ("味美思", "无酒精味美思或草本加味茶", "草本香在，弱一些"),
        ("vermouth", "无酒精味美思或草本加味茶", "草本香在，弱一些"),
        ("苦艾酒", "草本苦味茶", "草本香在，弱一些"),
        ("苦精", "草本苦味茶", "用量极少，风味近似"),
        ("白酒", "无酒精米香风味饮料", "糟香弱"),
        ("啤酒", "无酒精啤酒", "风味接近，少酒劲"),
        ("利口酒", "同风味无酒精利口酒", "甜度和香气接近，少酒劲"),
        ("清酒", "无酒精米香风味饮料", "米香在，弱一些"),
        ("烧酒", "无酒精米香风味饮料", "米香在，弱一些"),
    ]

    static func makeVersion(for drink: Drink) -> ZeroProofVersion {
        guard let ingredients = drink.ingredients else {
            // 无配料的卡（如 Guru 名片卡）没有可替换项，无酒精版即原样。
            return ZeroProofVersion(ingredients: [], substitutions: [], tasteNotes: [])
        }
        var swapped: [Ingredient] = []
        var subs: [ZeroProofSubstitution] = []
        for item in ingredients {
            let lower = item.name.lowercased()
            let isAlcoholic = alcoholKeywords.contains { lower.contains($0.lowercased()) }
            guard isAlcoholic else {
                swapped.append(item)
                continue
            }
            if let match = replacements.first(where: { lower.contains($0.keyword.lowercased()) }) {
                swapped.append(Ingredient(name: match.replacement, amount: item.amount, note: item.note, optional: item.optional))
                subs.append(ZeroProofSubstitution(original: item.name, replacement: match.replacement, note: match.note))
            } else {
                swapped.append(Ingredient(name: "同量无酒精风味饮料", amount: item.amount, note: item.note, optional: item.optional))
                subs.append(ZeroProofSubstitution(original: item.name, replacement: "同量无酒精风味饮料", note: "通用替代，风味仅供参考"))
            }
        }
        let tasteNotes = subs.isEmpty ? [] : [
            "少了酒精的灼热与酒劲",
            "甜感会更明显",
            "酒体略薄，可加冰或减糖调整",
        ]
        return ZeroProofVersion(ingredients: swapped, substitutions: subs, tasteNotes: tasteNotes)
    }
}
