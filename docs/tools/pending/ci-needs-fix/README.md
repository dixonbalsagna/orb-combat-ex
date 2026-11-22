# ci-needs-fix (park, Tools, 2026-11-22; URGENT: GitHub refused ci.yml on 12ed2ded, so no CI job ran)

**The error** (run 45058728995, from the run page's annotation; the API has no check runs for a refused file): `Invalid workflow file: .github/workflows/ci.yml#L1 (Line: 844, Col: 227): Job 'deploy' depends on unknown job 'net-b-4'.`

**The cause is mine.** My splitter inserted each new job into the `deploy` job's `needs:` list with a regex, `\bnet\b`. After the first patch the list ended `..., net, net-2, net-3, net-4, world, site`; the greedy match stopped at the "net" inside `net-4` (a word boundary sits before the hyphen) and put `, net-b` there. Line 844 read `..., godot-vfx-hash, net, net-2, net-3, net, net-b-4, world, site]`: `net` twice, `net-4` gone, `net-b-4` a job that does not exist. The workflow text was valid YAML, so `check-workflows` (which reads syntax) passed, and nothing checked that a `needs:` names a job. The same blind spot as 2026-11-06.

`ci-needs-fix.patch` (sha1 `c2d21523f4f8d5da8586c614031e347e903c1248`, three files, applies to 12ed2ded):

| File | Change |
| :--- | :--- |
| `.github/workflows/ci.yml` | line 844 only: `... godot-vfx-hash, net, net-b, net-2, net-3, net-4, world, site]` (the 21 jobs the deploy job waits for, each once; every one is a job of the file) |
| `tools/check-workflows.mjs` | a new `lintJobs`, run on every workflow file with a top-level `jobs:`: a `needs:` entry (inline list, a lone name or a block list) that names **no job of the file**, names the job itself, is **listed twice**, or closes a **cycle**; and a `matrix.` expression (in a name, a run or an `if:`) in a job with **no `strategy:`**. These are the things GitHub refuses at once although the text is fine YAML |
| `tools/check-workflows-selftest.mjs` | 11 new checks (28 in all, 17 before): the 2026-11-22 shape (`needs: [net, net-b, net, net-b-4]` is refused, naming the unknown job and the repeated one), a block list, a lone name (with its line number), a self-need, a cycle, matrix with and without a strategy, a text with no jobs, a comment that names a missing job, and the real ci.yml has no job problems |

## Checked

- **The new check refuses the file that GitHub refused**: run on 12ed2ded's ci.yml it reports line 844, `lists 'net' twice` and `depends on unknown job 'net-b-4'`; with the fix, `check-workflows ok: 13 files`. **Negative control for the self-test**: with the broken ci.yml put back, exactly the "real ci.yml has no job problems" check fails (1 of 28), and passes again with the fix.
- `check-workflow-shell` ok (284 run steps), `ci-budgets-check` ok on the fixed tree.

## Not proven

- GitHub has not read the fixed file: only a push does. I have no actionlint here (no dependencies in this repository); `lintJobs` covers the unknown-job, self, duplicate, cycle and matrix-without-strategy cases and not every rule GitHub applies (an expression that names a context that does not exist, for example). The world matrix, the quoted step names and the other new jobs were not the cause of this error, but the file as a whole is accepted only when GitHub says so.
