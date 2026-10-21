# Copilot instructions - Booking database project

This repository is a Redgate Flyway project for the Booking SQL Server database. The database is
changed through a controlled workflow. Follow these rules exactly; they are the guardrails.

## How changes flow

1. You edit the **schema-model** file directly (the source-controlled definition of each object).
2. The **Flyway MCP** generates the migration and undo scripts from that change. You do not write them.
3. The Flyway MCP code-reviews the new migration and test-runs it against the shadow database.
4. You summarise the result in the pull request for a human to approve.
5. After merge to `main`, the GitHub Actions pipeline deploys Build > Test > Production and produces
   the Flyway Check report (Test and Production).

## Flyway MCP tool sequence

Use exactly these tools, in this order. The project folder is the repository root (where `flyway.toml` is).

1. `load_project` - load the repository root; keep the returned `workspaceId`.
2. Edit the schema-model file (normal file edit, not an MCP tool).
3. `reload_project` - pick up your schema-model edit.
4. `create_diff_migrations` - diffs the schema model against the migrations using the shadow environment.
   Check the diff contains only the object you changed. If it contains anything else, stop and report it.
5. `generate_migrations` - pass the `migrationsDiffId` and `generateUndoScripts` set to true, with a short
   description that includes the BOOK ticket. Confirm both a `V` and a matching `U` script were created.
6. `review_code` - run it on the generated V script. Fix any violation by changing the schema-model and
   regenerating, or explain it in the PR.
7. `test_migrate` - must succeed against the shadow database. If the shadow database already contains a
   version you are about to generate (left over from an earlier attempt), call it with `rebuild` set to true.

Do NOT call `update_schema_model`, `update_development`, `create_diff_schema_model`,
`create_diff_development` or `create_schema_model_checkpoint`. They work against the development
database and are not part of this workflow.

## Project layout

| Path | What it is |
|------|------------|
| `schema-model/` | One .sql file per object. This is the ONLY place you edit database code. |
| `migrations/` | Versioned scripts (`V###__`), undo scripts (`U###__`), baseline (`B001`). |
| `flyway.toml` | Flyway project config and environments (shadow, Build, Test, Check, Production). |
| `.github/workflows/` | CI/CD pipeline. Do not change it as part of a database fix. |

## Rules

### Do
- Make the smallest change that fixes the issue. Edit only the schema-model file(s) the issue concerns.
- Keep object definitions in the existing style: `CREATE OR ALTER`, schema-qualified, bracketed names,
  `SET QUOTED_IDENTIFIER ON` / `SET ANSI_NULLS ON` header as in neighbouring files.
- Preserve existing behaviour and result-set shape (column names, types, order) unless the issue
  explicitly says otherwise. If you must change behaviour, call it out in the PR.
- Use the Flyway MCP tool sequence above to generate the migration (with a matching undo script), code
  review it and test-run it. Fix anything it flags, or explain in the PR why you did not.
- Keep the BOOK ticket reference in a comment at the top of any changed object.

### Do not
- Never hand-write or edit anything in `migrations/`. Existing migrations are immutable once merged.
- Never edit the schema-model and migrations to disagree with each other.
- Never run scripts against the `Production` environment. Use the shadow/Build/Check environments only.
- Never commit credentials, tokens, connection strings with passwords, or `.env` files. Secrets come
  from GitHub secrets or local environment variables.
- Never disable, skip or weaken Flyway checks to get a green result.
- Never add `SELECT *`, `NOLOCK` hints, or dynamic SQL built by string concatenation.

## Stored procedure performance fixes - checklist

When asked to speed up a query or procedure:
- Make predicates SARGable: no functions wrapped around indexed columns in `WHERE`/`JOIN`.
- Check which existing indexes can serve the query (see the table file in `schema-model/Tables/`).
  Prefer rewriting the query to use an existing index over adding a new one. If you believe a new
  index is needed, say so in the PR rather than adding it silently.
- Replace per-row correlated subqueries with set-based joins or window functions, but confirm the
  semantics are identical (for example, whether past rows are counted).
- Avoid aggregating a whole table in a view and then filtering it. Aggregate only the rows needed.
- Do not rely on the database collation being case-insensitive without checking it.

## Pull request summary

Write the PR description for a reviewer who has two minutes. Use this structure:

1. **What changed** - one or two sentences, plain language.
2. **Why it was slow / what the problem was** - the root cause.
3. **Behaviour check** - confirm results are unchanged, or list every difference.
4. **Generated scripts** - names of the V and U scripts the Flyway MCP produced.
5. **Validation results** - `test_migrate` against the shadow database: pass/fail. State plainly that the undo
   script was generated and code-reviewed but NOT executed, because no tool available to you can run it.
6. **Code review results** - the `review_code` findings, and how each was handled.
7. **Risk and rollback** - what could go wrong and how the undo script reverses it.
8. **Recommendation** - approve or needs discussion, and why.

Do not paste raw Flyway tool output into the description: the calling script appends a verified
"Flyway MCP evidence" section from the session record. Just summarise the results in your own words.
Report results exactly as the tools returned them. If something failed or was skipped, say so.
Do not use emoji.
