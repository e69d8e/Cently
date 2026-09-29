# 🪙 分厘 (Cently) v1.0.3 发布说明

> *分厘之间，细致入微 · 分文厘毫，了然于胸*

**分厘 (Cently)** 是一款基于 Flutter 构建的高颜值、纯本地、无后端的个人记账与财务分析应用。v1.0.3 版本聚焦于**界面视觉美学与人机交互体验的全面升级**，消除高频录入时的数字抖动，优化暗黑模式对比度，提供更顺畅的手势操作与多分类选取体验，并保持 100% 离线隐私安全与严格的测试保障。

---

### 📋 版本发布信息

- **版本号**：`v1.0.3`（构建版本 `1.0.3+4`）
- **发布日期**：2026-09-12
- **Git 标签**：`v1.0.3`
- **发布地址**：[GitHub Releases v1.0.3](https://github.com/e69d8e/Cently/releases/tag/v1.0.3)
- **代码对比**：[`v1.0.2...v1.0.3`](https://github.com/e69d8e/Cently/compare/v1.0.2...v1.0.3)

---

### ✨ 新增与优化内容 (Changelog)

#### 1. 🔠 全局等宽数字排版 (Tabular Figures)
- **消除高频数字抖动**：在全局 Light / Dark TextTheme 中注入 `FontFeature.tabularFigures()`，并在主页月度看板、流水明细、数字键盘按键、记账输入与实时计算预览、统计排行榜、回收站剩余天数等所有核心展示位显式启用等宽数字排版，彻底消除敲击与滚动时的字形跳动。

#### 2. 🌙 暗黑模式对比度与层级重构
- **主记账 FAB 按钮焦点重塑**：暗黑模式下改用极简高反差白亮表面 (`#F8FAFC`) 配深色图标，配合精细环形外圈描边，解决深色底栏下 FAB 融于背景的问题。
- **柔和财务背景色阶**：引入 `expenseBgDark`、`incomeBgDark`、`balanceBgDark` 等专为暗色适配的半透明微底色，带来舒适高质感的暗色财务体验。

#### 3. 📱 主页操作体验与看板美化
- **左右轻扫快速切月**：账单流水列表支持水平滑动手势（`onHorizontalDragEnd`），左右滑动即可轻快在各月份之间切换并伴随触觉反馈。
- **现代财务看板重构**：独立 Capsule Pill 标识账期，突出呈现“结余”Hero 金额及平滑淡入淡出动画，搭配收支双栏柔和卡片。
- **搜索体验增强**：搜索栏支持匹配笔数实时胶囊指示（`共匹配到 X 笔记录`）与一键清空按钮。
- **滑动删除交互**：滑动删除升级为带图标与提示文本的圆角胶囊背景。

#### 4. ⌨️ 记账流程与计算键盘交互升级
- **分类 5 列紧凑网格一键展开**：在记账页引入分类展开/收起按钮，支持在“单行横划”与“5列紧凑网格”之间一键平滑切换，海量自定义分类也能一屏直选。
- **计算器键盘实时算式激活**：`+` / `-` 运算符处于活动状态时按键高亮展示，金额显示区实时计算并预览运算结果（如 `= 128.50`）。
- **预设芯片优化**：选中项配备主色细边框与对勾图标，配合微动画自然过渡。

#### 5. 📊 统计分析与排行榜排版
- **金银铜专属奖牌徽章**：排行榜前三名显式增加 `#1`（金）、`#2`（银）、`#3`（铜）高反差徽章，层次分明。
- **动效微调**：饼图中心数据切换增加平滑淡入淡出动效，进度条升级为两端全圆角的 5dp 胶囊槽。

#### 6. 🏷️ 图标选择器语义化过滤
- **9 大语义分类**：新增「全部、餐饮、交通、购物、居家、娱乐、医疗、财务、其他」过滤标签，快速缩小图标搜寻范围。

#### 7. 🧪 自动化测试与代码质量
- **65 项测试全量绿灯通过**：覆盖模型、状态机、多字段搜索、回收站 30 天自动清理规则及全套 Widget 交互测试。
- **静态分析零告警**：`flutter analyze` 保持 0 Warning / 0 Error。

#### 8. 🔐 Android 官方发布签名
- **告别 debug 签名**：Android 全部发布产物（APK / AAB）改用 Cently 官方 release 密钥（PKCS12，alias `cently`，有效期 30 年）签名，可正常覆盖升级并通过分发平台校验。
- **CI 自动验签**：Release 流水线从 Repository Secrets 还原密钥库，打包后自动执行 `apksigner` / `keytool` 证书指纹校验，签名不符即构建失败。

---

### 📦 全平台安装包下载指南

| 平台 / 系统 | 推荐下载文件 | 说明 |
| :--- | :--- | :--- |
| **🪟 Windows** | `Cently-Windows-x64-1.0.3-Setup.exe` | **Windows 标准安装向导程序**（推荐），支持创建桌面与开始菜单快捷方式。<br>*亦提供 `Cently-Windows-x64-v1.0.3.zip` 绿色免安装版* |
| **🍎 macOS** | `Cently-macOS-v1.0.3.dmg` | **macOS 拖拽安装镜像**（推荐），双击打开后拖拽至 Applications 目录即可。<br>*亦提供 `Cently-macOS-v1.0.3.zip` 原生应用压缩包* |
| **🐧 Linux** | `Cently-Linux-amd64-v1.0.3.deb` | **Debian / Ubuntu 安装包**（推荐），双击或通过 `sudo dpkg -i` 安装。<br>*亦提供 `Cently-Linux-x64-v1.0.3.tar.gz` 独立运行包* |
| **🍏 iOS** | `Cently-iOS-unsigned-v1.0.3.ipa` | **iOS 独立应用包**，支持通过 TrollStore、AltStore、Sideloadly 或企业证书自签名安装。 |
| **🤖 Android** | `Cently-Android-arm64-v8a-v1.0.3.apk` | **64 位 ARM 安装包**（推荐绝大多数现代 Android 手机），体积更小。<br>• 全架构通用版：`Cently-Android-Universal-v1.0.3.apk`<br>• 32 位老旧机型：`Cently-Android-armeabi-v7a-v1.0.3.apk`<br>• PC 模拟器及 x86：`Cently-Android-x86_64-v1.0.3.apk`<br>• Google Play 格式：`Cently-Android-v1.0.3.aab` |
| **🌐 Web** | `Cently-Web-v1.0.3.zip` | **Web 静态网站资源包**，解压后可直接部署至 Nginx、Apache、Vercel 或 GitHub Pages。 |

---

### 🔐 安装包签名校验

Android 产物已由 **Cently 官方 release 密钥**签名（不再使用 debug key），可用以下命令核对：

```bash
# APK
apksigner verify --print-certs Cently-Android-Universal-v1.0.3.apk
# AAB
keytool -printcert -jarfile Cently-Android-v1.0.3.aab
```

官方签名证书指纹（应与输出完全一致）：

- **SHA-256**：`2B:E3:1B:55:C2:A8:58:D4:F3:39:0D:83:4A:BB:7E:28:77:D6:BA:2F:AD:8A:29:FE:80:F5:E8:11:50:E7:8B:68`
- **SHA-1**：`F3:E0:B7:CA:7C:C3:F5:DB:8F:D6:78:FB:9F:36:43:04:55:DE:D3:60`
- **证书主体**：`CN=Cently, OU=Cently Mobile, O=Cently, L=Beijing, ST=Beijing, C=CN`

> ⚠️ iOS 产物仍为未签名 `.ipa`（`--no-codesign`），需自行签名后安装；Windows / macOS / Linux 桌面产物未做代码签名。

---

**完整提交记录**：https://github.com/e69d8e/Cently/commits/v1.0.3
