# Svelte / Sapper / Sveltekit

<!-- toc -->

## General


call only in client
```
if (typeof window !== 'undefined') {

}

//or

onMount(() => {

        })
```

**sveltekit ssg**

- https://kit.svelte.dev/docs/adapter-static
  - or no adapter, manual setting for ssg (to later do a ssr)
- https://www.okupter.com/blog/deploy-sveltekit-website-to-github-pages


**TEST STRUCTURE: FILES/DIRECTORIES**

Using Jest for unit and integration tests.

Inspired by Rust Tests organization/pattern: [The Rust Programming Language: Test Organization](https://doc.rust-lang.org/stable/book/ch11-03-test-organization.html)

- Unit tests: saved as `*.test.js` side by side functions/files that are being tested.
- Integration tests: saved at `myproject/tests` directory, side-by-side with `src` dir.

Separate tests with `jest-runner-groups`:
- [Separating unit and integration tests in Jest](https://medium.com/coding-stones/separating-unit-and-integration-tests-in-jest-f6dd301f399c)
- [npm: jest-runner-groups](https://www.npmjs.com/package/jest-runner-groups)

**SERVE STATIC IN ANOTHER URI:**

If want to serve a static web app in another URI (same domain, but not at root `/`), e.g.:
- `projects.cwnt.io/cadelab` (and not at `projects.cwnt.io`): URI is `/cadelab`
- `www.meuovo.com/mystaticapp`: URI is `/mystaticapp`

Change the base path in all of these places to make `sapper export` work: (example with URI/Base path `cadelab`)

```
src/serve.js
---

polka() // You can also use Express
	.use(
    '/cadelab', // <-- add this line[^wd1][^wd2]
		compression({ threshold: 0 }),
		sirv('static', { dev }),
		sapper.middleware()
	)
	.listen(PORT, err => {
		if (err) console.log('error', err);
	});
```

```
rollup.config.js
---

export default {
	client: {
		input: config.client.input(),
		output: config.client.output(),
		plugins: [

            //(...),

			url({
				sourceDir: path.resolve(__dirname, 'src/node_modules/images'),
				publicPath: '/cadelab/client/' // <-- change this path
			}),

            //(...)

        ]

    //(...)

	server: {
		input: config.server.input(),
		output: config.server.output(),
		plugins: [

            //(...),

			url({
				sourceDir: path.resolve(__dirname, 'src/node_modules/images'),
				publicPath: '/cadelab/client/', // <-- change this path
				emitFiles: false
			}),

            //(...)

        ]

```

```
package.json
---
  "scripts": {
    //(...),
    "export": "npm run build:tailwind && sapper export --legacy --basepath cadelab", // <-- add `--basepath cadelab`[^wd2]
```


After that, to serve these files, map the webserver for the root directory, with `cadelab` directory in it.
- file structure: `export/cadelab`
- serve `export` dir
- the URI/Base path will be `www.domain.com/cadelab`

## Sveltekit

### Typing / Jsdoc / Typescript

- [How to add JSDoc Typechecking to SvelteKit](https://www.swyx.io/jsdoc-swyxkit)

### Markdown blog

- [How to Quickly Build and Deploy a Static Markdown Blog with SvelteKit](https://www.thisdot.co/blog/how-to-quickly-build-and-deploy-a-static-markdown-blog-with-sveltekit/)
  - blog / md / mdsvex
  - typescript with types

- [Let's learn SvelteKit by building a static Markdown blog from scratch](https://joshcollinsworth.com/blog/build-static-sveltekit-markdown-blog)

- [Build A SvelteKit Markdown Blog](https://joyofcode.xyz/sveltekit-markdown-blog)
