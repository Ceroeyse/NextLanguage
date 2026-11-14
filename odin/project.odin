package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:slice"
import "core:strings"

Project :: struct {
    workspace: string,
    packages: map[string]int,
    pending: [dynamic]string,
    sources: map[string]string,
}

add_package :: proc(project: ^Project, path: string) -> (name, directory: string) {
    index, found := project.packages[path]
    if !found {
        index = len(project.pending)
        project.packages[path] = index
        append(&project.pending, path)
    }
    name = fmt.aprintf("package_%d", index)
    directory, _ = filepath.join({project.workspace, name})
    return
}

stage_project :: proc(project: ^Project, entry: string) -> bool {
    for index := 0; index < len(project.pending); index += 1 {
        original := project.pending[index]
        _, staged := add_package(project, original)
        if err := os.make_directory(staged); err != nil {
            fmt.eprintfln("%s: unable to stage package: %v", original, err)
            return false
        }

        files, err := os.read_directory_by_path(original, -1, context.allocator)
        if err != nil {
            fmt.eprintfln("%s: unable to list package: %v", original, err)
            return false
        }
        slice.sort_by(files, proc(a, b: os.File_Info) -> bool { return a.name < b.name })

        count := 0
        entry_found := false
        for info in files {
            if filepath.ext(info.name) != ".nextlang" ||
               (info.type != .Regular && info.type != .Symlink) {
                continue
            }
            filename, _ := filepath.join({original, info.name})
            if !os.is_file(filename) {
                continue
            }
            entry_found ||= filename == entry
            staged_file, _ := filepath.join({staged, fmt.aprintf("%s.odin", filepath.stem(info.name))})
            if !stage_file(project, filename, staged_file) {
                return false
            }
            count += 1
        }
        if count == 0 || (index == 0 && !entry_found) {
            fmt.eprintfln("%s: expected a package containing .nextlang source files", original)
            return false
        }
    }
    return true
}

stage_file :: proc(project: ^Project, filename, staged_file: string) -> bool {
    source, read_error := os.read_entire_file(filename, context.allocator)
    if read_error != nil {
        fmt.eprintfln("%s: unable to read source: %v", filename, read_error)
        return false
    }
    translated, ok := lower_source(project, filename, string(source))
    if !ok {
        return false
    }
    if err := os.write_entire_file(staged_file, translated); err != nil {
        fmt.eprintfln("%s: unable to stage source: %v", filename, err)
        return false
    }
    project.sources[staged_file] = filename
    if cwd, err := os.get_working_directory(context.allocator); err == nil {
        if relative, relative_error := filepath.rel(cwd, staged_file); relative_error == nil {
            project.sources[relative] = filename
        }
    }
    return true
}

remap_diagnostics :: proc(project: ^Project, diagnostics: string) -> string {
    rendered := diagnostics
    for staged, original in project.sources {
        rendered, _ = strings.replace_all(rendered, staged, original)
    }
    return rendered
}
