#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export ODIN="${ODIN:-odin}"

"$ODIN" build "$root/odin" -vet -out:"$work/nextlang"
compiler="$work/nextlang"
project="$root/odin/tests/project/main.nextlang"
"$compiler" check "$project"

mkdir "$work/output directory"
for optimization in speed size none; do
    binary="$work/output directory/$optimization"
    if [ "$optimization" = speed ]; then
        "$compiler" build "$project" -o "$binary"
    else
        "$compiler" build "$project" --opt "$optimization" -o "$binary"
    fi
    printf 'FN LET WHILE IMPORT\n24 3 multi-file modules\n%s\n' "$optimization" > "$work/expected"
    # Clear PATH to prove the executable does not invoke Odin or Node at runtime.
    PATH=/nonexistent "$binary" > "$work/actual"
    diff -u "$work/expected" "$work/actual"
done

"$compiler" build "$root/odin/tests/tape/main.nextlang" -o "$work/tape"
test "$(PATH=/nonexistent "$work/tape" '++++++++[>++++++++<-]>+.' '')" = A
test "$(PATH=/nonexistent "$work/tape" ',[.,]' Next)" = Next

mkdir -p "$work/bad" "$work/cycle/a"
cat > "$work/bad/main.nextlang" <<'SOURCE'
package main
fn main() {
    let n: int = "wrong type"
    _ = n
}
SOURCE
if "$compiler" build "$work/bad/main.nextlang" -o "$work/tape" > "$work/log" 2>&1; then
    echo 'Expected an invalid program to fail compilation' >&2
    exit 1
fi
grep -F "$work/bad/main.nextlang:3:18: error:" "$work/log" >/dev/null
test "$(PATH=/nonexistent "$work/tape" ',.' Z)" = Z

mkdir "$work/bad/helper"
cat > "$work/bad/main.nextlang" <<'SOURCE'
package main
import "./helper"
fn main() { helper.example() }
SOURCE
cat > "$work/bad/helper/example.nextlang" <<'SOURCE'
package helper
fn example() { let x = missing }
SOURCE
if "$compiler" check "$work/bad/main.nextlang" > "$work/log" 2>&1; then
    echo 'Expected a type error in the imported package' >&2
    exit 1
fi
grep -F "$work/bad/helper/example.nextlang:2:24: error:" "$work/log" >/dev/null

mv "$work/bad/main.nextlang" "$work/bad/main.nxl"
if "$compiler" check "$work/bad/main.nxl" > "$work/log" 2>&1; then
    echo 'Expected the compiler to reject the old extension' >&2
    exit 1
fi
grep -F 'The entry file must have the .nextlang extension' "$work/log"

cat > "$work/cycle/main.nextlang" <<'SOURCE'
package main
import "./a"
fn main() { a.value() }
SOURCE
cat > "$work/cycle/a/a.nextlang" <<'SOURCE'
package a
import original "../"
fn value() { original.main() }
SOURCE
if "$compiler" check "$work/cycle/main.nextlang" > "$work/log" 2>&1; then
    echo 'Expected an import cycle to fail compilation' >&2
    exit 1
fi
grep -Ei 'cycle|cyclic' "$work/log" > /dev/null

echo 'Native builds, optimization modes, module imports, and diagnostics passed.'

legacy="$root/NextLanguage-Source/package/bulit-in/Debugger/normal-tests"
compare_example() {
    "$compiler" build "$root/odin/examples/$1/main.nextlang" --opt none -o "$work/example"
    node -e 'require(process.argv[1])(process.argv[2]).catch(error => {
        console.error(error.message);
        process.exitCode = 1;
    })' "$root/NextLanguage-Source/package/start.js" "$legacy/$2.debug" > "$work/expected"
    PATH=/nonexistent "$work/example" > "$work/actual"
    diff -u "$work/expected" "$work/actual"
}
compare_example variables outputVariables
compare_example conditionals ifCommand
compare_example functions functionState
echo 'All three compiled examples match the v2 programs.'
