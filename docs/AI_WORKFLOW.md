# AI development workflow

## Normal path

1. Create or select a GitHub issue. Put the goal, constraints, acceptance criteria, and risk in it.
2. Run `python scripts/route_task.py "<issue summary>"`. Paste its JSON into the issue or PR.
3. Follow its role stack. The planning role writes a short plan; Codex implements on a branch; Claude independently reviews when required.
4. Open a PR that links the issue, includes the routing decision, and reports tests. CI is evidence, not permission to merge.
5. Resolve review comments. A human explicitly approves and merges. The router never auto-merges.

## Role stacks

| Work | Stack |
| --- | --- |
| Small UI tweak | Codex |
| Unclear bug | GPT-5.6 Sol diagnosis → Codex fix → Claude review |
| Major architecture | GPT-5.6 Sol plan → Claude critique → GPT-5.6 Sol resolution → Codex implementation → Claude PR review |
| Documentation cleanup | fast utility model |

`config/router.json` is the single policy file. Change its role model names, keyword categories, stacks, and review rules; no code change is needed for policy edits. The router is deliberately deterministic and offline. Later automation may call a model to classify ambiguous work, but the saved routing decision remains reviewable in GitHub.

## Optional provider automation

The included CI only validates policy and tests. Do not enable a model-call workflow until repository/org secrets exist. Store credentials only as GitHub Actions secrets (for example `OPENAI_API_KEY` and `ANTHROPIC_API_KEY`), never in the repository. A future central `AI-Dev-Workflows` repository can expose `workflow_call` workflows; individual projects then call a pinned version and keep only their local policy/configuration.
