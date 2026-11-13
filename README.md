# NextLanguage

NextLanguage (NXL) is a programming language created for Project Next. The v2.0 interpreter runs on Node.js and supports typed variables, conditionals, functions, loops, and file-relative imports.

## Run a program

Use Node.js 22 or newer. From the repository root, run:

```sh
npm run build
npm start
```

The build creates a sample `app.nxl`, records its path, and runs it. To run an existing program directly, use `npm start -- path/to/file.nxl`.

See the [installation guide](NextLanguage-Source/documentation/Installation_Guide.md) for project setup and the [module syntax guide](NextLanguage-Source/documentation/syntaxes/Modules.md) for examples.

## Tests

```sh
npm ci
npm test
npm run github
```

## Odin migration

The v3.0 branch includes a native Odin CLI for an initial subset of NXL. See the [Odin migration guide](odin/README.md) for supported commands, build instructions, and the JavaScript parity check.
