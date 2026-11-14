package main

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"

Source_File :: struct {
    filename, content: string,
    edits: []Source_Edit,
}

Backend_Diagnostic :: struct {
    kind: string `json:"type"`,
    pos: struct {
        file: string,
        offset, line, column: int,
    },
    msgs: []string,
}

render_diagnostics :: proc(project: ^Project, stderr: string) {
    report: struct {
        errors: []Backend_Diagnostic,
    }
    // Linker failures and toolchain setup errors can be plain text.
    if json.unmarshal_string(stderr, &report) != nil || len(report.errors) == 0 {
        os.write_string(os.stderr, stderr)
        return
    }
    for diagnostic in report.errors {
        file := diagnostic.pos.file
        line, column := diagnostic.pos.line, diagnostic.pos.column
        if original, found := project.sources[file]; found {
            file = original.filename
            line, column = source_position(original, diagnostic.pos.offset)
        }
        if file != "" && line > 0 {
            fmt.eprintf("%s:%d:%d: ", file, line, column)
        }
        fmt.eprintfln("%s: %s", diagnostic.kind, strings.join(diagnostic.msgs, "\n"))
    }
}

source_position :: proc(source: Source_File, generated_offset: int) -> (line, column: int) {
    offset := generated_offset
    for edit in source.edits {
        if generated_offset < edit.generated_start {
            break
        }
        if generated_offset < edit.generated_end {
            offset = edit.source_start
            break
        }
        // Each pair of end offsets includes all earlier edits.
        offset = generated_offset + edit.source_end - edit.generated_end
    }

    line, column = 1, 1
    for value in transmute([]byte)source.content[:clamp(offset, 0, len(source.content))] {
        if value == '\n' {
            line += 1
            column = 1
        } else {
            column += 1
        }
    }
    return
}
