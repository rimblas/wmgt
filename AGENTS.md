# Repository Guidelines

## Project Structure & Module Organization
This repository is primarily an Oracle APEX and PL/SQL application for WMGT, with a separate Discord bot service in `bots/`.

- `install/`, `packages/`, `views/`, `triggers/`, `sql/`, `data/`: database schema objects, seed data, and maintenance scripts.
- `apex/`: APEX exports and readable application YAML under `apex/readable/`.
- `tests/`, `unit_tests/`: SQL-based verification and performance tests.
- `bots/src/`: Node.js bot source; `bots/src/tests/` holds Vitest suites.
- `docs/`, `www/`, `reports/`, `ords/`: operational docs, static assets, reporting, and ORDS-related files.

## Build, Test, and Development Commands
Run commands from the repo root unless noted.

- `npm --prefix bots install`: install bot dependencies.
- `npm --prefix bots run dev`: run the Discord bot locally with file watching.
- `npm --prefix bots test`: run the bot’s dependency/setup check.
- `npm --prefix bots run test:vitest`: execute the full bot test suite.
- `npm --prefix bots run status`: check deployed bot status via the repo scripts.
- `sqlcl @tests/test_wmg_verification_engine.sql`: run PL/SQL verification tests in SQLcl.
- `sqlcl @tests/test_wmg_verification_performance.sql`: run performance-oriented database checks.

## Coding Style & Naming Conventions
PL/SQL objects use lowercase file names that match object names, such as `packages/wmg_util.pks` and `views/wmg_rounds_v.sql`. Keep SQL keywords lowercase or mixed as already present, align parameter lists vertically, and preserve the existing `p_`, `x_`, `g_`, and `e_` prefixes for parameters, out values, globals, and exceptions.

Bot code uses ES modules, 2-space indentation, `PascalCase` for classes, and `camelCase` for functions and variables. Match existing file naming such as `RegistrationService.js` and `votes.test.js`. No repo-wide formatter or linter is configured, so keep changes consistent with surrounding code.

## Testing Guidelines
Add or update SQL tests in `tests/` or `unit_tests/` when changing package logic, scoring, or verification behavior. Name new database tests `test_*.sql`. For bot changes, add Vitest coverage in `bots/src/tests/` with `*.test.js` filenames; property and integration tests already follow patterns like `*.property.test.js` and `*-integration.test.js`.

## Commit & Pull Request Guidelines
Recent commits use short, imperative subjects with optional context, for example `Improve UX for Registration button` and `Bug: Only show actively registered players in a room`. Follow that style: one-line summary, capitalized, focused on behavior.

Pull requests should describe the user-visible change, note affected areas (`APEX`, `PL/SQL`, `bot`), list test commands run, and include screenshots when UI pages or Discord responses change. Link the relevant issue or operational task when available.
