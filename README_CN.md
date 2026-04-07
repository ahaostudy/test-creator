# test-creator

> 告别猜测，给你的项目一套专业级测试——用一句话搞定。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Language Agnostic](https://img.shields.io/badge/Language-Any-green.svg)]()
[![Framework Agnostic](https://img.shields.io/badge/Framework-Any-green.svg)]()

[English](README.md) | **中文**

---

test-creator 是一个 **skill**，为任何项目构建完整、专业的测试系统。它不修复你的代码——它精确告诉你哪里有问题、问题是什么。

支持 **任何语言、任何框架** —— Go、Python、Node.js、Java、Rust，随你用。

---

## 它能做什么

test-creator 给你的 AI 编码助手提供一套经过实战验证的测试方法论。它不是代码生成器，而是一个**思维框架** + 自动化质量工具，确保测试无死角。

### 6 项覆盖保证

每个测试类型必须通过 6 个强制检查点，没有捷径：

| | 检查点 | 为什么重要 |
|---|-------|----------|
| 1 | **基本效果** | 功能真的能用吗？ |
| 2 | **边界情况** | 空输入、最大值、特殊字符会怎样？ |
| 3 | **状态码验证** | 返回的 HTTP/业务码对不对，而不只是 200？ |
| 4 | **数据验证** | 数据库里真正存的是什么？直接查存储层，逐字段核对，而不是检查响应类型。 |
| 5 | **日志验证** | 关键操作有日志吗？敏感数据有没有泄漏到日志里？ |
| 6 | **异常处理** | 出错时会怎样？优雅降级还是直接崩？ |

### 4 种测试类型

按需选择，也可以全都要：

- **API 测试** —— CRUD、认证、分页、并发、幂等性
- **E2E 测试** —— 用户流程、表单、路由、异步状态
- **单元测试** —— 纯函数、数据转换、业务规则、状态机
- **集成测试** —— 数据库一致性、第三方服务、消息队列

### 双层质量保障

**第一层：自动化脚本** —— 覆盖率、稳定性（flaky 检测）、性能，三个维度一份报告。

**第二层：对抗性子代理审查** —— 独立 AI 从 6 个维度审查测试代码，找出脚本发现不了的问题：错误的断言、缺失的场景、不合理的 mock、差劲的测试数据。审查者的职责是**找问题，而不是夸你写得好**。

---

## 为什么选 test-creator？

| 老办法 | 用 test-creator |
|--------|----------------|
| 让 AI "写测试"然后听天由命 | 7 步结构化流程：深度分析 → 问答 → 测试计划 → 实现 → 验证 → 审查 → 修复 |
| 测试过了但漏掉真实 bug | 每个类型 6 个强制测试点，一个都不能少 |
| 数据验证 = 检查响应字段类型 | 数据验证 = 直接查存储层，逐字段核对 |
| 不知道测试套件到底好不好 | 多维质量报告（覆盖率 + 稳定性 + 性能） |
| 自己审查自己 | 对抗性子代理从 6 个角度审查 |
| 只能用一个框架 | 通过适配器系统支持任何语言/框架 |

---

## 支持的框架

自动检测，零配置：

- **JavaScript/TypeScript** —— Jest, Vitest
- **Python** —— pytest
- **Go** —— go test
- **Java** —— JUnit

没看到你用的框架？适配器系统可扩展——不到 50 行 shell 脚本就能加上。

---

## 安装

### Claude Code

```bash
curl -sSL https://raw.githubusercontent.com/ahaostudy/test-creator/main/scripts/install.sh | bash -s -- --tool claude-code
```

### Codex

```bash
curl -sSL https://raw.githubusercontent.com/ahaostudy/test-creator/main/scripts/install.sh | bash -s -- --tool codex
```

安装到 `~/.agents/skills/test-creator/`，使用 `/skills` 或 `$` 调用。

### OpenClaw

```bash
curl -sSL https://raw.githubusercontent.com/ahaostudy/test-creator/main/scripts/install.sh | bash -s -- --tool openclaw
```

安装到 `~/.openclaw/skills/test-creator/`。

### 手动安装 / 其他工具

```bash
curl -sSL https://raw.githubusercontent.com/ahaostudy/test-creator/main/scripts/install.sh | bash -s -- --tool generic --dir /your/target/dir
```

或者直接手动复制整个目录 —— 你需要 `SKILL.md` 以及同级的 `adapters/`、`scripts/`、`references/` 文件夹。

## 快速开始

### 1. 安装

选择上面适合你工具的安装命令。

### 2. 使用

让你的 AI 助手为项目生成测试：

> *"帮我给这个 Flask API 写测试"*
>
> *"我想给这个 Go 项目加集成测试"*
>
> *"给这个 React 应用写 E2E 测试"*

test-creator 会自动激活。

### 3. 交给它

AI 会：

1. 并行启动子代理，深度分析你的项目 —— 每个 API 接口（含参数/Header）、页面流程、数据模型、日志配置
2. 生成交互式问答页面，让你选择要覆盖的内容
3. 编写测试开发计划文档，确认后再开始写代码
4. 实现测试套件，所有文件统一放在 `tests/` 目录下
5. 通过 `run-all-checks.sh` 运行 3 个维度的自动化质量检查
6. 让子代理从 6 个角度审查测试
7. 输出质量报告，精确告诉你哪些通过、哪些失败、原因是什么

---

## License

[MIT](LICENSE)
