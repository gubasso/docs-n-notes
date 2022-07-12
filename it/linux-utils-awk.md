# Awk

```
awk '/foo/ {print $2}'
bug list 1 | awk -F ': ' '/Title/ {print $2}'
```

- `-F`: column delimiter
- `/Title/`: just line beggining with "Title"
- `{print $2}`: print just the second column

