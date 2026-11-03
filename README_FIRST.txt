调酒卡片 iOS 版 · 首次编译说明（给 Eloc）

1. 打开 CocktailDeck.xcodeproj（双击工程文件，不是文件夹里的其他文件）。
2. Xcode 顶部设备栏选一个 iPhone 模拟器（比如 iPhone 17），点 Run（▶）。
3. 模拟器编译不需要开发者账号；Bundle ID 现在是占位 com.example.CocktailDeck、AppIcon 是空集，这两样都不影响模拟器运行，提交时再换。
4. 第一次编译很可能报几个错（这工程还没在 Mac 上编过），把报错截图或文字发给 Muse，我这边改。
5. 注意：MacinCloud 这单 0.99 美元只是 24 小时试用价，定期计划费用 39 美元/月；试用期过后如果不取消，会自动按 39 美元续费。用完记得取消订阅。
6. 工程数据：1123 款酒，1100 张实拍照片已打包在 Resources/Photos/ 里，数据文件 Resources/drinks.json，中英对照 Resources/en.json。
