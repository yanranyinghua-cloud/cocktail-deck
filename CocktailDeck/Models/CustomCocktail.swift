import Foundation

// 用户自定义特调：只存用户自己填的内容，全部本地持久化（见 AppStore）。
// 展示时通过 asDrink() 转成 Drink，复用卡片/列表/详情全部现有视图；
// 核验徽章用 VerificationLabel.custom（“我的特调”），不是核验结论，
// 只是标明来源是用户自创，避免与已核验/待核验/待完善混淆。
struct CustomCocktail: Codable, Identifiable, Hashable {
    var id: String
    var nameEn: String
    var nameZh: String?
    var intro: String
    var ingredients: [Ingredient]
    var method: String
    var methodText: String
    var glass: String
    var garnish: String
    var baseSpirits: [String]
    var flavors: [String]
    var difficulty: String
    var strength: String
    var tip: String
    var createdAt: Date

    static func empty() -> CustomCocktail {
        CustomCocktail(
            id: UUID().uuidString,
            nameEn: "",
            nameZh: nil,
            intro: "",
            ingredients: [Ingredient(name: "", amount: "", note: "", optional: false)],
            method: "摇和",
            methodText: "",
            glass: "",
            garnish: "",
            baseSpirits: [],
            flavors: [],
            difficulty: "易",
            strength: "中",
            tip: "",
            createdAt: Date()
        )
    }

    /// 有效性：中英文名至少填一个，且至少有一味有效配料。
    var isValid: Bool {
        let hasName = !nameEn.trimmingCharacters(in: .whitespaces).isEmpty
            || !(nameZh ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        let hasIngredient = ingredients.contains {
            !$0.name.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return hasName && hasIngredient
    }

    /// 转展示用 Drink：id 加 custom- 前缀，避免与 1123 款内置 id 碰撞；
    /// 来源写“我的特调”，小窍门进 notes，创建时间不进 Drink（作品集另行展示）。
    func asDrink() -> Drink {
        let cleanIngredients = ingredients.filter {
            !$0.name.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return Drink(
            id: "custom-\(id)",
            nameEn: nameEn,
            nameZh: (nameZh ?? "").isEmpty ? nil : nameZh,
            aliases: [],
            source: "我的特调",
            sourceId: nil,
            category: "custom",
            verification: Verification(label: VerificationLabel.custom.rawValue, reason: ""),
            baseSpirits: baseSpirits,
            mixers: [],
            flavors: flavors,
            ingredients: cleanIngredients.isEmpty ? nil : cleanIngredients,
            amountsText: nil,
            method: method,
            methodText: methodText,
            glass: glass,
            garnish: garnish,
            description: intro,
            filterTags: FilterTags(
                baseSpirits: baseSpirits,
                mixers: nil,
                flavors: flavors,
                strength: strength,
                difficulty: difficulty,
                method: method,
                glass: glass.isEmpty ? nil : glass,
                fizz: nil,
                caffeine: nil,
                egg: nil,
                dairy: nil,
                hot: nil,
                spicy: nil
            ),
            notes: tip,
            photo: nil
        )
    }
}
