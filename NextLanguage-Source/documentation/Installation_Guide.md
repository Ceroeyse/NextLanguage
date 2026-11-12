# Installing and running NextLanguage

Download the [stable release](https://github.com/Ceroeyse/NextLanguage/releases/latest) and extract it. Open a terminal at the repository root, where `package.json` is located. The JavaScript interpreter requires Node.js 22 or newer and has no runtime dependencies.

| Command | Result |
| --- | --- |
| `npm run build` | Creates a starter program if needed, writes the main file path, and runs the program. |
| `npm run build -- "my project/main.nxl"` | Creates or selects the specified main file and runs it. Existing source is preserved. |
| `npm start` | Runs the program named in `main.config.file`. |
| `npm start -- path/to/file.nxl` | Runs the specified file for this invocation. |
| `npm run debug` | Runs the bundled NXL examples for variables, conditions, and functions. |

An existing `PACKAGES: @main path/to/file.nxl` entry in `package.config.val` supplies the main path when `main.config.file` is empty. Add `PACKAGES: @others path/to/file.nxl` for each additional script to run after the main script. Configured paths resolve from the project directory. Imports in NXL scripts resolve from the importing file.

To use the CLI directly, run `node NextLanguage-Source/cli.js --help`.
