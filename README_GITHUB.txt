调酒卡片 iOS 版 · GitHub 编译验证说明（给 Eloc）

目标：不花钱验证工程“编不编得过”。只能验编译，看不到模拟器界面、点不了 App；真机手感以后再说。

步骤：
1. 打开 github.com，新建仓库（New repository），名字比如 cocktail-deck。
   - Public（公开）：macOS 编译时间免费，最省事。注意公开后数据和照片都可见（反正 App 里也要带这些照片）。
   - Private（私有）：每月有免费额度，macOS 按 10 倍计分钟，约 200 分钟，几次编译也够用。
2. 把本压缩包解压，用 GitHub Desktop 最省事：克隆空仓库到本地 → 把解压出来的文件拷进去 → 提交（Commit）→ 推送（Push）。
   注意：.github/workflows/ios.yml 这个文件也要一起传上去，它就是自动编译的任务。
3. 到仓库的 Actions 标签页，看 iOS Build Check 的运行结果：
   - 绿勾 = 编过了。
   - 红叉 = 点进去看报错日志，把报错文字发给 Muse，我这边改，改完你再推一次。
4. 模拟器编译不需要开发者账号；Bundle ID 占位和空 AppIcon 不影响这次验证，提交时再换。

工程数据：1123 款酒，1100 张实拍照片在 Resources/Photos/ 里，数据文件 Resources/drinks.json，中英对照 Resources/en.json。
