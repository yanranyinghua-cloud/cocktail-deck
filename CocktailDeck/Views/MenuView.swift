import SwiftUI
import UIKit

// 私人酒单 Tab：按酒精度分三段——轻松开场 / 主角登场 / 压轴慢饮；
// 带备料清单（按配料名聚合，列出用到的酒款与各自用量）与可复制文字版。
// 酒单标题可编辑，改动在视图消失时保存；酒款增减即时保存。
struct MenuView: View {
@Bindable var viewModel: DeckViewModel
var onDetail: (Drink) -> Void

@State private var draftTitle = ""
@State private var copied = false

/// 酒精度 → 段：低/无酒精→轻松开场，中/中高/空/未知→主角登场，高→压轴慢饮。
private func section(for drink: Drink) -> String {
switch drink.filterTags?.strength {
case "低", "无酒精": return "轻松开场"
case "高": return "压轴慢饮"
default: return "主角登场"
}
}

private var sections: [(title: String, drinks: [Drink])] {
let ordered = ["轻松开场", "主角登场", "压轴慢饮"]
return ordered.map { title in
(title, viewModel.menuDrinks.filter { section(for: $0) == title})
}.filter {!$0.drinks.isEmpty}
}

/// 备料清单：配料名 → [(酒款名, 用量)]，按配料名排序。
private var shoppingList: [(name: String, uses: [(drinkName: String, amount: String)])] {
var map: [String: [(String, String)]] = [:]
for drink in viewModel.menuDrinks {
for item in drink.ingredients?? [] {
map[item.name, default: []].append((drink.name(for: viewModel.language), item.amount))
}
}
return map.keys.sorted().map { (name: $0, uses: map[$0]!)}
}

private var textVersion: String {
var lines: [String] = [viewModel.menu.title, ""]
for section in sections {
lines.append("")
for drink in section.drinks {
lines.append("· \(drink.name(for: viewModel.language))")
}
lines.append("")
}
lines.append("")
for entry in shoppingList {
let uses = entry.uses.map { "\($0.drinkName)\($0.amount.isEmpty? "": " \($0.amount)")"}
.joined(separator: "；")
lines.append("· \(entry.name)：\(uses)")
}
lines.append("")
lines.append("适量饮酒，开心最重要")
return lines.joined(separator: "\n")
}

var body: some View {
ScrollView {
VStack(alignment:.leading, spacing: 16) {
TextField("酒单标题", text: $draftTitle)
.font(.title3.bold())
.textFieldStyle(.roundedBorder)
.onAppear { draftTitle = viewModel.menu.title}

if viewModel.menuDrinks.isEmpty {
ContentUnavailableView(
"酒单还是空的",
systemImage: "wineglass",
description: Text("在牌堆、推荐或详情页点“加入酒单”，这里会按酒精度分段排好。")
)
} else {
ForEach(sections.indices, id: \.self) { sectionIndex in
    let section = sections[sectionIndex]
VStack(alignment:.leading, spacing: 8) {
Text("\(section.title)（\(section.drinks.count) 款）")
.font(.headline)
ForEach(section.drinks) { drink in
HStack {
Button {
onDetail(drink)
} label: {
VStack(alignment:.leading, spacing: 2) {
Text(drink.name(for: viewModel.language))
.font(.subheadline.bold())
Text(drink.baseSpirits.joined(separator: " · "))
.font(.caption)
.foregroundStyle(.secondary)
}
}
.buttonStyle(.plain)
Spacer()
Button {
viewModel.toggleMenu(drink)
} label: {
Image(systemName: "trash")
.foregroundStyle(.red)
}
.buttonStyle(.plain)
}
.padding(10)
.background(Color.secondary.opacity(0.08))
.clipShape(RoundedRectangle(cornerRadius: 12))
}
}
}

Divider()
Text("备料清单").font(.headline)
ForEach(shoppingList.indices, id: \.self) { entryIndex in
    let entry = shoppingList[entryIndex]
VStack(alignment:.leading, spacing: 2) {
Text(entry.name).font(.subheadline.bold())
Text(entry.uses.map { "\($0.drinkName)\($0.amount.isEmpty? "": " \($0.amount)")"}.joined(separator: "；"))
.font(.caption)
.foregroundStyle(.secondary)
}
}

Button(copied? "已复制 ✓": "复制文字版") {
UIPasteboard.general.string = textVersion
copied = true
}
.buttonStyle(.borderedProminent)
.frame(maxWidth:.infinity)
}

Text("适量饮酒，开心最重要")
.font(.footnote)
.foregroundStyle(.secondary)
}
.padding(16)
}
.onDisappear {
let title = draftTitle.trimmingCharacters(in:.whitespaces)
if!title.isEmpty, title!= viewModel.menu.title {
viewModel.saveMenuTitle(title)
}
}
}
}
