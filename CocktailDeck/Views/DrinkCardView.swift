import SwiftUI

// 卡片：正面为实拍照片（Bundle 内 Photos/*.webp，失败回落占位），
// 背面为手绘插画区——工作区无手绘资源，背面继续用占位面板并如实标注，
// 不加载远程图片（不热链），不虚构图片。点图片翻面。
struct DrinkCardView: View {
    let drink: Drink
    let language: AppLanguage
    let isInMenu: Bool
    let onDetail: () -> Void
    let onToggleMenu: () -> Void

    init(
        drink: Drink,
        language: AppLanguage = .chinese,
        isInMenu: Bool = false,
        onDetail: @escaping () -> Void,
        onToggleMenu: @escaping () -> Void = {}
    ) {
        self.drink = drink
        self.language = language
        self.isInMenu = isInMenu
        self.onDetail = onDetail
        self.onToggleMenu = onToggleMenu
    }

    @State private var flipped = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                // 正面：实拍
                PhotoImage(drink: drink)
                    .opacity(flipped ? 0 : 1)
                // 背面：手绘（无资源，占位）
                handDrawnPlaceholder
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .opacity(flipped ? 1 : 0)
            }
            .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    flipped.toggle()
                }
            }

            Text(drink.name(for: language))
                .font(.title3.bold())
            if let secondary = drink.secondaryName(for: language) {
                Text(secondary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("\(drink.baseSpirits.joined(separator: " · "))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                VerificationBadge(label: drink.verificationLabel)
                if let strength = drink.filterTags?.strength {
                    Text(strength).font(.caption)
                }
                if let difficulty = drink.filterTags?.difficulty {
                    Text("难度\(difficulty)").font(.caption)
                }
                Spacer()
                Button(isInMenu ? "已在酒单" : "加入酒单", action: onToggleMenu)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("详情", action: onDetail)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            Text("点图片翻面查看另一面")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 4)
    }

    private var handDrawnPlaceholder: some View {
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
                Text("手绘插画 · 暂无资源")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .aspectRatio(4 / 3, contentMode: .fit)
    }
}

struct VerificationBadge: View {
    let label: VerificationLabel

    var body: some View {
        Text(label.rawValue)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(label.tint.opacity(0.15))
            .foregroundStyle(label.tint)
            .clipShape(Capsule())
    }
}
