# Contribute to Atrium

Atrium is an internal macOS product for Ubundi and First Motive.

## Workflow

1. Start from the current `main` branch.
2. Create a focused `feat/<name>` or `fix/<name>` branch.
3. Make the smallest change that solves the task.
4. Run the native test suite.
5. Open a pull request to `main` and state the verification result.

Do not change the bundle identifier, local database path, stored meeting format, private release boundary, or external-data confirmation boundary without an accepted architecture decision.

## Verify

```bash
cd macos
swift test -Xswiftc -warnings-as-errors
```

For bundle, resource, permission, or startup changes, also run:

```bash
./script/build_and_run.sh --verify
```

For packaging or release changes, run the checks in [docs/RELEASING.md](docs/RELEASING.md).

## Style

- Follow the surrounding Swift and SwiftUI code.
- Prefer Apple system frameworks and the authenticated GitHub CLI update path.
- Keep recording, transcription, storage, retrieval, citations, and default answer generation on the Mac.
- Add tests for changed behavior.
- Update documentation when a command, boundary, or user workflow changes.

Keep [LICENSE.md](LICENSE.md) and [NOTICE.md](NOTICE.md) with distributed source and substantial copies.
