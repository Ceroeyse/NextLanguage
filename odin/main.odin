package main

import "core:fmt"
import "core:os"

main :: proc() {
    os.exit(run_cli(os.args[1:]))
}

run_cli :: proc(args: []string) -> int {
    if len(args) == 1 && (args[0] == "--help" || args[0] == "-h") {
        fmt.println("Usage: nextlanguage-odin <file.nxl>")
        return 0
    }
    if len(args) != 1 {
        fmt.wprintln(os.to_writer(os.stderr), "Usage: nextlanguage-odin <file.nxl>")
        return 2
    }

    filename := args[0]
    data, read_error := os.read_entire_file(filename, context.allocator)
    if read_error != nil {
        fmt.wprintfln(os.to_writer(os.stderr), "%s: %v", filename, read_error)
        return 1
    }
    defer delete(data)

    diagnostic := run_source(string(data), os.to_writer(os.stdout))
    if diagnostic.message != "" {
        fmt.wprintfln(os.to_writer(os.stderr), "%s:%d: %s", filename, diagnostic.line, diagnostic.message)
        return 1
    }
    return 0
}
