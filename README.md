# 旅行伴侣 · Travel Companion

> 一款为重度旅行者设计的、覆盖全生命周期的个人旅行操作系统

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev/)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.x-blue)](https://riverpod.dev/)
[![Drift](https://img.shields.io/badge/Drift-SQLite-orange)](https://drift.simonbinder.eu/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 项目背景

作者长期作为朋友圈中的"旅行组织者"——负责规划行程、订酒店、AA 分账。在使用过现有所有主流旅行 app（携程、飞猪、马蜂窝、小红书、圆周旅迹、路敢敢、TripIt 等）后，发现一个市场空白：

**没有任何一款 app 完整覆盖"决策 → 规划 → 执行 → 结算 → 留存"全流程**。每次旅行都需要在 4-5 个 app 之间反复切换，信息反复抄录。

本项目正是为了填补这个空白——做一款**反商业化的、为重度旅行者设计的、覆盖全生命周期的个人工具**。

详细的需求分析、用户画像、竞品调研见 [docs/SRS.md](docs/SRS.md)。

---

## 核心特性

### 已实现（v1.0）

- **行程规划**：按天 + 时间轴的多日行程编辑，6 种活动类型颜色区分
- **待定池**：先收集候选活动、再决定排期的真实心智模型（竞品都没做对的核心交互）
- **预算与记账**：实时预算进度、按类别汇总、超支预警
- **PDF 导出**：A4 详细行程单，调用系统分享面板，支持中文字体
- **本地优先**：SQLite 持久化，关闭 app 数据不丢，无网络也能用

### 路线图

| 版本 | 内容 | 状态 |
|---|---|---|
| v1.0 | MVP：规划 + 预算 + 导出 | ✓ 已完成 |
| v1.5 | 协作：同行者 + AA 分摊 + 凭证 + 打包清单 | 进行中 |
| v2.0 | 留存：AI 引言 + 回忆录 + 终身足迹 + 年度报告 | 规划中 |

---

## 技术栈

| 层级 | 选型 |
|---|---|
| UI 框架 | Flutter 3.x · Material Design 3 |
| 状态管理 | Riverpod 2.6 |
| 本地数据库 | Drift (SQLite ORM) + 代码生成 |
| PDF 生成 | pdf + printing 包，纯客户端生成 |
| 国际化 | flutter_localizations + intl |
| 平台 | iOS · macOS · Android (后续) |

### 架构原则

- **本地优先（Local-First）**：所有写操作首先落地本地 SQLite，云端同步仅作为补充
- **响应式数据流**：通过 Riverpod 实现"数据变更自动传播到所有相关 widget"
- **Repository 模式**：业务模型（`models/`）与数据库行（Drift 生成）解耦，方便测试
- **反商业化**：无广告、无推荐位、无诱导付费，纯粹的工具属性

---

## 项目结构

```
lib/
├── data/
│   ├── database/           # Drift 数据库定义
│   ├── repositories/       # 数据访问层
│   └── app_data.dart       # 全局数据访问入口
├── models/                 # 业务模型（Trip, TripActivity, Expense）
├── providers/              # Riverpod Provider
├── pages/
│   ├── trip_list/          # 旅行列表页
│   ├── trip_create/        # 新建旅行
│   ├── trip_detail/        # 行程详情 + 时间轴
│   ├── activity_edit/      # 活动编辑
│   └── budget/             # 预算与记账
├── widgets/                # 可复用组件
├── theme/                  # 配色与样式
└── utils/                  # 工具函数（PDF 生成等）
```

---

## 本地运行

### 环境要求

- Flutter 3.x（[安装指南](https://docs.flutter.dev/get-started/install)）
- Xcode 26+（仅 iOS / macOS 调试）
- Dart 3.x

### 启动步骤

```bash
# 1. 克隆项目
git clone https://github.com/Dreamaker203/travel-companion.git
cd travel-companion

# 2. 安装依赖
flutter pub get

# 3. 生成 Drift 代码（首次必跑）
dart run build_runner build --delete-conflicting-outputs

# 4. 运行
flutter run -d macos  # 或 -d ios
```

---

## 设计哲学

### 一·先 collect 再 schedule

调研发现真实用户排行程的心智模型是 **"先确定玩什么 → 再决定哪天去玩"**。但圆周旅迹、路敢敢等竞品都强制先选日期才能加活动。本项目通过**待定池**功能（dayNumber=0 表示待定）支持这一真实流程。

### 二·组织者视角

竞品大多假设用户独自旅行或随便共享。本项目设计上区分**组织者**（你，规划全程）与**同行者**（朋友们，需要看懂你的安排）。导出 PDF 模板专为"发给队友"优化。

### 三·全生命周期

旅行不只是"去之前订票"，还包含**回来之后的留存**。规划数据天然就是回忆素材的最好原料——结构化、有时间、有地点、有花销。v2.0 将基于规划数据自动生成回忆录、足迹地图、年度报告。

---

## 开发故事

这个项目从 0 到 v1.0 MVP 的开发过程，浓缩了**完整的产品-工程闭环实践**：

1. **需求分析**：明确目标用户、使用场景、核心痛点
2. **竞品调研**：分析 5+ 款主流旅行 app 的强弱点，定位差异化
3. **UI/UX 设计**：高保真原型 + 设计系统
4. **技术选型**：Flutter + Drift + Riverpod 的取舍理由
5. **MVP 实现**：在严格的范围控制下完成核心闭环
6. **状态管理重构**：从 setState 升级到响应式数据流

---

## 作者

**Dreamaker** · 东北大学软件工程 · 2026 届

- 开发动机：解决自己作为旅行组织者的真实痛点
- 长期目标：作为秋招与 2027 年中国科学技术大学计算机研究生复试的代表项目

---

## 许可

MIT License