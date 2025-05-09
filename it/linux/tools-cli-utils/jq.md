# jq

- `jq` alternative written in rust: https://github.com/01mf02/jaq

https://jqplay.org/
https://programminghistorian.org/en/lessons/json-and-jq

## Examples

Filter/select a subset of fields from an object: https://stackoverflow.com/a/68664471


```sh
curl "https://api.airtable.com/v0/${airtable_base_id}/${airtable_table_variaveis}?maxRecords=3&view=Grid%20view" \
-H "Authorization: Bearer ${AIRTABLE_API_KEY}" \
| jq -c "[.records[] | {id, fields}]"
```

```sh
$ cat file.json | jq -c '.users[] | {first}'
{"first":"Stevie"}
{"first":"Michael"}
```

```sh
# list all keys
jq 'keys' input.json

# print data from a set of keys
jq '{key1, key2}' input.json

# from each first level keys, print unique second level keys
jq 'map(keys) | add | unique' input.json

jq '[.[]?.my_key[]?]    # gather every non-null my_key list into one big array
   | sort                # sort the whole array
   | unique              # remove duplicates (requires sorted input)
' input.json
```

Loop over an array of strings

```sh
#!/usr/bin/env bash
set -euo pipefail

items=(
  "alibaba"
  "aws"
  "azure"
  "gcp"
)

for item in "${items[@]}"; do
  echo "=== $item ==="
  jq --arg "$item"'
    [.[]?.[$key][]?] | sort | unique
  ' input.json
done
```
