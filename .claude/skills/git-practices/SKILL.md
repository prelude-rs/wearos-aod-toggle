---
name: git-practices
description: MANDATORY company git conventions for this repository. Consult before EVERY commit, branch creation, merge, or PR — no exceptions, even for one-line changes, even when the user says "just commit it" / "só commita".
---

# Git Practices (Sellers)

**These conventions are mandatory. Announce you are following `git-practices` before your first git write operation in a session.** The hard rules below are also enforced by hooks — violating them will block the operation, so get them right the first time.

> Harvested from the Sellers `team-git` standard (shared near-verbatim across the `/team`-family repos) plus `datalake-api/docs/git-workflow.md`. The two SDD-kit additions over that standard are marked **(SDD)**: change-id traceability in commits/PRs, and the validation-gate readiness rule. Source of truth for any project-local CI commands stays in the project (e.g. a `team-task-verify` skill or `docs/git-workflow.md`).

## Branch model

| Branch | Purpose |
|--------|---------|
| `main` | Produção — código estável e deployado |
| `dev`  | Desenvolvimento — integração contínua de features |

Never commit directly to `dev` or `main`. All code enters via Pull Request to `dev` — hotfixes included; release, promotion and hotfix: `spec-layout` → "Changelog de release".

### Work branches

Format: `<type>/<user>/<short-description>` — e.g. `feat/ricardo/jwt-tenant-scope`.

| Type | When |
|------|------|
| `feat`  | New feature or endpoint |
| `fix`   | Bug fix |
| `refact` | Refactor without behavior change |
| `docs`  | Documentation only |
| `test`  | Test additions or fixes |
| `chore` | Dependencies, CI, tooling |

When the work implements an active SDD change, use the change-id as the description so branch ↔ spec is obvious: `feat/ricardo/2026-06-jwt-keycloak`. **(SDD)**

### Creating a branch

```bash
git checkout dev
git pull origin dev

# Prune local branches whose PRs were already merged.
# Uses `gh` because GitHub squash-merges create new commits that `git branch --merged` can't detect.
for branch in $(git branch | grep -v -E '^\*|dev|main' | sed 's/^ *//'); do
  if gh pr list --state merged --head "$branch" --json number --jq '.[0].number' 2>/dev/null | grep -q .; then
    git branch -D "$branch"
  fi
done

git checkout -b <type>/<user>/<description>
```

Always branch from an up-to-date `dev` (the one exception, the promotion branch: `spec-layout` → "Changelog de release"). Prune merged branches on every branch creation to keep the local tree clean.

## Commits

- Mensagens em **português**, claras e descritivas, prefixadas pelo tipo. Subject ≤ 72 chars, no modo imperativo, one logical change per commit (tests in the same commit as the code they verify).

  ```
  feat: adiciona filtro por tenant no endpoint de fatos
  fix: trata JWT sem active_org no middleware de auth
  refactor: extrai subdomínio do modelo de permissões
  docs: documenta o git workflow
  test: cobre enumeração de domínios no endpoint
  chore: atualiza dependências
  ```

- **(SDD)** For `feat`/`fix`/`refact` commits, reference the change-id and the requirement IDs the commit serves in the body: `Refs: 2026-06-jwt-keycloak R3, R4`. This is what lets the validation-gate walk commits back to requirements.
- Attribution trailer: keep the `Co-Authored-By` Claude trailer.

## Pull requests

1. **Target `dev`** (release, promotion and hotfix: `spec-layout` → "Changelog de release"). Never push directly to `dev`/`main`.
2. **Run the pre-PR local check first** — `task-verify` at the level for the target branch (**L2** for `dev`, **L3** for `main`). Concrete commands are project-local (recorded in `task-verify`); at minimum the project's lint, test, and build/type-check.
3. **CI must pass + review before merge.** Merge strategy: squash or merge commit (via GitHub).
4. **(SDD) A PR delivers one *or more* changes — the gate is per change, the PR is the delivery vehicle.** A PR is not "ready for review" until **every** change it carries has `validation-gate` verdict COMPLETE (or its INCOMPLETE items explicitly listed as known gaps). `verify-archived-gates` iterates over every archive folder in the PR's diff and checks each independently, so batching never relaxes a gate.
   - **Single change:** title mirrors the change-id and spec.md title; description links `specs/active/<change-id>/` and pastes the `evidence.md` verdict table.
   - **Batch (N changes):** title names the batch and its epic (e.g. `Lote 004-A — épico harvest-mattpocock`). The description **opens with one table row per change** — change-id · what it delivers in one sentence · verdict · link to the archived `evidence.md` — and pushes per-change detail behind `<details>`. **Batch only changes that are independent of each other**; a change that fails its gate simply does not join the batch. Precedent: PR #27 promoted C5–C10 (6 changes) in one PR.
   - **Why batch:** review is a scarce human resource. Squeezing N gated changes into one PR cuts review count without touching a single gate — the same reason `dev → main` promotions have always been batched.
   - **What batching costs, accepted deliberately:** the whole PR blocks on its weakest change; `git revert` of the merge undoes all of it (surgical revert stays possible **only** because of `Refs:` — see point 5, which becomes load-bearing under batching); and the first change waits for the last.
5. **(SDD) Squash-merge must preserve the change link.** The `commit-msg` hook does **not** run on a GitHub-side squash (the message is composed server-side at merge), so the *convention* — not the hook — guarantees traceability: the squash commit must carry **`Refs: <change-id>`** in its subject/body so `dev` history links back to `specs/archive/<change-id>/`. Either keep the repo's squash setting on **"concatenate commit messages"** (each task commit already carries `Refs:`), or put `Refs: <change-id>` in the PR description. (The kit's real traceability lives in the archived artifacts + `SOURCE-OF-TRUTH.md`, which survive any merge strategy; squash only collapses per-task commit boundaries in `dev`'s linear history — recoverable via the PR's Commits tab.)

**(SDD) Via rápida (fast lane) PR.** A `Mode: fast` change has no `spec.md`/`design.md`/`evidence.md` —
its single `change.md` is the record (see `spec-layout` → "Via rápida"). At the PR, do the *retroactive
registration*: fill `change.md` (what changed / why / the **task-verify L2** commands + results), flip
its `Verdict:` to `COMPLETE`, rewrite the declared SoT sections (`spec-layout` rule 5(b)), append a CHANGELOG row with
**`epic = fast`** and the release-changelog item — or, for the release change, the declaration of its seq (`spec-layout` → "Changelog de release") — and `git mv` the folder to `specs/archive/`. Branch + PR + **L2** are still required
(only the artifact is leaner). For point 4, the PR-readiness bar is the filled `change.md` with
`Verdict: COMPLETE` (there is no `evidence.md` to paste).

### PR flow

```
1. git checkout dev && git pull
2. git checkout -b <type>/<user>/<description>
3. Desenvolva, commite com mensagens claras (Refs: <change-id> nos commits de feat/fix)
4. Rode lint + test + build localmente
5. git push -u origin <branch>
6. Abra PR para dev no GitHub
7. Aguarde CI passar + review
8. Se `dev` avançou e o branch ficou desatualizado, atualize antes do merge (passo 9)
9. Merge via GitHub (squash ou merge commit)
```

6. **Keep the branch up-to-date with `dev` before merge.** Keep it current with its base even where the org ruleset does not demand it (measured 2026-09-30: "require branches to be up to date" is off on the kit's and bko's `dev` and `main`, so GitHub will not block the merge for it); if `dev` advanced (another PR merged), update before merging. Update it: `git fetch origin && git rebase origin/dev` (or merge `dev` in), resolve any conflicts locally, then re-push. Rebasing a pushed feature branch needs `git push --force-with-lease` — that is **fine for your own unmerged review branch** (see Never: the no-force-push rule is about *shared* branches like `dev`/`main`, not your feature branch).

### Batch PR body — the shape (point 4)

The reviewer is the scarce resource. **Lead with the table; hide the rest.** A reviewer must be able to
approve after reading ~6 lines, and drill into only what bothers them.

```markdown
> **PR em lote.** Entrega N changes do épico <link>, cada uma com `consistency-report.md`
> (`Verdict: PASS`) e `evidence.md` (`Verdict: COMPLETE`) arquivados. `verify-archived-gates`
> checa cada uma independentemente — o gate é por change, a PR é o veículo.

| # | Change | Entrega | Veredito | Evidence |
|---|--------|---------|----------|----------|
| 1 | <change-id> | <uma frase> | COMPLETE · consistency PASS | <link p/ o evidence arquivado> |

**Ganhos medidos:** <números antes → depois>
**Preservação:** <o que foi provado intacto>
**CI:** <estado>

<details><summary>Detalhe da change N — o que os gates pegaram</summary> … </details>
<details><summary>Verificação</summary> … </details>
<details><summary>Sai daqui para o épico (rule 5(d))</summary> … </details>

Refs: <change-id-1>, <change-id-2>, …
```

Rules for the body: **numbers, not adjectives** (a gain without a before→after pair does not go in the
table); one `<details>` per change, never one giant block; and a `Refs:` line naming **every** change in
the batch, which is what makes a surgical revert possible.

## Never

- Never push secrets, credentials, `.env` files, or fixtures with real client/tenant names.
- Never force-push **shared** branches (`dev`, `main`, anything others build on). Force-pushing your **own unmerged feature branch** to rebase/update it is fine (use `--force-with-lease`). Never amend a commit that has been pushed **and already reviewed/approved**.
- Never bypass hooks (`--no-verify`). If a hook blocks you wrongly, stop and tell the human; do not route around it.
