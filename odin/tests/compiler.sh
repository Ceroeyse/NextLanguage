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
grep -F "$work/bad/main.nextlang:3:" "$work/log"
test "$(PATH=/nonexistent "$work/tape" ',.' Z)" = Z

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
