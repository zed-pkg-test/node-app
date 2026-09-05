# Agent policy

This repository is a deterministic zed-pkg interoperability fixture, not a production application.

Automated contributors should preserve the minimal package graph, deterministic behavior, and the distinction between npm-owned dependencies and the dependency sourced through Zed. Do not add deployment infrastructure, production credentials, network-dependent test data, or unrelated framework dependencies merely to make the fixture look like an application.

Changes to install behavior must exercise the shared Zed conformance contract: local mode may use symlinks; Docker/OCI installs must be self-contained copies; checksum/provenance failures must fail closed; and tests should use deterministic assertions rather than sleep-based timing.

Before changing dependency identity, repository ownership, install paths, or lock data, verify downstream consumers and retain graph history. Repository transfers or renames must preserve package identity until all consumers have been repointed.

Security and credential reports inherit the `zed-pkg-test` organization security/contact policy. Never commit secrets, access tokens, private keys, production data, or credentials to this fixture. If a vulnerability report contains sensitive material, use the organization’s private reporting/contact path rather than a public issue.

## Repository-local Git worktrees

- Create or use a Git worktree only when the human operator explicitly authorizes it for the current task. Concurrency or a dirty checkout is not permission by itself.
- Put every authorized worktree at `<repository-root>/tmp/worktrees/<name>`; from the repository root, use `./tmp/worktrees/<name>`. Never place worktrees beside repositories or organization directories.
- Keep `tmp`, `temp`, `tmp/worktrees`, and `temp/worktrees` ignored in the repository-root `.gitignore`. Do not commit files from those directories.
- Relocate or remove a worktree only when the operator explicitly requests it. Before removal, preserve and publish intended changes, verify its commit is represented on the target branch, and confirm there are no tracked, untracked, ignored-sensitive, or in-use files that must survive. Remove it with `git worktree remove <path>` without `--force`; never delete a worktree directory with `rm`.
