# Hypnagogia

2D twin-stick roguelike, planned and built with the BMAD Game Dev Studio method (`_bmad/`, outputs in `_bmad-output/`).

## Language

- **Conversation, design documents, BMAD artifacts (brief, GDD, stories…): French.**
- **Code: English** — identifiers, comments, file and folder names, log messages.
- **Commit messages: English**, following [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): description`.
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
  - Scope is optional (e.g. `feat(combat): add dash i-frames`); description in the imperative, lowercase, no trailing period.
  - Breaking changes: `!` after the type/scope, or a `BREAKING CHANGE:` footer.
- Player-facing text (dialogue, UI strings) is game content, not code: keep it in localization files, not hardcoded.
