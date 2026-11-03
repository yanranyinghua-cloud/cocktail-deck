import SwiftUI
import UIKit

// 本地实拍照片：只读 Bundle 内 Resources/Photos/<manifestKey>.webp，
// 不联网、不热链。加载失败或无实拍（unresolved / rejected / 无照片）
// 一律回落占位面板，不虚构图片。
// 注意：WebP 解码依赖系统 ImageIO（部署目标 iOS 17，理论上支持），
// 仍需真机验证；若真机解码失败，界面仍显示占位，不崩溃。
struct PhotoImage: View {
    let drink: Drink

    var body: some View {
        if let image = loadImage() {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(4 / 3, contentMode: .fit)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            placeholder
        }
    }

    private func loadImage() -> UIImage? {
        guard let photo = drink.photo,
              photo.status == "cached" || photo.status == "ok" else { return nil }
        guard let url = Bundle.main.url(
            forResource: photo.manifestKey,
            withExtension: "webp",
            subdirectory: "Photos"
        ) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.12))
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                .foregroundStyle(.secondary.opacity(0.4))
            VStack(spacing: 6) {
                Text(String(drink.nameEn.prefix(1)))
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.6))
                Text(photoNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .aspectRatio(4 / 3, contentMode: .fit)
    }

    private var photoNote: String {
        guard let photo = drink.photo else { return "暂无实拍照片" }
        switch photo.status {
        case "unresolved": return "暂无确认实拍"
        case "rejected": return "照片错配，已剔除"
        default: return "照片加载失败"
        }
    }
}
