# Git QA

## Download changes to another branch

I am at master branch and run:
git fetch origin develop:develop

---

The command you ran (`git fetch origin develop:develop`) fetches the `develop` branch from the remote repository (in this case, `origin`) and updates (or creates) a local branch called `develop` to match the remote one.
Here’s a breakdown of the command:

- `git fetch`: Fetches changes from the remote repository without modifying your working directory or active branch.
- `origin`: Refers to the remote repository, which by default is often named `origin`.
- `develop:develop`: The syntax `remote_branch:local_branch`. This means you are fetching the `develop` branch from `origin` and updating or creating a local branch called `develop`.
Since you're currently on the `master` branch, this will not affect your current branch. The fetched branch (`develop`) will be available in your local repository but won't be checked out or merged into `master` unless you explicitly switch to `develop` or merge it.If you want to merge the `develop` branch into `master` after fetching, you could do:

```bash
git merge develop
```
Or, if you want to check out `develop`, you would do:

```bash
git checkout develop
```

## Get the diff from the start of a branch

To get the diff from the start of a branch in Git, you can use the following command:

```bash
git diff $(git merge-base --fork-point <branch_name>)..<branch_name>
```

Here's how it works:

1. `git merge-base --fork-point <branch_name>`: This finds the point where the branch diverged from its upstream (i.e., where the branch started).

2. `git diff <starting_point>..<branch_name>`: This command then shows the difference between the starting point (where the branch started) and the current state of the branch.

If you're already on the branch, you can simplify it to:


```bash
git diff $(git merge-base --fork-point HEAD)
```

This will show you all the changes from the start of the branch to your current working state.

Let me know if you need further clarification or assistance!

## Revert only one file to a past commit

To revert a single file to a previous commit in Git, follow these steps:

1. **Identify the commit**  you want to revert to:
You need to find the commit hash for the commit where the file was in the state you want to revert to. You can use:

```bash
git log -- [file_name]
```

This will show the history of that specific file, and you can find the commit hash from here.

2. **Checkout the file from the specific commit** :
Once you have the commit hash, you can checkout the file from that commit using:

```bash
git checkout [commit_hash] -- [file_name]
```

This command will replace your working directory's version of the file with the version from the specified commit. However, it won't automatically stage the file.

3. **Stage the file** :
If you want to commit this change, you'll need to stage it:

```bash
git add [file_name]
```

4. **Commit the change** :
Finally, commit the change to the file:

```bash
git commit -m "Revert [file_name] to a previous version from [commit_hash]"
```

### Summary of Commands:


```bash
git log -- [file_name]
git checkout [commit_hash] -- [file_name]
git add [file_name]
git commit -m "Revert [file_name] to a previous version from [commit_hash]"
```


## how do I git commit without running pre-commit hook

If you want to skip the `pre-commit` hook when making a Git commit, you can bypass the `pre-commit` hooks using the `--no-verify` option.To commit without running `pre-commit` hooks:

```bash
git commit --no-verify -m "Your commit message"
```

### Explanation:

- The `--no-verify` option tells Git to skip all the verification hooks, including `pre-commit`, `pre-push`, and others, allowing you to commit without triggering any of the hooks.

This is useful when you know that the changes are okay, or you're temporarily bypassing the checks (e.g., fixing them later or in case of urgency).

### Example:


```bash
git add file.txt
git commit --no-verify -m "Commit without running pre-commit hooks"
```
This will bypass the `pre-commit` hooks and allow the commit to proceed.
