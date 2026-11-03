import SwiftUI

// 调酒卡片 iOS 原生版 · 一阶段骨架
// 注意：本工程不内置任何占位酒款数据。数据全部来自 Resources/drinks.json，
// 若文件缺失或解析失败，界面显示空态，不虚构任何酒款。
@main
struct CocktailDeckApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
