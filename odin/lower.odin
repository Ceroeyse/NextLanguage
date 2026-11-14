package main

import "core:fmt"
import "core:odin/tokenizer"
import "core:os"
import "core:path/filepath"
import "core:strconv"
import "core:strings"

Source_Edit :: struct {
    source_start, source_end: int,
    generated_start, generated_end: int,
}

lower_source :: proc(project: ^Project, filename, source: string) -> (string, []Source_Edit, bool) {
    lexer: tokenizer.Tokenizer
    tokenizer.init(&lexer, source, filename)
    lexer.flags = {.Insert_Semicolon}

    tokens: [dynamic]tokenizer.Token
    for {
        token := tokenizer.scan(&lexer)
        if token.kind == .EOF {
            break
        }
        if token.kind != .Comment {
            append(&tokens, token)
        }
    }
    if lexer.error_count != 0 {
        return "", nil, false
    }

    result := strings.builder_make()
    cursor := 0
    edits: [dynamic]Source_Edit
    previous: tokenizer.Token_Kind
    for token, index in tokens {
        begin := token.pos.offset
        end := begin + len(token.text)
        replacement := ""
        if token.kind == .Import && previous != .Foreign {
            path_index := index + 1
            if path_index < len(tokens) && tokens[path_index].kind == .Ident {
                path_index += 1
            }
            if path_index < len(tokens) && tokens[path_index].kind == .String {
                path := tokens[path_index]
                decoded, _, ok := strconv.unquote_string(path.text)
                if ok && (strings.has_prefix(decoded, "./") || strings.has_prefix(decoded, "../")) {
                    import_dir, _ := filepath.join({filepath.dir(filename), decoded})
                    if !os.is_directory(import_dir) {
                        fmt.eprintfln("%s:%d:%d: Next package directory not found: %s",
                            filename, path.pos.line, path.pos.column, decoded)
                        return "", nil, false
                    }
                    if strings.contains(path.text, "\n") || strings.contains(path.text, "\r") {
                        fmt.eprintfln("%s:%d:%d: Next package paths must be on one line",
                            filename, path.pos.line, path.pos.column)
                        return "", nil, false
                    }
                    canonical, err := os.get_absolute_path(import_dir, context.allocator)
                    if err != nil {
                        fmt.eprintfln("%s:%d:%d: Unable to resolve Next package %s: %v",
                            filename, path.pos.line, path.pos.column, decoded, err)
                        return "", nil, false
                    }
                    name, _ := add_package(project, canonical)
                    begin = path.pos.offset
                    end = begin + len(path.text)
                    replacement = fmt.aprintf("\"nextlang_project:%s\"", name)
                    // Generated directory names must not change the default import alias.
                    if path_index == index+1 {
                        replacement = fmt.aprintf("%s %s", filepath.base(import_dir), replacement)
                    }
                }
            }
        } else if token.kind == .Ident && previous != .Period {
            if token.text == "while" {
                replacement = "for"
            } else if index + 2 < len(tokens) {
                name, punctuation := tokens[index+1], tokens[index+2]
                if name.kind == .Ident && name.pos.line == token.pos.line &&
                   punctuation.pos.line == token.pos.line {
                    if token.text == "fn" && punctuation.kind == .Open_Paren {
                        replacement = fmt.aprintf("%s :: proc", name.text)
                        end = name.pos.offset + len(name.text)
                    } else if token.text == "let" && punctuation.kind == .Eq {
                        replacement = fmt.aprintf("%s :=", name.text)
                        end = punctuation.pos.offset + len(punctuation.text)
                    } else if token.text == "let" && punctuation.kind == .Colon {
                        replacement = name.text
                        end = name.pos.offset + len(name.text)
                    }
                }
            }
        }

        if replacement != "" && begin >= cursor {
            strings.write_string(&result, source[cursor:begin])
            generated_start := len(strings.to_string(result))
            strings.write_string(&result, replacement)
            append(&edits, Source_Edit{begin, end, generated_start, generated_start + len(replacement)})
            cursor = end
        }
        previous = token.kind
    }
    strings.write_string(&result, source[cursor:])
    return strings.to_string(result), edits[:], true
}
