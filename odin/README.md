# NextLanguage v3.0 migration

The Odin interpreter reads an NXL source file, parses it into statements, and executes it with a fresh variable table. This first implementation supports blank lines, comments, `@output` and `:output`, and `@var` and `@variable` declarations for strings, booleans, and signed decimal integers in the JavaScript safe-integer range. Unknown commands and unsupported types produce a diagnostic with the filename and line number.

Build with the [Odin dev-2026-11a compiler](https://github.com/odin-lang/Odin/releases/tag/dev-2026-11a) from the repository root.

```sh
odin build odin -vet -out:/tmp/nextlanguage-odin
/tmp/nextlanguage-odin odin/tests/basics.nxl
```

Run the same NXL fixture through both interpreters and compare their stdout. This also checks that the Odin CLI reports unsupported commands and invalid values.

```sh
sh odin/tests/compare.sh
```

The next migration step is expression evaluation and conditional blocks. Functions, loops, imports, input, and the JavaScript project configuration are still handled by the v2.0 interpreter.
