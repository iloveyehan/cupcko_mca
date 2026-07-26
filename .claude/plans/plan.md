# UI 重构计划：cupcko_mca 现代化（深色金边主题）

## 目标
保持所有现有功能（数据加载、版本筛选、来源分组、差异对比、扫描器、斜杠命令、事件）不变，仅重构视觉表现层，统一为「深色金边」现代风格。

设计决策（已与用户确认）：
- 视觉主题：深色金边（半透明深色面板 + 金色强调 + 细边框）
- 标签布局：现代竖向侧栏（药丸式，选中态金色高亮）
- 重构范围：全部统一（主窗口 + 差异弹窗 + 扫描器进度/结果窗口）

## 1. 新增共享主题文件 `cupcko_theme.lua`（TOC 中置于 myScanner 之前）
定义 `addonTable.Theme`，集中管理：
- **配色**：`bg`=#1a1a22、`panel`=#22222c、`panelHover`=#2c2c38、`border`=#3a3a2e（暗金）、`accent`=#c8a96a（金）、`accentDim`、`text`=#e8e2d0、`textDim`=#9a9484、`success`=#5ec46a、`danger`=#c45a5a
- **辅助函数**：
  - `Theme.ApplyPanel(frame, opts)` - 用 `Interface\Buttons\WHITE8x8` 做纯色底 + 1px 细边（`edgeSize=1`），实现扁平卡片
  - `Theme.CreateButton(parent,text,w,h)` - 扁平按钮，hover/pressed 改底色，金字
  - `Theme.CreateTab(parent)` - 侧栏药丸 Tab，含选中态（金色高亮条 + 高亮底）、hover、未选中态
  - `Theme.CreateHeader(parent,...)` - 顶部标题条 + 金色分隔线
  - `Theme.SkinScrollBar(scrollFrame)` - 防御性重绘滚动条为细金色滑块，隐藏上下按钮；并 `EnableMouseWheel`
  - `Theme.CreateStatusBar(...)` / `Theme.CreateIconButton(...)` - 进度条与坐骑图标按钮
- 通过 `local Theme = addonTable.Theme` 在两文件中复用。

## 2. `cupcko_mca.lua` 主窗口重构
- **主框体**：移除旧 `UI-DialogBox-*` 贴图，改用 `Theme.ApplyPanel`（深色半透 + 金细边）；保留 movable/resizable/clamped/ESC 关闭。
- **顶栏**：`CreateHeader`，标题「坐骑收集」金色字 + 底部 1px 金色分隔线；右上自定义 ✕ 关闭按钮（扁平金边）。
- **侧栏（竖向）**：在框内左侧新建 ~130px 宽容器，内含可滚动 Tab 列表；Tab 用 `CreateTab`，选中态显示金色左竖条 + 高亮底；高度不足时可滚动。`SetSelectedTab` 改为通过回调设置选中样式（不再用 Disable）。
- **内容滚动区**：锚定到侧栏右侧，使用 `Theme.ApplyPanel` 给内容区一个略深的画布底；滚动条 `SkinScrollBar`；启用鼠标滚轮。
- **总览卡片**：每张卡片用 `ApplyPanel`（深色卡 + 金细边 + hover 提亮）；进度条改用 `StatusBar` + 渐变填充（100% 金、其余绿->黄->红过渡），名称/计数字体美化；点击仍跳转对应版本 Tab。
- **坐骑网格**：图标按钮加 1px 金细边底框；已收集=原色 + 金边；未收集=去饱和变灰 + 暗红边；hover 放大 1.15× + 高亮边 + 名称悬浮提示；保留原 tooltip 与点击行为（右键召唤、Shift 链接、Ctrl 试穿）。
- **底部**：扁平「差异」按钮（`CreateButton`）；右下自定义调整大小手柄（细金色把手）。
- **差异弹窗**：复用 `ApplyPanel` + `SkinScrollBar` + 扁平关闭按钮统一风格。
- 斜杠命令：保留 `/.`，并新增 `/cmca` 兼容。

## 3. `myScanner.lua` 窗口统一重构
- 进度条窗口 `CreateProgressBar`、结果窗口 `ShowScanResults` 全部改用 `Theme.ApplyPanel` / `Theme.CreateHeader` / `Theme.SkinScrollBar`，配色与主窗口一致；StatusBar 用金色填充。

## 4. TOC 更新
```
cupcko_data.lua
cupcko_theme.lua   ← 新增
myScanner.lua
cupcko_mca.lua
```

## 不做 / 取舍
- **不做真圆角**：WoW 裁剪圆角纹理复杂且易碎，改用扁平卡片+细边+内缩模拟现代感（与 Details 等主流插件一致）。
- **不做平滑动画**：hover/选中使用即时状态切换，保证性能与稳定。
- **不改数据结构与业务逻辑**：`externalMountData`、`expansions`、`sources`、扫描协程逻辑全部保持原样。
- 仅在需要时做防御性存在性检查，确保 retail（Interface 120000）下不报错。

## 验证方式
- WoW API 无法在命令行运行，以代码审查 + 上线后 `/reload` 实测为准；保证：插件加载无报错、`/.` 打开窗口、Tab 切换、总览卡片、坐骑网格 hover/点击、差异弹窗、扫描窗口均正常。

## 涉及文件
- 新增 `cupcko_theme.lua`
- 改写 `cupcko_mca.lua`（UI 部分）
- 改写 `myScanner.lua`（窗口 UI 部分）
- 改 `cupcko_mca.toc`（加入主题文件）
