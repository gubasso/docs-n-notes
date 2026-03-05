# Make `origin` Match Your Local Branch State

## Update your view of `origin` first

```bash
git fetch --prune origin
```

## See local branches

```bash
git branch
# or more detail (upstream + last commit)
git branch -vv
```

## See remote branches (`origin/*`)

```bash
git branch -r
# or only origin
git branch -r | grep '^  origin/'
```

## See all branches (local + remote)

```bash
git branch -a
```

## Compare branch lists (local vs origin)

```bash
# Local branch names
git for-each-ref --format='%(refname:short)' refs/heads | sort

# Origin branch names
git for-each-ref --format='%(refname:short)' refs/remotes/origin | sort
```

## Check which local branches track an upstream (and what)

```bash
git branch -vv
```

## See ahead/behind vs upstream for all local branches

```bash
git for-each-ref --format='%(refname:short) %(upstream:short) %(upstream:track)' refs/heads
```

## Check one branch: local vs origin

```bash
# Show commit difference summary
git rev-list --left-right --count HEAD...origin/BRANCH

# Show actual commits that differ
git log --oneline --left-right HEAD...origin/BRANCH
```

## See what would be pushed (from current branch)

```bash
git status -sb
git log --oneline --decorate --graph --left-right @{u}...HEAD
```

## See what would change on push (dry run)

```bash
git push --dry-run
```
