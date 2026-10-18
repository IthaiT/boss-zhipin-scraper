---
name: boss-zhipin-scraper
description: 搜索 BOSS直聘职位，直接摘取岗位、公司、招聘者、职责要求等原文，仅导出用户确认的 32 个字段到 JSON 和 CSV。用于 zhipin.com 职位搜索和资料导出，不总结、改写或自动筛选岗位。
license: MIT
metadata:
  version: "2.5.0"
  author: eatmoreduck
  platforms: [macos, linux, windows]
  hermes:
    tags: [scraper, jobs, career, cdp, chrome, zhipin, boss直聘]
---

# BOSS直聘职位字段导出 v2.5.0

直接交付 JSON 和 CSV。岗位字段严格限定为以下 32 项，两种格式字段相同；文件顶层保留关键词、城市、总数和 `jobs` 数组这些搜索上下文。

```text
city title company salary
location experience_education_tags experience_requirement education_requirement
company_scale company_stage company_industry company_welfare
boss_title boss_active_status job_link job_description
job_responsibilities job_requirements skills work_address
recruiter_name company_full_name company_link company_description
graduation_time application_deadline days_per_week minimum_months
job_id captured_at capture_status capture_reason
```

## 提取规则

- 职位描述、职责、要求、公司介绍直接截取网站原文，保留段落内的文字、空格与换行，不让 AI 总结、改写或补写。
- `job_description` 保存完整职位描述区域正文。只有明确的职责/要求标题时才提取 `job_responsibilities`、`job_requirements`；没有标题或无法区分时留空，原文仍在 `job_description`。
- `skills` 使用列表接口原始技能数组，保留 `C` 等单字符标签；不使用详情页中混有页面文字的旧 `skill_tags`。
- `company` 是网站展示公司名，`company_full_name` 是详情中的工商全称；`recruiter_name` 来自招聘者姓名，不与公司名混淆。活跃状态优先采用详情页上的原始标记，如“刚刚活跃”。
- 详细地址、公司介绍、毕业时间、招聘截止日期从对应页面区域摘取；实习每周天数、最短时长从接口原始字段读取。没有提供的信息留空，技能缺失为 `[]`。
- 不在导出文件中保存 `raw_list`、`raw_detail`、`page_text`、重复别名、头像、Logo、跟踪参数或其他未列出的岗位字段。接口上下文和完整页面文字仅在抓取期间临时使用。
- 不设 JD 最低字数，不擅自抽样或添加薪资、学历、经验等筛选。指定范围内每个唯一岗位均有记录；失败和未处理也要保留，写明 `capture_status`、`capture_reason`。
- 不生成整理版、Markdown、报告、摘要或提示词；不运行旧 `job_summary.py`，不加 `--analysis`。

## 执行

先以当前 `SKILL.md` 的目录定位 `scripts/boss_cdp_raw.py` 绝对路径，优先使用该 skill 的 `.venv` Python；需要 Python 3.10+、`requests`、`websocket-client`。仅缺依赖时安装。

以下 `PYTHON`、`SCRIPT_PATH` 代表实际绝对路径：

```text
PYTHON SCRIPT_PATH --check --cdp-port 9222
```

只有 CDP 不通时运行 `--setup-chrome`，仅安装 Edge 时用 `--setup-edge`。用户在专用浏览器登录后重新检查。专用持久 profile 位于 `~/.boss-zhipin-scraper/chrome-profile`，复用其登录态，默认不复制主浏览器数据。

```text
PYTHON SCRIPT_PATH --keyword "嵌入式软件工程师" --city 深圳 --pages 3 --output "绝对路径/jobs.json"
```

默认同时生成 `jobs.json` 和 `jobs.csv`，列表和详情位于同一对文件。`--format json` 只生成 JSON；`--format csv` 生成二者，也是默认值。输出使用用户指定位置或当前工作区；脚本无参数默认目录为 `~/.boss-zhipin-scraper/job-result/`。

CSV 使用 UTF-8 BOM，所有 32 列固定存在；数组以 JSON 字符串保存，正文不截断。返回文件链接及岗位数、失败数即可。

每页依次读取列表、处理该页新岗位详情、更新累计 JSON/CSV，再加载下一页。CSV 采用完整快照原子替换，读取器需刷新或重新打开；Windows/Excel 锁文件时保留旧 CSV 和最新 `.csv.pending`，后续保存重试，结束后仍占用时可关闭读取器并将 pending 快照替换为 CSV。`--max-details` 按整个城市累计，重复岗位不重复抓详情。

## 状态与边界

- `success`：已取得职位描述；`partial`：只取得部分内容、未找到描述区域或遇到登录墙/人工验证；`failed`：缺链接、空页面或连接/提取失败；`not_attempted`：尚未处理或被显式限制、中断阻止。
- 列表被动捕获页面自身请求，通过滚动加载下一批，不注入同步 XHR。单次最多 10 批，保留现有请求间隔。
- 验证或登录墙出现时，先保存这 32 个字段与剩余岗位的状态，再停止，请用户人工处理，不绕过验证。
- `--max-details N` 只在用户明确限制或必要的开发测试时使用，未处理项仍保留；`--no-detail` 仅抓列表；`--detail-output` 可额外输出同样 32 字段的详情副本。
- `--allow-dom-fallback` 默认关闭，DOM 薪资可能受字体影响。`--copy-login-state` 仅在用户明确要求时使用；`--reset-chrome-profile` 会清除专用登录态，不用于普通重启。
- 抓取结束默认保留浏览器；用户要求关闭时可用 `--stop-chrome` / `--stop-edge`，仅影响专用 profile。
