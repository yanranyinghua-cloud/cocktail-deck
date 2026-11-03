import SwiftUI

// 自定义特调表单：中英文名 / 介绍 / 配料用量 / 做法 / 标签 / 小窍门，
// 下方实时预览卡片（就是保存后进牌堆的样子，带“我的特调”徽章）。
// 保存后进入牌堆，可搜可筛；编辑沿用同一表单。
// 注意：这里 viewModel 用普通持有（不用 @Bindable），因为表单只读
// viewModel 的基酒列表与语言、只调保存方法，不需要订阅它的变化；
// 自定义 init + @Bindable 组合在编译上不稳定，故避开。
struct CustomFormView: View {
    let viewModel: DeckViewModel
    var editing: CustomCocktail?

    @Environment(\.dismiss) private var dismiss

    @State private var draft: CustomCocktail
    @State private var flavorsText: String
    @State private var showInvalidAlert = false

    init(viewModel: DeckViewModel, editing: CustomCocktail? = nil) {
        self.viewModel = viewModel
        self.editing = editing
        let initial = editing ?? CustomCocktail.empty()
        self._draft = State(initialValue: initial)
        self._flavorsText = State(initialValue: initial.flavors.joined(separator: "、"))
    }

    private let methodOptions = ["摇和", "搅拌", "直调", "兑和", "捣碎", "分层"]
    private let difficultyOptions = ["易", "中", "难"]
    private let strengthOptions = ["低", "中", "中高", "高", "无酒精"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        Text("名字").font(.headline)
                        TextField("中文名（可空）", text: Binding(
                            get: { draft.nameZh ?? "" },
                            set: { draft.nameZh = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        TextField("英文名", text: $draft.nameEn)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                        Text("中英文名至少填一个。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Group {
                        Text("介绍").font(.headline)
                        TextField("一句话介绍这杯酒", text: $draft.intro, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }

                    Group {
                        Text("配料").font(.headline)
                        ForEach(draft.ingredients.indices, id: \.self) { index in
                            HStack(spacing: 8) {
                                TextField("材料", text: $draft.ingredients[index].name)
                                    .textFieldStyle(.roundedBorder)
                                TextField("用量", text: $draft.ingredients[index].amount)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 96)
                                Button {
                                    draft.ingredients.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                                .disabled(draft.ingredients.count <= 1)
                            }
                        }
                        Button("＋ 加一味配料") {
                            draft.ingredients.append(Ingredient(name: "", amount: "", note: "", optional: false))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Group {
                        Text("做法").font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(methodOptions, id: \.self) { option in
                                    Button(option) { draft.method = option }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                        .tint(draft.method == option ? .accentColor : .secondary)
                                }
                            }
                        }
                        TextField("做法步骤", text: $draft.methodText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }

                    Group {
                        Text("杯型与装饰").font(.headline)
                        TextField("杯型，如：古典杯", text: $draft.glass)
                            .textFieldStyle(.roundedBorder)
                        TextField("装饰，如：橙皮", text: $draft.garnish)
                            .textFieldStyle(.roundedBorder)
                    }

                    Group {
                        Text("标签").font(.headline)
                        Text("基酒（多选）").font(.subheadline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76))], spacing: 8) {
                            ForEach(viewModel.allBaseSpirits.filter { $0 != "多基酒" && $0 != "利口酒为主" }, id: \.self) { spirit in
                                let selected = draft.baseSpirits.contains(spirit)
                                Button(spirit) {
                                    if selected {
                                        draft.baseSpirits.removeAll { $0 == spirit }
                                    } else {
                                        draft.baseSpirits.append(spirit)
                                    }
                                }
                                .buttonStyle(.plain)
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(selected ? Color.accentColor : Color.secondary.opacity(0.12))
                                .foregroundStyle(selected ? Color.white : Color.primary)
                                .clipShape(Capsule())
                            }
                        }
                        Text("风味（用 、 隔开）").font(.subheadline)
                        TextField("如：清爽、果香", text: $flavorsText)
                            .textFieldStyle(.roundedBorder)
                        HStack(spacing: 12) {
                            Picker("难度", selection: $draft.difficulty) {
                                ForEach(difficultyOptions, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            Picker("酒精度", selection: $draft.strength) {
                                ForEach(strengthOptions, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    Group {
                        Text("小窍门").font(.headline)
                        TextField("给后来者的一句提醒", text: $draft.tip, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()
                    Text("实时预览").font(.headline)
                    DrinkCardView(
                        drink: draft.asDrink(),
                        language: viewModel.language,
                        onDetail: {}
                    )
                }
                .padding(16)
            }
            .navigationTitle(editing == nil ? "写一款特调" : "编辑特调")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!draft.isValid)
                }
            }
            .alert("还差一点", isPresented: $showInvalidAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("中英文名至少填一个，且至少有一味有效配料。")
            }
        }
    }

    private func save() {
        draft.flavors = flavorsText
            .split(whereSeparator: { $0 == "、" || $0 == "," || $0 == "，" })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        draft.ingredients.removeAll { $0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        guard draft.isValid else {
            showInvalidAlert = true
            return
        }
        if editing != nil {
            viewModel.updateCustom(draft)
        } else {
            draft.createdAt = Date()
            viewModel.addCustom(draft)
        }
        dismiss()
    }
}
