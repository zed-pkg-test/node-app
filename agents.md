# Agent policy

This repository is a deterministic zed-pkg interoperability fixture, not a production application.

Automated contributors should preserve the minimal package graph, deterministic behavior, and the distinction between npm-owned dependencies and the dependency sourced through Zed. Do not add deployment infrastructure, production credentials, network-dependent test data, or unrelated framework dependencies merely to make the fixture look like an application.

Changes to install behavior must exercise the shared Zed conformance contract: local mode may use symlinks; Docker/OCI installs must be self-contained copies; checksum/provenance failures must fail closed; and tests should use deterministic assertions rather than sleep-based timing.

Before changing dependency identity, repository ownership, install paths, or lock data, verify downstream consumers and retain graph history. Repository transfers or renames must preserve package identity until all consumers have been repointed.

Security and credential reports inherit the `zed-pkg-test` organization security/contact policy. Never commit secrets, access tokens, private keys, production data, or credentials to this fixture. If a vulnerability report contains sensitive material, use the organization’s private reporting/contact path rather than a public issue.
