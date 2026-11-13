package main

import "core:strings"

Command :: union {
    Output,
    Declare,
}

Output :: struct {
    text: string,
}

Declare :: struct {
    name: string,
    annotation: string,
    text: string,
}

Statement :: struct {
    line: int,
    command: Command,
}

Diagnostic :: struct {
    line: int,
    message: string,
}

parse :: proc(source: string) -> ([dynamic]Statement, Diagnostic) {
    remaining := source
    statements: [dynamic]Statement
    line_number := 0

    for source_line in strings.split_lines_iterator(&remaining) {
        line_number += 1
        line := strings.trim_space(strings.trim_suffix(strings.trim_space(source_line), ";"))
        if line == "" || strings.has_prefix(line, "#") {
            continue
        }

        separator := len(line)
        for char, offset in line {
            if strings.is_space(char) {
                separator = offset
                break
            }
        }
        command := line[:separator]
        operand := strings.trim_left_space(line[separator:])
        switch command {
        case "@output", ":output":
            if operand == "" {
                return statements, {line_number, "Expected output text"}
            }
            append(&statements, Statement{line_number, Output{operand}})
        case "@var", "@variable":
            declaration, ok := parse_declaration(operand)
            if !ok {
                return statements, {line_number, "Expected a variable declaration"}
            }
            append(&statements, Statement{line_number, declaration})
        case:
            return statements, {line_number, "Unsupported command"}
        }
    }
    return statements, {}
}

parse_declaration :: proc(operand: string) -> (Declare, bool) {
    closing := strings.index_byte(operand, ']')
    if closing < 2 || operand[0] != '[' || !strings.has_prefix(operand[closing+1:], ":") {
        return {}, false
    }

    name := operand[1:closing]
    for char in name {
        if !(char >= 'a' && char <= 'z' || char >= 'A' && char <= 'Z' ||
            char >= '0' && char <= '9' || char == '_') {
            return {}, false
        }
    }

    annotation := ""
    text := strings.trim_left_space(operand[closing+2:])
    if strings.has_prefix(text, "(") {
        closing_type := strings.index_byte(text, ')')
        if closing_type < 2 {
            return {}, false
        }
        annotation = text[1:closing_type]
        text = strings.trim_left_space(text[closing_type+1:])
    }
    return Declare{name, annotation, text}, true
}
