# public-cloud-info-client pint suse

- https://pint.suse.com/

## Basic usage

List all amazon images active.

```sh
pint amazon images --active --json
```

Other examples:

```sh
pint amazon images --active --json --filter="name~sles-,name~byos,name~sap,name\!arm64,name\!manager,name\!openSUSE,name\!liberty,name\!micro" --region us-east-1 | bat -l json
```

Filter examples:

```
pint_filter = 'name~sles-,name~byos,name~sap,name!arm64,name!manager,name!openSUSE,name!liberty,name!micro'
```
