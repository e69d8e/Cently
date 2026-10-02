# AGENTS.md — Cently（分厘）

## 项目概况
- Flutter 个人记账应用：**离线优先、数据全部存本地 SQLite、无任何云端**；UI 全中文（`locale: zh_CN`）。
- 当前版本 `1.0.5+6`（见 pubspec.yaml），支持 Android / iOS / macOS / Windows / Linux / Web 六端。
- 技术栈：Dart SDK ^3.13.0、`provider` 状态管理、`sqflite`（+ `sqflite_common_ffi` / `sqflite_common_ffi_web`）、`fl_chart`、`intl`。`publish_to: none`，私有项目勿发布 pub.dev。
- 唯一的网络能力是「检查更新」（`lib/services/update_service.dart`）：仅在用户开启自动检查或手动触发时请求 GitHub Releases API（`e69d8e/Cently`），不上传任何数据；自动检查默认关闭、每天最多一次，失败静默降级。除此之外不得新增任何联网行为。

## 常用命令
```bash
flutter pub get                                  # 安装依赖
flutter analyze                                  # 静态分析（CI 门禁，需零告警）
flutter test                                     # 全部测试（当前 104 项，CI 门禁）
flutter test test/unit/transaction_provider_test.dart   # 单跑一个测试文件
flutter run -d macos                             # 本地调试（也可 -d chrome 等）
```
- CI（`.github/workflows/ci.yml`）：push/PR 到 main 时执行 `flutter analyze` + `flutter test`，二者都必须通过。
- 发布（`release.yml`）：推送 `vX.Y.Z` 标签触发全平台构建矩阵，勿手动改版本号而不打标签。bump 版本号时需同步 `lib/services/update_service.dart` 里的兜底常量 `kFallbackAppVersion`（仅 PackageInfo 不可用时使用）。

## 架构分层（lib/）
- 依赖方向：`models/` → `data/`（DatabaseHelper 单例 + DefaultData 预置数据）→ `providers/`（ChangeNotifier）→ `screens/` + `widgets/`；`theme/`、`utils/` 横切，`services/` 承载外部服务（目前仅 GitHub 检查更新）。UI 只经 provider 读写数据，**不得绕过 provider 直接操作 DB**。
- `lib/data/database_helper.dart`：schema 当前 **version 6**。改表结构必须：① 递增 `version:`；② 在 `_onUpgradeDB` 追加 `if (oldVersion < N)` 迁移分支，禁止破坏性重建。
- 软删除模型：账单不物理删除，写 `deletedAt`（30 天回收站）。新增查询注意过滤 `isDeleted`，彻底删除仅回收站可触发。
- 记录/分类 ID 一律用 `uuid` 生成。

## 平台兼容要点（易踩坑）
- `database_helper.dart` 里的数据库工厂分支不可删：Web → `databaseFactoryFfiWeb`；Windows/Linux/macOS → `sqfliteFfiInit()` + `databaseFactoryFfi`。删掉任一分支对应端直接崩。
- 调用 `Platform.*`（dart:io）前必须先判 `kIsWeb`，Web 上会抛异常。
- `import 'package:flutter/foundation.dart'` 需写 `hide Category;`（与本项目 `models/category.dart` 的 `Category` 类冲突）。
- 移动端锁竖屏（main.dart 里 `SystemChrome.setPreferredOrientations`，Web/桌面端跳过）。
- macOS 沙盒（`macos/Runner/{DebugProfile,Release}.entitlements`）必须保留 `com.apple.security.network.client`，否则出站网络全挂：检查更新请求失败、`url_launcher` 打不开链接。

## 代码约定
- 颜色一律用 `lib/theme/app_colors.dart` 的 token（expense/income/balance 等均有 dark 变体），禁止在页面里硬编码十六进制色值；深浅色必须同时适配（`AppTheme.lightTheme` / `darkTheme`）。
- 金额展示用 `lib/utils/currency_format.dart`（`format` / `formatCompact` / `formatRaw`），带 ¥ 符号；不要手写数字格式化。
- 禁止 `print(`；catch 块里用 `debugPrint` 并静默降级，绝不阻塞启动或交互（现有 provider 均如此）。
- UI 文案全中文；提交信息为中文加前缀，如 `feat & ui:`、`docs:`、`test & docs:`、`feat(ci):`。

## 测试要点
- 每个测试文件需在 `setUpAll` 中：`TestWidgetsFlutterBinding.ensureInitialized(); sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;`
- 用内存库 + 现有测试钩子：`openDatabase(inMemoryDatabasePath, ...)` → `DatabaseHelper.instance.createDBForTesting(db)` → `DatabaseHelper.setDatabaseForTesting(db)`。
- 布局：`test/unit/` 为 provider/工具单测；`cently_test.dart`、`widget_test.dart` 为组件测试。
- 涉及版本号展示的 widget 测试用 `PackageInfo.setMockInitialValues(...)` 固定版本（10.x 必须带 `buildSignature: ''`）；测试环境无网络，更新检查只能用 `UpdateService(httpClient: MockClient(...))` 注入假响应。

## 改动前建议阅读
- `README.md`：构建/签名/CI 说明。注意 Android 官方签名依赖 `android/key.properties` 与 `cently-release.jks`（均已 gitignore），本地缺失时 release 构建回退 debug 签名，仅限本地调试、不可分发。
- `CHANGELOG.md`：各版本技术要点与产物校验指纹。
