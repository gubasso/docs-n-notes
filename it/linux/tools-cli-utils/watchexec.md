# cli: watchexec

## Examples

With `miniserve` to work as a dev serve with live reload (hot reload):

```sh
watchexec \
  --watch html \
  --restart \
  --debounce 100 \
  -- \
  miniserve html -i ism_content.html -p 8080
```

With `rsync`

```sh
watchexec 'rsync -vurzP --delete-after ./* user@host:/full/path/'
watchexec 'rsync -vurzP --delete-after ./* user@host:relative/path/from/user/home'
rsync -vrzP --delete-after ~/website/ user@host:/var/www/html/
```

Command with echo:

```sh
watchexec \
  -w package/python-kiwi-keg.spec \
  -- \
  'cp package/python-kiwi-keg.spec /home/gbasso/Projects/obs.g/home:gbasso:branches:Cloud:Tools/python-kiwi-keg \
   && echo "✅ Copied at $(date)"'
```
