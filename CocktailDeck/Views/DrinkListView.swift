import SwiftUI

// 列表：行点开后就地展开，显示完整配方与做法；同时只展开一款。
// 新参数全部给默认值，旧调用点仍能编译。
struct DrinkListView: View {
    let drinks: [Drink]
    let language: AppLanguage
    let englishRecipes: [String: EnglishRecipe]
    let menuIds: Set<String>
    let onToggleMenu: (Drink) -> Void

    init(
        drinks: [Drink],
        language: AppLanguage = .chinese,
        englishRecipes: [String: EnglishRecipe] = [:],
        menuIds: Set<String> = [],
        onToggleMenu: @escaping (Drink) -> Void = { _ in }
    ) {
        self.drinks = drinks
        self.language = language
        self.englishRecipes = englishRecipes
        self.menuIds = menuIds
        self.onToggleMenu = onToggleMenu
    }

    @State private var expandedId: String?

    var body: some View {
        List(drinks) { drink in
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    withAnimation {
                        expandedId = (expandedId == drink.id) ? nil : drink.id
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(drink.name(for: language))
                                .font(.headline)
                            Text(drink.baseSpirits.joined(separator: " · "))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VerificationBadge(label: drink.verificationLabel)
                        Image(systemName: expandedId == drink.id ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if expandedId == drink.id {
                    DrinkDetailBody(
                        drink: drink,
                        language: language,
                        englishRecipe: englishRecipes[drink.id],
                        isInMenu: menuIds.contains(drink.id),
                        onToggleMenu: { onToggleMenu(drink) }
                    )
                    .padding(.top, 4)
                }
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}
