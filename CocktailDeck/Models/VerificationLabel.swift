import SwiftUI

// 核验标签：直接沿用研究数据的三档定义，界面只做展示，不做二次判定。
// 已核验：来源和配方信息完整。
// 待核验：有配方，但用量或制作方式存在疑点。
// 待完善：只有名称、描述或不完整资料。
enum VerificationLabel: String {
    case verified = "已核验"
    case pending = "待核验"
    case incomplete = "待完善"
    case custom = "我的特调"
    case unknown = "未知"

    static func from(_ raw: String) -> VerificationLabel {
        VerificationLabel(rawValue: raw) ?? .unknown
    }

    var tint: Color {
        switch self {
        case .verified: return .green
        case .pending: return .orange
        case .incomplete: return .gray
        case .custom: return .purple
        case .unknown: return .secondary
        }
    }
}
