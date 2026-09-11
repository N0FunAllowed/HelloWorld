# AI development rules

GitHub is the record of work: begin from an issue, work on a `feature/`, `fix/`, or `docs/` branch, and open a pull request. Never commit directly to `master` and never merge a pull request without the user's explicit approval.

Before editing, run `python scripts/route_task.py "<task>"` and record the decision in the issue or PR. Follow `docs/AI_WORKFLOW.md`. Keep changes small, run relevant tests, and state what was and was not tested in the PR.

Codex is the implementation agent. Escalate product, scope, or architecture choices to the planning role; obtain the independent review specified by `config/router.json` before merging. Do not put tokens, API keys, or private data in code, issues, PRs, or logs.
