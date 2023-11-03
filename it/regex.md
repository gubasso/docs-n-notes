# Regex

<!-- vim-markdown-toc GFM -->

* [Basics[^1]](#basics1)
* [References:](#references)

<!-- vim-markdown-toc -->

## Basics[^1]

`^` and `$` are called "anchors". They anchor the match to the beginning and end of the string respectively.

```
^foo    matches any string starting with 'foo'
foo$    matches any string ending with 'foo'
^foo$   matches exact string 'foo'.
```

To be precise, the last one is "any string starting and ending with the same 'foo'"; "foofoo" does not match.

`[0-9]` is an example of a character class; it matches any single digit.
`[a-z]` matches any lower case alpha, and
`[0-9a-f]` is the range of hex characters.

`.` (the period) is special -- it matches any character.
If you want to match an actual period, you need to say `\.`.

`*`, `?`, and `+` are quantifiers.
They apply to the previous token. `a*` means "zero or more 'a' characters". Similarly
`a+` means "one or more", and
`a?` means "zero or one".

As a result, `.*` means "any number (including zero) of any character".

The previous token need not be a single character; you can use parens to make it longer.
`(foo)+` matches one or more "foo", (like "foo", "foofoo", "foofoofoo", etc.)

## References:

[^1]: [Gitolite: extremely brief regex overview](https://gitolite.com/gitolite/regex)
