# Nix Language Basics

> $nix $nix-lang

Everyday syntax. Everything is an **expression** that evaluates to a value.

## Values & types

```nix
42 3.14                 # int, float
"hi" ''multi-line''     # strings ('' '' is an indented/multiline string)
true false null         # bools, null
[ 1 "two" 3 ]           # list — space-separated, NOT commas
{ a = 1; b = 2; }       # attribute set (dict/object); each entry ends with ;
./path ./file.toml      # path literal — first-class value, `.` = current dir
"github:owner/repo"     # just a string (flake refs are strings)
```

## Attribute sets

```nix
{ a = 1; b = { c = 2; }; }   # nested
obj.b.c                      # access with dots
{ a.b.c = 1; }               # sugar for { a = { b = { c = 1; }; }; }
{ "${sys}" = 1; }            # dynamic key via interpolation
obj ? a                      # `?` operator: does obj have key `a`?  → bool
```

## `let ... in` — local bindings

```nix
let
  x = 1;
  y = x + 1;      # bindings can reference EACH OTHER (order-independent, lazy)
in x + y          # → 3.  Scope = the `in` expr + the other bindings
```

`let a = b; b = 1; in a` works — laziness means textual order doesn't matter.

## Functions (always ONE argument; call by juxtaposition)

```nix
x: x + 1                     # lambda. Call it: (x: x + 1) 10  → 11
f a b                        # call f with a, then result with b (currying)
```

### Attrset-arg (named "arguments") + defaults + ellipsis

```nix
{ a, b ? 10, ... }: a + b    # destructure a set; b defaults to 10;
                             # `...` = ignore extra keys (omit it = extras error)
args@{ a, ... }: args        # `@` also binds the WHOLE set as `args`
```

Args are matched **by name, not position**. Names must match the keys passed in.

## `inherit` — copy names into a set

```nix
{ inherit x; }               # = { x = x; }
{ inherit (pkgs) cargo git; } # = { cargo = pkgs.cargo; git = pkgs.git; }
```

## Operators & keywords you'll see constantly

```nix
{ a = 1; } // { a = 9; b = 2; }   # //  merge, RIGHT wins, SHALLOW → {a=9;b=2;}
with pkgs; [ cargo git ]          # dump attrs into scope (use sparingly)
rec { v = "1"; n = "x-${v}"; }    # rec: entries can see each other
if cond then a else b             # expression — `else` is MANDATORY
"hello ${name}"                   # string interpolation
```

## `import` — a function, not a statement

```nix
import ./file.nix          # read + evaluate file.nix → its value
import nixpkgs { ... }     # nixpkgs evaluates to a FUNCTION; call it with config
```

## Standard libraries

- `builtins.*` — interpreter primitives: `readFile`, `fromJSON`, `toJSON`, `map`, `filter`,
  `fetchGit`, `currentSystem`.
- `lib.*` (from `pkgs.lib` / `nixpkgs.lib`) — the Nixpkgs stdlib.

```nix
map (x: x + 1) [ 1 2 3 ]              # → [ 2 3 4 ]
builtins.filter (x: x > 1) [ 1 2 3 ]  # → [ 2 3 ]
lib.optionals cond [ a b ]            # → [ a b ] if cond else [ ]
lib.mapAttrs (name: val: val) set     # transform every value in a set
lib.genAttrs [ "x86_64-linux" ] (s: …)# build a set keyed by those names
```

`genAttrs` is essentially what `flake-utils.eachDefaultSystem` does internally.

## Comments

```nix
# line comment
/* block comment */
```
