# Git Commands Examples

Graphical log

```sh
git log --oneline --graph --decorate -n 15 master develop

git log --graph --decorate --oneline --simplify-by-decoration \
  --branches=master --branches=develop --tags \
  --max-count=50

git log --graph --decorate --oneline \
  --branches=master --tags \
  --max-count=50
```
