import Foundation

// 与 phase1/drinks.json 一一对应的数据模型。
// JSON 使用 snake_case，加载时用 .convertFromSnakeCase 解码。
// 字段说明：
// - nameZh 为空表示来源未提供中文名，界面直接显示英文名，禁止现编中文名。
// - ingredients 与 amountsText 二选一：来源给结构化用量用前者，
//   来源只给文本用量（如六类）用后者原样展示，不做猜测性拆分。
// - photo 只记录照片清单（manifest）信息；一阶段不联网加载图片，
//   本地图片打包是二阶段任务。

struct DrinksDocument: Decodable {
    let drinks: [Drink]
}

struct Drink: Decodable, Identifiable, Hashable {
    let id: String
    let nameEn: String
    let nameZh: String?
    let aliases: [String]
    let source: String
    let sourceId: String?
    let category: String
    let verification: Verification
    let baseSpirits: [String]
    let mixers: [String]
    let flavors: [String]
    let ingredients: [Ingredient]?
    let amountsText: [String]?
    let method: String
    let methodText: String
    let glass: String
    let garnish: String
    let description: String
    let filterTags: FilterTags?
    let notes: String
    let photo: PhotoRef?
    // 红框警示：仅当 warnText 非空时展示；10 款 warn 为真但 warnText 为空的
    // 酒款按二阶段口径如实留空，不补写文案。带默认值，兼容无此键的旧数据。
    let warn: Bool? = nil
    let warnText: String? = nil

    var displayName: String { nameZh ?? nameEn }
    var verificationLabel: VerificationLabel { VerificationLabel.from(verification.label) }
}

struct Ingredient: Codable, Hashable {
    var name: String
    var amount: String
    var note: String
    var optional: Bool
}

struct Verification: Decodable, Hashable {
    let label: String
    let reason: String
}

struct PhotoRef: Decodable, Hashable {
    let manifestKey: String
    let source: String?
    let remoteUrl: String?
    let page: String?
    let status: String
}

struct FilterTags: Decodable, Hashable {
    let baseSpirits: [String]?
    let mixers: [String]?
    let flavors: [String]?
    let strength: String?
    let difficulty: String?
    let method: String?
    let glass: String?
    let fizz: Bool?
    let caffeine: Bool?
    let egg: Bool?
    let dairy: Bool?
    let hot: Bool?
    let spicy: Bool?
}
