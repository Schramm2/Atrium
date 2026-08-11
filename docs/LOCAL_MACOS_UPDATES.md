# Local macOS Updates

This workflow builds the current checkout and replaces `/Applications/Notive.app`. It does not create a tag or publish a GitHub Release.

## Update the installed app

Quit Notive first so an active recording is not interrupted.

```bash
cd /path/to/notive
./scripts/update-local-macos.sh
```

The script:

1. Records the current branch, commit, version, and worktree status.
2. Builds the native Swift bundle and DMGs.
3. Verifies the nested ad-hoc code signature.
4. Replaces `/Applications/Notive.app` through a staged copy with rollback.
5. Registers the application with Launch Services.
6. Writes the installed-source receipt to `~/Library/Application Support/com.ubundi.meet/installed-build.txt`.

The local build includes uncommitted worktree changes. Review the printed list before installation.

## Data compatibility

The native application keeps bundle identifier `com.ubundi.meet` and uses the existing database beneath:

```text
~/Library/Application Support/com.ubundi.meet/
```

The installer does not move, rewrite, or delete application data.

## Verify the installed source

```bash
cat "$HOME/Library/Application Support/com.ubundi.meet/installed-build.txt"
git rev-parse HEAD
```

The receipt commit must match the intended checkout.
