---
description: Create a git tag and GitHub release together. Usage: /release [version]
---

# Release Command

Create a git tag and GitHub release in one step.

## What This Command Does

1. **Determine version** - Use provided version or auto-increment from latest tag
2. **Create git tag** - Tag current HEAD
3. **Push tag** - Push tag to remote
4. **Create GitHub Release** - Create release with auto-generated notes via `gh`

## Usage

```
/release          # Auto-increment patch version from latest tag
/release v0.2.0   # Specify exact version
```

## Steps

### 1. Check latest tag

```bash
git tag --sort=-version:refname | head -1
```

### 2. Determine next version

If no version argument provided, auto-increment the patch number:
- `v0.1.27` → `v0.1.28`
- `v1.2.3` → `v1.2.4`

If a version argument is provided, use it as-is.

### 3. Confirm with user

Show the version to be created and ask for confirmation before proceeding.

### 4. Create and push tag

```bash
git tag <version>
git push origin <version>
```

### 5. Create GitHub Release

```bash
gh release create <version> --title "<version>" --generate-notes
```

`--generate-notes` automatically generates release notes from commits since the previous tag.

### 6. Display result

Show the release URL.

## Example

```
User: /release

Agent:
Latest tag: v0.1.27
Next version: v0.1.28

Create release v0.1.28? (yes/no): yes

✓ Tag v0.1.28 created
✓ Tag pushed to origin
✓ GitHub Release created

https://github.com/gudegithub/border-commerce/releases/tag/v0.1.28
```

```
User: /release v0.2.0

Agent:
Creating release v0.2.0...

Create release v0.2.0? (yes/no): yes

✓ Tag v0.2.0 created
✓ Tag pushed to origin
✓ GitHub Release created

https://github.com/gudegithub/border-commerce/releases/tag/v0.2.0
```

## Safety Checks

- **Confirm before acting**: Always ask for confirmation before creating tag/release
- **Tag already exists**: Warn and abort if the tag already exists
- **Dirty working tree**: Warn if there are uncommitted changes (but allow proceeding)

## Required Tools

- **Git**: Tag creation and push
- **GitHub CLI (`gh`)**: Release creation
