#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM

"${ODIN:-odin}" build "$root/odin" -vet -out:"$work/nextlanguage-odin"
fixture="$root/odin/tests/basics.nxl"
"$work/nextlanguage-odin" "$fixture" > "$work/odin.txt"
node "$root/NextLanguage-Source/cli.js" "$fixture" > "$work/javascript.txt"
diff -u "$work/javascript.txt" "$work/odin.txt"

printf '@output valid\n@if [true]:\n@end\n' > "$work/unsupported.nxl"
if "$work/nextlanguage-odin" "$work/unsupported.nxl" > "$work/unsupported.out" 2> "$work/unsupported.err"; then
    echo 'Expected the Odin interpreter to reject unsupported syntax' >&2
    exit 1
fi
test ! -s "$work/unsupported.out"
grep -q 'unsupported.nxl:2: Unsupported command' "$work/unsupported.err"

printf '@var [ready]: (boolean)maybe\n' > "$work/invalid.nxl"
if "$work/nextlanguage-odin" "$work/invalid.nxl" > "$work/invalid.out" 2> "$work/invalid.err"; then
    echo 'Expected the Odin interpreter to reject an invalid value' >&2
    exit 1
fi
grep -q 'invalid.nxl:1: Invalid boolean' "$work/invalid.err"
echo 'Odin and JavaScript output match. Odin diagnostic checks passed.'
