# CLAUDE.md - Booking database project (Flyway)

This repository is a Redgate Flyway project for the Booking SQL Server database. It is used to demonstrate
safe, AI-assisted database development. Follow the workflow below exactly. The guardrails are the point.

(`.github/copilot-instructions.md` is a separate set of instructions for a GitHub Copilot workflow. It does not
apply to you. Do not edit it.)

## The workflow: develop in the Development database, then capture

The developer changes the Development database directly (using the VS Code SQL Server extension) and tests it
there. Your job, when asked, is to carry that change safely into version control:

1. **Find the change.** `load_project` (project folder = repository root), then `create_diff_schema_model`.
   This compares the Development database with the schema-model. List every difference to the developer.
2. **Confirm scope.** Only the object(s) the developer named should be captured. Other differences may be
   unrelated work. Report them and leave them out. Never pass `*` as the changes. Pass only the specific change IDs.
   Use `get_diff_details` to show the developer the exact before and after for each object being captured.
3. **Update the schema-model.** `update_schema_model` with only the chosen change IDs. This edits the
   `schema-model/` files for you.
4. **Generate the migration.** `reload_project`, then `create_diff_migrations`. The diff must contain only the
   object(s) you captured. If it contains anything else, stop and report it. Then `generate_migrations` with
   `generateUndoScripts` true and a short description that starts with the ticket number (for example `BOOK-215 ...`).
   Confirm both a `V` script and a matching `U` undo script were created.
5. **Review.** `review_code` on the new `V` script and on the `U` script. Report every finding. Do not suppress
   or work around a finding; if one needs a fix, tell the developer and let them decide.
6. **Test.** `test_migrate` against the shadow database. It must succeed. If the shadow already contains a version
   you are about to generate (left over from an earlier attempt), call it with `rebuild` set to true.
7. **Commit and push (only when asked).** Stage only `schema-model/` and `migrations/`. Commit with the ticket
   number in the message. Push to the branch the developer names. Never push to `main` unless the developer
   explicitly says so in the same message. Never force-push.

## Optional: extra confidence from Redgate Monitor

When the developer asks, use the Redgate Monitor MCP (server name `local`, read-only) to back up the change with
evidence. Typical questions: is the procedure among the top queries, what are its average duration and execution
count, and what does its query plan show (scan or seek)? Use the tools the server actually exposes (top queries,
query details, query plan). Rules:
- Ask which monitored server and database to use if it is not obvious. Do not guess.
- Quote real numbers from the tool results. Never estimate or invent a figure.
- Be clear about what Monitor measured and where. Monitor data shows what a monitored instance observed; it does
  not by itself prove the new Development version is faster. Say which database each number came from.

## Rules

### Do
- Keep the change as small as the developer's change. Do not "improve" the SQL while capturing it.
- Preserve the developer's code exactly. If you spot a problem or a behaviour change, tell them. Do not fix it
  silently.
- Report results exactly as the tools returned them, in a short plain summary: what was captured, the migration
  and undo script names, review findings, test result, and anything not verified.
- State plainly that no tool available to you executes the undo script. It is generated and code-reviewed only.

### Do not
- Never write or edit anything in `migrations/` yourself. Migrations come only from `generate_migrations`.
- Never edit `.github/workflows/`, `flyway.toml` or `Filter.scpf` as part of a database change.
- Never use `update_development`, `create_diff_development` or `create_schema_model_checkpoint`. They write to
  the Development database or are not part of this workflow.
- Never run anything against Test or Production. Deployment happens only through the GitHub Actions pipeline
  after the change is pushed.
- Never read or print `flyway.user.toml`. It contains database logins. Never put credentials, tokens or
  connection strings with passwords in any file, commit or message.
- Never `git add -A` or `git add .`.

## Project facts

| Path | What it is |
|------|------------|
| `schema-model/` | One .sql file per object. The source-controlled definition of the database. |
| `migrations/` | Versioned (`V###__`), undo (`U###__`) and baseline (`B001`) scripts. Immutable once merged. |
| `flyway.toml` | Project config and environments: development, shadow, Build, Check, Test, Production. |
| `.github/workflows/GitHub-Flyway-CICD-Pipeline.yml` | Deploys Build, Test, then Production, with Flyway Check reports. |

- Next migration version: look at `migrations/` for the highest existing `V` number. Do not guess it.
- This is a Windows machine. Use PowerShell syntax for any terminal commands, with a backtick for line continuation.
- Write in plain, direct language. No emoji.
