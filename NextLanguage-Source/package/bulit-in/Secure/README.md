# Loading JavaScript plugins

A project can load a trusted Node.js plugin from `package.config.val`:

```text
PLUGINS: Example @path: plugins/example.js @sign plugins/info.js
```

Both paths are relative to the project directory. The metadata module exports a function that returns `{ name: 'Example', enabled: true }`. The plugin module exports a function that receives `{ package, local, addOutput, debugOutput }` and can return a promise.

The metadata checks the configured name and whether the plugin is enabled. Plugin and metadata files run with the same Node.js permissions as the interpreter.
