package main

import "core:encoding/json"
import "core:fmt"
import "core:io"
import "core:mem/virtual"
import "core:strconv"
import "core:strings"

Value :: union {
    string,
    bool,
    i64,
}

run_source :: proc(source: string, output: io.Writer) -> Diagnostic {
    arena: virtual.Arena
    if virtual.arena_init_growing(&arena) != nil {
        return {0, "Unable to allocate interpreter memory"}
    }
    defer virtual.arena_destroy(&arena)
    context.allocator = virtual.arena_allocator(&arena)

    statements, diagnostic := parse(source)
    if diagnostic.message != "" {
        return diagnostic
    }

    variables := make(map[string]Value)
    for statement in statements {
        switch command in statement.command {
        case Declare:
            value, error := parse_value(command)
            if error != "" {
                return {statement.line, error}
            }
            variables[command.name] = value
        case Output:
            value, found := variables[command.text]
            if !found {
                text, ok := read_text(command.text)
                if !ok {
                    return {statement.line, "Invalid string literal"}
                }
                value = text
            }

            text: string
            switch content in value {
            case string:
                text = content
            case bool:
                text = content ? "true" : "false"
            case i64:
                text = fmt.aprint(content)
            }
            _, text_error := io.write_string(output, text)
            if text_error != nil {
                return {statement.line, "Unable to write output"}
            }
            _, newline_error := io.write_string(output, "\n")
            if newline_error != nil {
                return {statement.line, "Unable to write output"}
            }
        }
    }
    return {}
}

parse_value :: proc(declaration: Declare) -> (Value, string) {
    text := declaration.text
    switch declaration.annotation {
    case "", "string":
        value, ok := read_text(text)
        if !ok {
            return nil, "Invalid string literal"
        }
        return value, ""
    case "boolean":
        if text != "true" && text != "false" {
            return nil, "Invalid boolean"
        }
        return text == "true", ""
    case "int", "integer", "negative", "negatives":
        digits := text
        if strings.has_prefix(text, "-") || strings.has_prefix(text, "+") {
            digits = text[1:]
        }
        for char in digits {
            if char < '0' || char > '9' {
                return nil, "Expected a decimal integer"
            }
        }
        value, ok := strconv.parse_i64(text, 10)
        max_safe_integer :: 9007199254740991
        if !ok || len(digits) == 0 || value < -max_safe_integer || value > max_safe_integer {
            return nil, "Invalid integer"
        }
        return value, ""
    case:
        return nil, "Unsupported variable type"
    }
}

read_text :: proc(text: string) -> (string, bool) {
    if len(text) >= 2 && text[0] == '"' && text[len(text)-1] == '"' {
        value: string
        error := json.unmarshal_string(text, &value)
        return value, error == nil
    }
    if len(text) >= 2 && text[0] == '\'' && text[len(text)-1] == '\'' {
        body := text[1:len(text)-1]
        if !strings.contains(body, "\\") {
            return body, true
        }
        buffer := strings.builder_make()
        for i := 0; i < len(body); i += 1 {
            char := body[i]
            if char == '\\' && i+1 < len(body) {
                switch body[i+1] {
                case '\'', '\\': char = body[i+1]; i += 1
                case 'n': char = '\n'; i += 1
                case 'r': char = '\r'; i += 1
                case 't': char = '\t'; i += 1
                }
            }
            strings.write_byte(&buffer, char)
        }
        return strings.to_string(buffer), true
    }
    return text, true
}
