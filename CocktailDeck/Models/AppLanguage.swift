import Foundation

// 界面语言：中文 / EN 一键切换，选择本地持久化（见 AppStore）。
// 注意：合并数据里配方字段本身就是中文译文（zh 已 baked 进主字段），
// 因此 EN 模式的英文配方来自独立的 Resources/en.json 对照表（984 款英文原文），
// 基线 143 款没有英文配方，EN 模式下显示中文原文并附说明，不现编英文。
enum AppLanguage: String, Codable, CaseIterable {
    case chinese = "中文"
    case english = "EN"
}

extension Drink {
    /// 按语言取主名：中文模式优先中文名（无中文名时回落英文名，禁止现编）；
    /// EN 模式固定英文名（英文名为空时回落中文名，不显示空白）。
    func name(for language: AppLanguage) -> String {
        switch language {
        case .chinese:
            if let zh = nameZh, !zh.isEmpty { return zh }
            return nameEn
        case .english:
            if !nameEn.isEmpty { return nameEn }
            return nameZh ?? nameEn
        }
    }

    /// EN 模式下的副名：中文模式显示英文名，EN 模式显示中文名（若有且与主名不同）。
    func secondaryName(for language: AppLanguage) -> String? {
        switch language {
        case .chinese:
            guard let zh = nameZh, !zh.isEmpty, zh != nameEn else { return nil }
            return nameEn
        case .english:
            guard let zh = nameZh, !zh.isEmpty, zh != nameEn else { return nil }
            return zh
        }
    }
}
