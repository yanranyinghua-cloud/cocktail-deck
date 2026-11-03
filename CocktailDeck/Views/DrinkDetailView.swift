import SwiftUI

// 详情页：卡片点“详情”弹出。配方、做法、杯型、装饰、来源、核验说明全部
// 原样展示；核验标签不是已核验时，label_reason 放在醒目提示框里。
// 三阶段新增：语言（EN 模式用 en.json 英文配方对照，无对照时显示中文原文＋说明）、
// 经典/无酒精双版本切换（无酒精版按 1:1 替换含酒精材料并逐项列对照与口感差异）、
// 红框警示（仅 warnText 非空时显示；10 款 warn 为真但文案缺失的如实留空）、
// 加入酒单按钮。新参数全部给默认值，旧调用点仍能编译。
struct DrinkDetailView: View {
    let drink: Drink
    let language: AppLanguage
    let englishRecipe: EnglishRecipe?
    let isInMenu: Bool
    let onToggleMenu: () -> Void

    init(
        drink: Drink,
        language: AppLanguage = .chinese,
        englishRecipe: EnglishRecipe? = nil,
        isInMenu: Bool = false,
        onToggleMenu: @escaping () -> Void = {}
    ) {
        self.drink = drink
        self.language = language
        self.englishRecipe = englishRecipe
        self.isInMenu = isInMenu
        self.onToggleMenu = onToggleMenu
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                DrinkDetailBody(
                    drink: drink,
                    language: language,
                    englishRecipe: englishRecipe,
                    isInMenu: isInMenu,
                    onToggleMenu: onToggleMenu
                )
                .padding(16)
            }
            .navigationTitle(drink.name(for: language))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DrinkDetailBody: View {
    let drink: Drink
    let language: AppLanguage
    let englishRecipe: EnglishRecipe?
    let isInMenu: Bool
    let onToggleMenu: () -> Void

    init(
        drink: Drink,
        language: AppLanguage = .chinese,
        englishRecipe: EnglishRecipe? = nil,
        isInMenu: Bool = false,
        onToggleMenu: @escaping () -> Void = {}
    ) {
        self.drink = drink
        self.language = language
        self.englishRecipe = englishRecipe
        self.isInMenu = isInMenu
        self.onToggleMenu = onToggleMenu
    }

    @State private var zeroProof = false

    /// 是否自定义特调：自定义内容是用户自己的文字，不适用“暂无英文配方”说明。
    private var isCustom: Bool { drink.id.hasPrefix("custom-") }

    /// EN 模式下是否有英文配方对照（中文模式不查对照）。
    private var showsEnglishNote: Bool {
        language == .english && englishRecipe == nil && !isCustom
    }

    private var zeroProofVersion: ZeroProofVersion {
        ZeroProof.makeVersion(for: drink)
    }

    // EN 模式：配方字段逐项用对照表覆盖，单项缺失回落中文原文。
    private var resolvedIngredients: [Ingredient]? {
        if language == .english, let recipe = englishRecipe, let items = recipe.ingredients {
            return items
        }
        return drink.ingredients
    }

    private var resolvedDescription: String {
        if language == .english, let text = englishRecipe?.description { return text }
        return drink.description
    }

    private var resolvedMethod: String {
        if language == .english, let text = englishRecipe?.method { return text }
        return drink.method
    }

    private var resolvedMethodText: String {
        if language == .english, let text = englishRecipe?.methodText { return text }
        return drink.methodText
    }

    private var resolvedGlass: String {
        if language == .english, let text = englishRecipe?.glass { return text }
        return drink.glass
    }

    private var resolvedGarnish: String {
        if language == .english, let text = englishRecipe?.garnish { return text }
        return drink.garnish
    }

    /// 展示用配料：无酒精版打开时用替换后配料，否则用语言解析后配料。
    private var displayedIngredients: [Ingredient]? {
        zeroProof ? zeroProofVersion.ingredients : resolvedIngredients
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                VerificationBadge(label: drink.verificationLabel)
                if !drink.aliases.isEmpty {
                    Text("又名 " + drink.aliases.joined(separator: " / "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(isInMenu ? "已在酒单" : "加入酒单", action: onToggleMenu)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            if showsEnglishNote {
                Label("本款暂无英文配方，以下显示中文原文。", systemImage: "info.circle")
                    .font(.caption)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if !drink.verification.reason.isEmpty {
                Label(drink.verification.reason, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // 红框警示：仅 warnText 非空时显示；warn 为真但文案缺失的 10 款如实留空。
            if let warnText = drink.warnText, !warnText.isEmpty {
                Text(warnText)
                    .font(.caption)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                            .foregroundStyle(.red.opacity(0.6))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if !resolvedDescription.isEmpty {
                Text(resolvedDescription)
                    .font(.body)
            }

            // 经典 / 无酒精切换：只有能替换出至少一项时才显示。
            if zeroProofVersion.hasSubstitutions {
                Picker("版本", selection: $zeroProof) {
                    Text("经典").tag(false)
                    Text("无酒精").tag(true)
                }
                .pickerStyle(.segmented)
            }

            Group {
                Text(zeroProof ? "配方（无酒精版）" : "配方").font(.headline)
                if let ingredients = displayedIngredients {
                    ForEach(ingredients, id: \.self) { item in
                        HStack(alignment: .top) {
                            Text(item.name)
                            Spacer()
                            Text(item.amount + (item.note.isEmpty ? "" : "（\(item.note)）"))
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                } else if let lines = drink.amountsText {
                    ForEach(lines, id: \.self) { line in
                        Text("• \(line)").font(.subheadline)
                    }
                } else {
                    Text("来源未提供用量，见核验说明。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // 无酒精对照：逐项列出替换与口感差异；做法沿用经典版。
            if zeroProof {
                Group {
                    Text("替换对照").font(.headline)
                    ForEach(zeroProofVersion.substitutions.indices, id: \.self) { index in
                        let sub = zeroProofVersion.substitutions[index]
                        HStack(alignment: .top) {
                            Text(sub.original)
                            Text("→")
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sub.replacement)
                                Text(sub.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .font(.subheadline)
                    }
                    Text("口感差异：" + zeroProofVersion.tasteNotes.joined(separator: "；") + "。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("做法沿用经典版（用量按 1:1 等量替换）。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Group {
                Text("做法").font(.headline)
                if !resolvedMethod.isEmpty {
                    Text(resolvedMethod).font(.subheadline.bold())
                }
                if !resolvedMethodText.isEmpty {
                    Text(resolvedMethodText).font(.subheadline)
                }
            }

            HStack(spacing: 16) {
                if !resolvedGlass.isEmpty {
                    Label(resolvedGlass, systemImage: "cup.and.saucer")
                }
                if !resolvedGarnish.isEmpty {
                    Label(resolvedGarnish, systemImage: "leaf")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // 备注：与红框文案同一句话时不重复显示（数据里双份保存）。
            if !drink.notes.isEmpty, drink.notes != drink.warnText {
                Text("备注：\(drink.notes)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("出处：\(drink.source)")
                if let photo = drink.photo {
                    switch photo.status {
                    case "unresolved":
                        Text("照片：暂无确认实拍")
                    case "rejected":
                        Text("照片：候选图错配，已剔除")
                    case "cached", "ok":
                        Text("照片：本地实拍已打包")
                    default:
                        Text("照片：\(photo.status)")
                    }
                } else {
                    Text("照片：暂无实拍")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
