# The CI guards that do not depend on ci.yml (Tools, 2026-11-07)

Three small workflows, each its own file with its own job, so a broken or red `ci.yml` can never hide them. Corrective directive items CD-01, CD-19 and CD-27. Each saves what it proved under `docs/tools/runs/<sha>/` (CD-22).

| Workflow | When | What it does | Rules / code |
| :--- | :--- | :--- | :--- |
| `workflow-lint.yml` | every push and pull request | the lint's self-test, then `node tools/check-workflows.mjs` over `.github/workflows` and `.github/actions`: a file GitHub cannot parse (an unquoted `: ` in a step name) is red on the push that broke it, with the file and line | `tools/check-workflows.mjs`, `check-workflows-selftest.mjs` |
| `content-screen.yml` | every push and pull request | the screen's self-test, then `node tools/content-screen.mjs`: a user-profile path, a secret, a console SDK path, a franchise word in what ships (data, ui, render, sim, audio, net, art, the public pages), a gold-haired fighter file (Legal RL-014), and the public sentences that must not come back (README.md "We are fixing them" and "(official)"; "open source" in CLAUDE.md as a warning). Never prints a name or a secret in full | `tools/content-screen.mjs`, `content-screen.json`, `content-screen-selftest.mjs` |
| `player-watch.yml` | daily, and on demand | what players get: the live address's `/play/` against the repository's switch, the interim's end date and the nightly's age; a failure turns the run red (GitHub emails the owner about a failed scheduled run; the EP also reads `gh run list --workflow player-watch.yml`); it posts nothing publicly | `tools/player-watch.mjs`, `player-watch-selftest.mjs` |

## Run them by hand

```
node tools/check-workflows.mjs
node tools/content-screen.mjs
node tools/player-watch.mjs
```

To change a content rule, edit `tools/content-screen.json` (its words are Legal's lists: `docs/legal/never-use-words.md`; a new franchise word is Legal's to add).

## The shell inside the run steps parses (2026-11-14)

`node tools/check-workflow-shell.mjs` reads every `run:` of every workflow and action file (a block scalar or a one-line value), replaces each `${{ expression }}` with a placeholder and asks bash to parse the script (`bash -n`: it parses and runs nothing). A step with `shell: pwsh`, `powershell`, `cmd` or `python` is skipped. It is in the workflow lint (`workflow-lint.yml`), after the YAML lint, with a self-test of 11 checks that plants the bug that made it: desktop-builds run 43582095368 failed on a runner at "The commit being built" with `unexpected EOF while looking for matching '`, an apostrophe inside `${VAR:+...}` in a double-quoted echo. The YAML lint skips block scalars, so no check had parsed that script. What this does not catch: a script that parses and still fails when it runs (a missing file, a wrong flag, a command that does not exist on the runner).
