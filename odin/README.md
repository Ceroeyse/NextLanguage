# NextLanguage v3.0 compiler

NextLanguage compiles `.nextlang` packages to native executables. The frontend lowers Next syntax to Odin and uses Odin for type checking, optimization, code generation, and linking. The finished executable does not need Odin or Node.js at runtime.

## Build and use the compiler

Install [Odin dev-2026-11a](https://github.com/odin-lang/Odin/releases/tag/dev-2026-11a) and a linker supported by Odin. Run these commands from the NextLanguage repository root.

```sh
odin build odin -out:nextlang
./nextlang check odin/tests/project/main.nextlang
./nextlang build odin/tests/project/main.nextlang -o example
./example
```

The compiler searches for `odin` on `PATH`. Set `ODIN` to use a specific executable. A build defaults to the entry filename without its extension in the current directory. Use `-o` to choose the executable path, `--opt size` to optimize for size, or `--opt none` to disable optimization. The default mode is `speed`. The `check` command type-checks the package without creating a binary.

## Syntax and libraries

A program starts with `package main` and declares a `main` function. Next supports `fn name(parameters) -> Result { ... }`, inferred bindings with `let name = value`, typed bindings with `let name: Type = value`, and `while condition { ... }`. The lowered program uses Odin semantics, including mutable variables, arithmetic, `if`/`else`, `switch`, range and C-style loops, recursion, and typed arrays, dynamic arrays, maps, structs, pointers, generics, and procedure values.

```text
package main

import "core:fmt"
import text "core:strings"

fn factorial(n: int) -> int {
    if n < 2 {
        return 1
    }
    return n * factorial(n - 1)
}

fn main() {
    let n = 3
    while n > 0 {
        fmt.println(text.to_upper("factorial"), n, factorial(n))
        n -= 1
    }
}
```

Use any `core:` import path supported by the installed Odin compiler. Packages are passed directly to Odin, which resolves their own dependencies and exposes their exported procedures, types, and constants under the import alias. `base:` and `vendor:` imports also pass through, subject to Odin's target and system dependency requirements. Each file declares the packages it uses.

A Next package consists of the `.nextlang` files in one directory. Import another Next package with `import "./helpers"` or `import helpers "../helpers"`. Relative paths resolve from the importing file. Use an explicit alias when the directory name is not an identifier. Local imports identify package directories.

To migrate a v2 program, rename the file to `.nextlang` and convert directives to v3 syntax. Put executable statements inside `fn main()`, use `let` for variable declarations, and use `fmt.println` for output. The v2 JavaScript interpreter still runs existing `.nxl` programs.

## Tests

```sh
sh odin/tests/compiler.sh
```

The tests build and run recursive and iterative programs, check standard-library and multi-file imports, and verify all three optimization modes. A sparse-tape interpreter exercises loops, mutable indexed storage, and data-dependent branching. Negative cases cover type errors, cyclic imports, and the v2 file extension.

## v2 migration examples

The [variables](examples/variables/main.nextlang), [conditionals](examples/conditionals/main.nextlang), and [functions](examples/functions/main.nextlang) examples are ports of the bundled v2 debug programs. The compiler tests use Node.js 22 or newer to run the v2 originals and compare their standard output byte for byte with the native executables.
