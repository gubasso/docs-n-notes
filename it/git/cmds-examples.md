# Git Commands Examples

Graphical log

```sh
git log --oneline --graph --decorate -n 15 main develop

git log --graph --decorate --oneline --simplify-by-decoration \
  --branches=main --branches=develop --tags \
  --max-count=50

git log --graph --decorate --oneline \
  --branches=main --tags \
  --max-count=50
```
