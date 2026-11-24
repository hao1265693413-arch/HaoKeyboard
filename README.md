# 豪の键盘

一把自己做的 iOS 键盘：黑白灰三档键帽、顶部工具栏（脚本 / 换行 / 粘贴 / 左 / 右 / 板子 / 地球 / 全选 / 收起）。

## 现状（M1 壳）

- 键盘本体：字母 / 数字 / 符号三页
- 工具栏 9 个键全部可用（脚本、板子、中文还是占位）
- 双击空格出句号、长按空格出「。」、长按字母出右上角小标符号
- 退格长按连删、⇧ 单击切大小写、双击锁大写

## 编译

CI 用 GitHub Actions 的 macOS 机器，XcodeGen 生成工程后 xcodebuild 出无签名 IPA：

```
xcodegen generate
xcodebuild -project HaoKeyboard.xcodeproj -scheme HaoKeyboard -configuration Release -sdk iphoneos CODE_SIGNING_ALLOWED=NO
```

产物 `HaoKeyboard.ipa`，用 TrollStore 装。

## 下一步

- M2：中文拼音引擎（全拼 + 候选栏）
- M3：简拼 / 混拼 + 个人学习 + 常用语
- M4：手感打磨（震动、按键音、主题）
