package main

import "core:fmt"
import "core:mem/virtual"
import "core:os"
import "core:path/filepath"
import "core:strings"

usage :: `Usage: nextlang build <entry.nextlang> [-o <executable>] [--opt speed|size|none]
       nextlang check <entry.nextlang>`

Options :: struct {
    entry, output, optimization: string,
    check: bool,
}

main :: proc() {
    os.exit(run_cli(os.args[1:]))
}

run_cli :: proc(args: []string) -> int {
    if len(args) == 1 && (args[0] == "--help" || args[0] == "-h") {
        fmt.println(usage)
        return 0
    }
    options, error := parse_options(args)
    if error != "" {
        fmt.eprintln(error)
        fmt.eprintln(usage)
        return 2
    }

    arena: virtual.Arena
    if err := virtual.arena_init_growing(&arena); err != nil {
        fmt.eprintfln("Unable to allocate compiler memory: %v", err)
        return 1
    }
    defer virtual.arena_destroy(&arena)
    context.allocator = virtual.arena_allocator(&arena)
    return compile(options)
}

parse_options :: proc(args: []string) -> (Options, string) {
    if len(args) < 2 || (args[0] != "build" && args[0] != "check") {
        return {}, "Expected build or check followed by an entry file"
    }
    options := Options{entry = args[1], optimization = "speed", check = args[0] == "check"}
    if filepath.ext(options.entry) != ".nextlang" {
        return {}, "The entry file must have the .nextlang extension"
    }
    if options.check && len(args) != 2 {
        return {}, "The check command does not take build options"
    }

    for i := 2; i < len(args); i += 2 {
        if i+1 >= len(args) || args[i+1] == "" {
            return {}, "Missing value for build option"
        }
        switch args[i] {
        case "-o":
            options.output = args[i+1]
        case "--opt":
            options.optimization = args[i+1]
            if options.optimization != "speed" && options.optimization != "size" && options.optimization != "none" {
                return {}, "Expected --opt speed, size, or none"
            }
        case:
            return {}, "Unknown build option"
        }
    }
    return options, ""
}

compile :: proc(options: Options) -> int {
    if !os.is_file(options.entry) {
        fmt.eprintfln("%s: unable to open entry file", options.entry)
        return 1
    }
    entry, entry_error := os.get_absolute_path(options.entry, context.allocator)
    if entry_error != nil {
        fmt.eprintfln("%s: unable to open entry file", options.entry)
        return 1
    }

    output, parent: string
    if !options.check {
        name := options.output
        if name == "" {
            name = filepath.stem(options.entry)
        }
        when ODIN_OS == .Windows {
            if !strings.equal_fold(filepath.ext(name), ".exe") {
                name = fmt.aprintf("%s.exe", name)
            }
        }
        extension := filepath.ext(name)
        if strings.equal_fold(extension, ".nextlang") || strings.equal_fold(extension, ".nxl") {
            fmt.eprintln("The output path must differ from a NextLanguage source path")
            return 1
        }
        err: os.Error
        parent, err = os.get_absolute_path(filepath.dir(name), context.allocator)
        if err != nil || !os.is_directory(parent) {
            fmt.eprintfln("%s: output directory does not exist", filepath.dir(name))
            return 1
        }
        output, _ = filepath.join({parent, filepath.base(name)})
        if output == entry || os.is_directory(output) {
            fmt.eprintfln("%s: invalid executable output path", output)
            return 1
        }
    }

    workspace, workspace_error := os.make_directory_temp(parent, "nextlang-build-*", context.allocator)
    if workspace_error != nil {
        fmt.eprintfln("Unable to create a build directory: %v", workspace_error)
        return 1
    }
    defer os.remove_all(workspace)

    project := Project{workspace = workspace, packages = make(map[string]int), sources = make(map[string]string)}
    _, staged_dir := add_package(&project, filepath.dir(entry))
    if !stage_project(&project, entry) {
        return 1
    }

    backend := os.get_env("ODIN", context.allocator)
    if backend == "" {
        backend = "odin"
    }
    collection := fmt.aprintf("-collection:nextlang_project=%s", workspace)
    args: [dynamic]string
    append(&args, backend, "build", staged_dir, collection, "-error-pos-style:unix")
    executable_name :: "program.exe" when ODIN_OS == .Windows else "program"
    temporary_output, _ := filepath.join({workspace, executable_name})
    if options.check {
        args[1] = "check"
    } else {
        append(&args, fmt.aprintf("-out:%s", temporary_output), fmt.aprintf("-o:%s", options.optimization))
    }

    state, stdout, stderr, process_error := os.process_exec({command = args[:]}, context.allocator)
    if process_error != nil {
        fmt.eprintfln("Unable to invoke Odin (%s): %v", backend, process_error)
        return 1
    }
    if len(stdout) > 0 {
        os.write(os.stdout, stdout)
    }
    if len(stderr) > 0 {
        os.write_string(os.stderr, remap_diagnostics(&project, string(stderr)))
    }
    if !state.success || state.exit_code != 0 {
        return 1
    }
    if !options.check {
        if err := os.rename(temporary_output, output); err != nil {
            fmt.eprintfln("%s: unable to publish executable: %v", output, err)
            return 1
        }
    }
    return 0
}
