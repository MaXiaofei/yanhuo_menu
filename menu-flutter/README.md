# 咕嘟小食单 App（Flutter 版）

与 `menu-mini` 小程序**功能与样式一致**的 Android + iOS 原生 App，直连现有 Spring Boot 后端（`menu-api`，零改动）。

> **当前进度：P0**（脚手架 + 登录 + 首页 hub + 菜库 + 菜品详情含步骤计时器）。其余页面（点评/录入/周计划/库存/采购/每日记录/AI）为占位页，将在 P1/P2 替换。

---

## 一、环境准备

### Mac（iOS + Android 开发）

按顺序装好，每装一个跑一次 `flutter doctor` 看是否变绿。

| 软件 | 安装 | 说明 |
|---|---|---|
| **Flutter SDK** | `brew install --cask flutter` 或官网下 zip | 含 Dart。装完 `flutter doctor` |
| **Xcode** | Mac App Store（约 12GB） | iOS 编译签名必需 |
| **CocoaPods** | `sudo gem install cocoapods` 或 `brew install cocoapods` | iOS 插件依赖 |
| **Android Studio** | [developer.android.com/studio](https://developer.android.com/studio) | Android SDK + 模拟器。装完在 SDK Manager 下 API 36 |
| **Apple ID** | 注册免费账号（个人）| 见下文"iOS 免费签名" |

跑 `flutter doctor`，确认 **Xcode ✅、CocoaPods ✅、Android SDK ✅** 再往下。

### 测试设备

| 平台 | 设备 | OS 版本 | Android 底层 |
|------|------|---------|-------------|
| iOS | iPhone（AltStore 侧载）| 待定 | - |
| Android | Redmi Note 15 | HyperOS 3.0 (`WPQCNXM`) | **Android 16** (API 36) |

> Android 16 = API 36。`compileSdk`/`targetSdk` 走 Flutter SDK 内置值即可，不需要手动改。

---

## 二、首次运行（4 步）

### 1. 生成 iOS/Android 原生壳

本目录已含 `lib/`（业务代码）和 `pubspec.yaml`，缺的是 `android/`、`ios/` 原生壳。在**本目录**运行：

```bash
cd menu-flutter
flutter create --org com.maxiaofei --project-name menu_flutter --platforms=ios,android .
```

> `flutter create` 会保留已有的 `lib/`、`pubspec.yaml`，只补 `android/`、`ios/`、`test/` 等缺失文件。
> 生成的 Bundle ID 为 `com.maxiaofei.menuFlutter`。

### 2. 覆盖 iOS 配置（允许明文 HTTP + 权限说明）

用本仓库的 `ios/Runner/Info.plist` 覆盖 `flutter create` 生成的同名文件（已含 ATS 放行 + 相册/相机权限 + 中文显示名）：

```bash
# 已在本仓库，无需操作；若 flutter create 覆盖了它，重新 git checkout 恢复
git checkout ios/Runner/Info.plist
```

> 这一步是为了内测能连 `http://49.232.3.201:9090`（明文）。**上架前必须删掉 `NSAppTransportSecurity` 段并给后端配 HTTPS。**

### 3. 装依赖

```bash
flutter pub get
```

### 4. 改后端地址（按需）

`lib/core/constants.dart` 的 `baseUrl`，测试环境默认是 `http://49.232.3.201:9090/gudu`。改成你自己的后端地址（注意保留 `/gudu`）。

### 5. 跑起来（先 iOS 模拟器）

```bash
flutter run
```

选择一个 iOS 模拟器。应看到：登录页（用户名 `admin` + 密码）→ 首页 hub（橙色顶栏）→ 浏览菜库。

---

## 三、iOS 免费账号真机内测（你的 iPhone）

### 准备：加签名身份

1. 打开 **Xcode → Settings → Accounts → 左下 +** → 登录免费 Apple ID → 出现「Personal Team」。
2. 终端：`open ios/Runner.xcworkspace`。
3. 左侧选 **Runner** → **Signing & Capabilities** → **Team** 选你的 Personal Team。
   - Bundle Identifier 显示 `com.maxiaofei.menuFlutter`（勿用通配符，免费账号不支持）。

### 装到手机

1. 数据线连 iPhone 到 Mac，手机弹「**信任此电脑**」→ 输锁屏密码。
2. Xcode 顶部设备下拉选你的 iPhone。
3. `flutter run`（或 Xcode 点 ▶ Run）。
4. **首次必做**：手机 `设置 → 通用 → VPN与设备管理` → 找到「开发者 App / 你的开发者证书」→ `信任`。
   - 不做这步，App 闪退，提示「不受信任的开发者」。

### ⚠️ 免费账号限制（请知悉）

- **签名 7 天过期**：过期后 App 打不开，需手机连 Mac 重新 `flutter run` 重签。
- **每台设备最多 3 个免费签名 App**。
- **家人设备**：每台都要物理连你的 Mac 签一次，7 天一次，无法远程安装。
- **重签后本地数据可能清空**：关键数据走后端，别只存手机。
- 不能推送/上架/TestFlight（这些需 $99/年开发者账号）。

---

## 四、功能与小程序对照（P0）

| 页面 | 路由 | 状态 | 对应小程序 |
|---|---|---|---|
| 登录 | `/login` | ✅ P0 | `pages/login/Login` |
| 首页 hub（10 个功能入口） | `/` | ✅ P0 | `pages/index/Index` |
| 菜库列表（搜索/分页/封面缩略图） | `/dish` | ✅ P0 | `pages/dish/List` |
| 菜品详情（步骤计时器/营养/标记做过/缩略图点开原图） | `/dish/:id` | ✅ P0 | `pages/dish/Detail` |
| 点评（星级/文字/传图/分项打分） | `/dish/:id/review` | ✅ P0 | `pages/dish/Review` |
| 录入新菜（手动 + URL 导入，图片压缩上传） | `/create-dish` | ✅ P0 | `pages/dish/Create` |
| 录入食材（AI 补全营养 / 自定义单位自动补入 dict） | `/create-ingredient` | ✅ P0 | `pages/ingredient/Create` |
| 食材库存（全部/临期/不足 + 批量添加 + 手动扣减 + 单位自动匹配） | `/pantry` | ✅ P0 | `pages/pantry/List` |
| 采购清单（plan/dish/menu/custom 四种生成 + 纯文字分享 + 品类分区） | `/shopping` | ✅ P0 | `pages/shopping/Shopping` |
| 每日饮食记录（轻量+精准双模式 / 菜库选菜 / 日期滑动） | `/dailylog` | ✅ P0 | `pages/dailylog/DailyLog` |
| 周计划 | `/mealplan` | 🚧 占位 | `pages/mealplan/Calendar` |
| AI 定菜单 | `/ai-recommend` | 🚧 占位（后端已完：规则引擎+紧凑 prompt+缓存） | `pages/ai/Recommend` |
| AI 估营养 | `/ai-estimate` | 🚧 占位（后端已完：prompt 收紧+aiNote 固定） | `pages/ai/Estimate` |

> **待打磨**：菜品详情、菜单、周计划页面仍需精细化设计（当前为 MVP 基础版）。

---

## 五、关键后端契约（已封装在 `lib/core/`，改地址即可）

- baseURL **带 `/gudu` 前缀**（后端 context-path）：`http://49.232.3.201:9090/gudu`
- 鉴权 header：`Authorization: <裸 token>`（**无 Bearer 前缀**）
- 统一响应 `{code,msg,data}`：`code==0` 成功，`401` 跳登录
- 分页取 `records`
- memberId 由后端 session 取，调 AI/日志前先在首页切换当前成员

---

## 六、目录结构

```
lib/
├── main.dart / app.dart          入口 + 主题 + Provider 注入
├── core/                         主题、常量、dio 封装、路由
├── models/                       数据模型（Dish/Member/...）
├── services/                     API 调用（对应 menu-mini/src/api）
├── stores/                       状态（AuthStore/MemberStore）
├── widgets/                      通用组件（营养网格/成员条）
└── pages/                        13 个页面
```

---

## 七、常见问题

- **真机连不上后端**：① 确认手机和服务器同网段；② `ios/Runner/Info.plist` 的 `NSAllowsArbitraryLoads` 是否生效；③ 后端 `menu-api` 是否在跑。
- **中文乱码/字体**：iOS 已配 `zh_CN`；如需自定义中文字体，在 `pubspec.yaml` 声明字体。
- **签名失败**：Xcode → Signing & Capabilities → 勾选 Automatically manage signing → Team 选 Personal Team。
