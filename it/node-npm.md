# Node / NPM

> node, nodejs, node.js, npm

<!-- toc -->

- [Releases](#releases)
  - [Create a prerelease version](#create-a-prerelease-version)
  - [Bump the prerelease version](#bump-the-prerelease-version)
  - [Promote the prerelease to a release](#promote-the-prerelease-to-a-release)

<!-- tocstop -->

# Releases

version package.json and git tag

- [How to use `npm version` to create prerelease tags](https://jasonraimondi.com/posts/use-the-npm-version-command-to-semantically-version-your-node-project/)

## Create a prerelease version

```sh
# this will take you to 2.0.0-rc.0
npm version premajor --preid=rc

# this will take you to 1.1.0-beta.0
npm version preminor --preid=beta

# this will take you to 1.0.1-alpha.0
npm version prepatch --preid=alpha
```

## Bump the prerelease version

```sh
# this will take you to 1.1.0-beta.1
npm version prerelease

# and again will take you to 1.1.0-beta.2
npm version prerelease

# and again will take you to 1.1.0-beta.3 and so on
npm version prerelease
```

## Promote the prerelease to a release

```sh
# from 2.0.0-rc.1 to 2.0.0
npm version major

# from 1.1.0-beta.0 to 1.1.0
npm version minor

# from 1.0.1-alpha.0 to 1.0.1
npm version patch
```

