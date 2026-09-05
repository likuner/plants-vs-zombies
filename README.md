# 后院保卫战

一个离线运行的 SwiftUI 植物大战僵尸风格 iOS 原型。

## 本地预览

1. 用 Xcode 打开 `PlantsVsZombies.xcodeproj`。
2. 选择 `PlantsVsZombies` scheme 和一个 iOS 17+ Simulator。
3. 点击 Run 查看真实游戏循环，或在 `ContentView.swift` 打开 `#Preview("后院保卫战")` 查看静态预览。

## 游戏操作

- 点击植物卡片，再点击草坪格子种植。
- 向日葵每隔一段时间产生阳光。
- 豌豆射手自动向所在横向车道发射豌豆。
- 坚果墙可以挡住僵尸，为防线争取时间。
- 使用右侧圆形按钮暂停；胜负结束后同一按钮可重新开始。
- 使用顶部扬声器按钮切换音效。

当前版本不依赖网络或外部素材，所有图形使用 SwiftUI 和 SF Symbols 绘制，音效由本地程序实时生成。
