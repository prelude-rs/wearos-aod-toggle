## Context lifecycle (when to clear/compact)

Part of the `spec-layout` skill — read when deciding when to clear or compact.

Because **authority lives in the artifacts** (the change folder + `SOURCE-OF-TRUTH.md` in git) and not in the conversation, **the conversation is disposable** — clearing it never loses execution state, as long as you clear at the right boundary.

- **Persist the orchestrator *within* a change** (the thread that walks discuss → spec → design (+ decomposição) → ledger → … → sign-off): it carries the human decisions and continuity you don't want to re-explain.
- **Run heavy/independent work in *fresh* subagents** — `consistency-gate`, `validation-gate`, the autonomous TDD executor, codebase mapping. This is what keeps the orchestrator's context from growing unboundedly: the token-heavy work and its tool output stay out of the main thread. (The gate skills already mandate fresh context for independence — context economy is the bonus.)
- **A change is a session.** Clear (`/clear`) **between** changes; the next change starts from its committed folder. The sizing by kind (rule 2) keeps a single change to one deliverable ending in one green state, small enough that one session's context stays manageable — scope control *is* the first line of context control.
- **Safe clear/compact points = committed gate boundaries:** spec Approved, design Approved (plan included, `check-tasks.sh` green) + consistency-report written, ledger generated (`check-tasks.sh --ledger`), executor finished (commits on the branch), evidence written, archived. At each, the artifact + git history **are** the handoff. **Never clear mid-phase** (mid-interrogation, mid-implementation) — that's the only place live state isn't yet in a file.
- **Resume contract:** a fresh session can pick up any change from `specs/proposed/<change-id>/*` (still being discussed) or `specs/active/<change-id>/*` (in implementation) + `git log` + `SOURCE-OF-TRUTH.md`/the epic (+ the project's persistent memory for cross-session facts). If those reconstruct where you are, clearing was safe.
