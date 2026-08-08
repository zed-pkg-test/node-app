# node-app

`node-app` is a deterministic interoperability fixture for **zed-pkg**. It is not a production application and is intentionally small so CI can prove mixed package-manager behavior without unrelated runtime dependencies.

## Package graph

The fixture keeps ordinary JavaScript dependencies under npm while sourcing `zed-pkg-test/node-lib` through Zed:

```text
node-app
└── zed-pkg-test/node-lib ^1.0.0   (Zed)
```

`.zpkg.toml` installs Zed-managed dependencies beneath `.vendor/.zed`; the Node adapter exposes them at the expected `node_modules/@org/name` path and records the Zed node path under `.zed/node_path`.

## Deterministic inputs and outputs

Inputs are the tracked `.zpkg.toml`, the package metadata in `package.json`, the exact dependency resolution captured by the Zed lockfile when present, and the source under `src/`. A conforming install must resolve only the declared `zed-pkg-test/node-lib` dependency through Zed and leave npm ownership of unrelated dependencies unchanged.

The consuming assertion is the repository CI/check path: install according to the fixture mode, run `npm run check`, and run the application assertion that imports the Zed-provided library. A clean checkout must produce the same package graph and observable output for the same pinned inputs.

## Install-mode expectations

- **Local developer mode:** symlink semantics are allowed and preferred where Zed's local mode supports them.
- **Docker/OCI mode:** installed package content must use copy semantics. A container fixture must not depend on host symlinks, hardlinks, or files outside the declared install root.
- **Filesystem boundary:** removing the source/cache after a copy-mode install must not break the installed fixture.
- **Integrity:** checksum/provenance validation must fail closed when resolved content differs from the lock/registry metadata.

These expectations are conformance assertions, not deployment guidance. Copy/symlink/OCI canary implementation is shared with the portfolio work tracked by DEN-588 and DEN-591 rather than duplicated here.

## Expected failures

CI should fail with an actionable, platform-neutral diagnostic when the Zed dependency cannot be resolved, its checksum/provenance does not match, the Node adapter cannot expose the package, or a copy-mode install escapes its filesystem boundary. Tests must not depend on timing-sensitive behavior.

## Ownership and security

The canonical owner is the `zed-pkg-test` GitHub organization. This repository exists only as a test fixture for Zed consumers. See `agents.md` for automation rules. Security reports and credential disclosures should follow the organization-level security/contact policy; do not open public issues containing secrets.
