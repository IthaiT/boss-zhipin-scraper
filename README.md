# BOSS直聘职位字段导出工具 v2.5.0

> 本仓库是 [IthaiT/boss-zhipin-scraper](https://github.com/IthaiT/boss-zhipin-scraper) 的个人定制版，基于 [eatmoreduck/boss-zhipin-scraper](https://github.com/eatmoreduck/boss-zhipin-scraper)。`2.5.0` 是本定制版的版本号，不代表上游官方发布。原项目作者与 MIT 许可证保持不变。

直接克隆本仓库，默认 `master` 分支即为定制版：

```bash
git clone https://github.com/IthaiT/boss-zhipin-scraper.git
cd boss-zhipin-scraper
```

仅将用户确认的 32 个岗位字段导出为 JSON 和 CSV。职位描述、职责、要求、公司介绍直接摘取原文，不做 AI 改写；缺失内容留空，技能保留原始数组。

## 使用

```bash
python scripts/boss_cdp_raw.py --check
# 仅在 CDP 不通时启动；Edge 使用 --setup-edge
python scripts/boss_cdp_raw.py --setup-chrome
python scripts/boss_cdp_raw.py --keyword "嵌入式软件工程师" --city 深圳 --pages 3 --output jobs.json
```

需要 Python 3.10+、`requests`、`websocket-client`。默认生成 `jobs.json` 和 `jobs.csv`，每条岗位的字段相同且仅有 32 个。JSON 顶层保留关键词、城市、总数和 `jobs` 数组。`--format json` 仅保存 JSON；`--detail-output` 是可选的同字段详情副本。

## 字段

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

技能来自列表接口；详细地址、工商全称、公司介绍、毕业要求、招聘截止日期和招聘者活跃状态从详情对应区域提取。职责、要求仅在有明确标题时拆分；无法区分时留空，完整内容仍在职位描述中。原文字段内部的空格、换行保持不变。

输出不保存原始接口包、整页文字、重复别名、头像、Logo、跟踪参数及其他未选岗位字段；浏览器上下文仅临时用于采集。每个岗位均保留，失败或未处理也有记录。状态为 `success`、`partial`、`failed`、`not_attempted`，并附原因。

CSV 使用 UTF-8 BOM，技能数组以 JSON 字符串保存。默认不运行旧 `job_summary.py`、统计、摘要或提示词生成，不读取本地简历文件。

采集按页进行：读取一页列表 → 处理该页新岗位的详情 → 更新累计 JSON/CSV → 再加载下一页。每页完成即可重新读取同一个 CSV 查看完整详情；`--no-detail` 每页更新列表，`--max-details` 在整个城市内累计计数，重复岗位不重复访问详情。

CSV 先写完整快照，再原子替换，读取时不会看到半截文件；已打开的读取器可能仍持有上一版，需要重新打开或刷新。若 Windows/Excel 锁住目标文件，会保留原 CSV，并将最新完整数据保存为 `jobs.csv.pending`，后续每次保存自动重试。若结束时仍被占用，关闭占用程序后将 `.pending` 文件替换为原 CSV。

专用持久 profile 位于 `~/.boss-zhipin-scraper/chrome-profile`，默认不复制主浏览器数据。仅用户明确要求时使用 `--copy-login-state`；`--reset-chrome-profile` 清除专用登录态，`--stop-chrome` / `--stop-edge` 仅关闭专用 profile。默认结果目录为 `~/.boss-zhipin-scraper/job-result/`。

单次最多 10 批，保留请求间隔。人工验证和登录墙出现时，保存选定字段及剩余任务状态后停止。`--no-detail` 只取列表；显式 `--max-details N` 的超出部分仍在文件中标记未处理。

```bash
python -m unittest tests.test_chrome_setup tests.test_job_summary
python scripts/boss_cdp_raw.py --smoke-test
```
