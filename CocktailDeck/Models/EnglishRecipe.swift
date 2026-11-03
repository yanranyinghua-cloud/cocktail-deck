import Foundation

// EN 模式配方对照：来自一阶段 984 款英文原文（Resources/en.json），
// key 为合并后 id（冒号改连字符）。全部字段可选：缺失即回落合并数据的中文原文。
// 基线 143 款不在对照表里，EN 模式下显示中文原文并附说明。
struct EnglishRecipe: Decodable {
    let ingredients: [Ingredient]?
    let method: String?
    let methodText: String?
    let description: String?
    let glass: String?
    let garnish: String?
}
