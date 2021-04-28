" VimIT (Vim Interactive Template)
" Copyright (C) <year>  <name of author>
" 
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
" 
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
" 
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <https://www.gnu.org/licenses/>.

if exists("g:vimit_loaded")
    finish
endif
let g:vimit_loaded = 1

let s:vimit_record_mode_line = 0
let s:vimit_record_mode_col = 0
let s:vimit_record_mode = 0
let s:vimit_var_set = {}
let s:vimit_var_state = {}
let s:vimit_var_expr = {}
let s:vimit_var_format = {}
let s:vimit_printed = ""
let s:vimit_groups = {}

"prints the text normally
function! s:VIMIT_insert(text)
    if type(a:text) != v:t_string
        call execute("normal! a" . string(a:text))
        let s:vimit_printed .= string(a:text)
    else
        call execute("normal! a" . a:text)
        let s:vimit_printed .= a:text
    endif
endfunction

"prints the text with format
function! s:VIMIT_printf(format, text)
    call execute("normal! a" . printf(a:format, a:text)) 
    let s:vimit_printed .= printf(a:format, a:text)
endfunction

function! s:VIMIT_var_scope(var_name)
    let s = split(a:var_name, '#')
    for key in keys(s:vimit_state)
    endfor
endfunction

function! s:VIMIT_eval_lex(expr, var_name)
    let n = 0
    let lex_state = "expr"
    let ret = ""
    let var_name = ""
    let var_format = ""
    while n < strlen(a:expr)
        if lex_state == "expr"
            if a:expr[n] == '$'
                let lex_state = "var"
                let var_name = ""
            else
                let ret .= a:expr[n]
                let lex_state = "expr"
            endif
        elseif lex_state == "var"
            if a:expr[n] == '('
                let var_name = ""
                let lex_state = "var_name"
            elseif a:expr[n] >= 'a' && a:expr[n] <= 'z' || a:expr[n] >= 'A' && a:expr[n] <= 'Z' || a:expr[n] == '_' || a:expr[n] == '$'
                let var_name = a:expr[n]
                let lex_state = "var_name_nb"
            else
                let lex_state = "error"
            endif
        elseif lex_state == "var_name"
            "call input(a:expr[n:strlen(a:expr)-1])
            if a:expr[n] >= 'a' && a:expr[n] <= 'z' || a:expr[n] >= 'A' && a:expr[n] <= 'Z' || a:expr[n] == '_' || a:expr[n] == '$'
                let var_name .= a:expr[n]
            elseif a:expr[n] == ')'
                let name = a:var_name . '#' . var_name
                if var_name[0] == '_'
                    let name = split(a:var_name, '#')[0] . '#' . var_name[1:strlen(var_name)-1]
                endif
                let ret .= "s:vimit_var_state[\"" . name . "\"]"
                let var_name = ""
                let lex_state = "expr"
            elseif a:expr[n] == '%' || a:expr[n] == '^'
                let var_format = a:expr[n]
                let lex_state = "format"
            else
                let lex_state = "error"
            endif
        elseif lex_state == "var_name_nb"
            if a:expr[n] >= 'a' && a:expr[n] <= 'z' || a:expr[n] >= 'A' && a:expr[n] <= 'Z' || a:expr[n] == '_' || expr[n] == '$'
                let var_name .= a:expr[n]
            elseif a:expr[n] == '%' || a:expr[n] == '^'
                let var_format = a:expr[n]
                let lex_state = "format_nb"
            else
                let name = a:var_name . '#' . var_name
                if var_name[0] == '_'
                    let name = split(a:var_name, '#')[0] . '#' . var_name[1:strlen(var_name)-1]
                endif
                let ret .= "s:vimit_var_state[\"" . name . "\"]"
                let var_name = ""
                let lex_state = "expr"
            endif
        elseif lex_state == "format"
            if a:expr[n] != ')'
                let var_format .= a:expr[n]
                let lex_state = "format"
            else
                let name = a:var_name . '#' . var_name
                if var_name[0] == '_'
                    let name = split(a:var_name, '#')[0] . '#' . var_name[1:strlen(var_name)-1]
                endif
                if var_format[0] == '%'
                    let ret .= "printf(\"" . var_format . "\",s:vimit_var_state[\"" . name . "\"])"
                elseif var_format[0] == '^' && var_format[1] == '%'
                    let ret .= "printf(\"" . var_format . "\",toupper(s:vimit_var_state[\"" . name . "\"]))"
                else
                    let ret .= "toupper(s:vimit_var_state[\"" . name . "\"])"
                endif
                let var_format = ""
                let var_name = ""
            endif
        elseif lex_state == "format_nb"
            if a:expr[n] != ' '
                let var_format .= a:expr[n]
                let lex_state = "format"
            else
                let name = a:var_name . '#' . var_name
                if var_name[0] == '_'
                    let name = split(a:var_name, '#')[0] . '#' . var_name[1:strlen(var_name)-1]
                endif
                if var_format[0] == '%'
                    let ret .= "printf(\"" . var_format . "\",s:vimit_var_state[\"" . name . "\"])"
                elseif var_format[0] == '^' && var_format[1] == '%'
                    let ret .= "printf(\"" . var_format . "\",toupper(s:vimit_var_state[\"" . name - "\"]))"
                else
                    let ret .= "toupper(s:vimit_var_state[\"" . name . "\"])"
                endif
                let var_format = ""
                let var_name = ""
            endif
        else

        endif
        let n += 1
    endwhile
    return ret
endfunction

"wip
function! s:VIMIT_eval(expr, var_name)
    "Evaluation environment:
    let FILENAME = expand("%:t")
    let EXTENSION = expand("%:e")
    let FULL_PATH = expand("%:p")
    let DIRECTORY = expand("%:p:h")
    if has_key(s:vimit_var_state, a:var_name)
        let n = s:vimit_var_state[a:var_name]
    endif
    return eval(s:VIMIT_eval_lex(a:expr, a:var_name))
endfunction

"get user input and evaluate expressions
function! s:VIMIT_input(name, format, is_expr)
    let var_name = a:name
    let input = 1
    if !has_key(s:vimit_var_set, var_name) || s:vimit_var_set[var_name] == 0
        "add space and remove it to alow display of cursor
        call execute("normal! a ")
        let highlight = matchaddpos("Cursor", [[line('.'), col('.')]])
        redraw 
        let in = input("var " . var_name . a:format . ":")
        call matchdelete(highlight)
        call execute("normal! x")
        let in_split = split(in, ';')
        if empty(in) && has_key(s:vimit_var_state, var_name) 
            if a:is_expr != 0
                let in_split = split(s:vimit_var_expr[var_name], ';')
                for expr in in_split
                    try
                        let s:vimit_var_state[var_name] = s:VIMIT_eval(expr, var_name)
                    catch
                        let s:vimit_var_state[var_name] = s:VIMIT_eval("\"" . expr . "\"", var_name)
                    endtry
                endfor
            else
                
            endif
        elseif empty(in)
            let input = 0
        else
            if a:is_expr != 0
                try
                    let s:vimit_var_state[var_name] = s:VIMIT_eval(in_split[0], var_name)
                catch
                    let s:vimit_var_state[var_name] = s:VIMIT_eval("\"" . in_split[0] . "\"", var_name)
                endtry
                call remove(in_split, 0)
                let s:vimit_var_expr[var_name] = join(in_split, ';')
            else
                let s:vimit_var_state[var_name] = in
            endif
        endif
    endif
    if !empty(a:format) && input != 0
        let format = a:format
        if format[0] == '^' && format[1] == '%'
            call s:VIMIT_printf(format[1:strlen(format)-1], toupper(s:vimit_var_state[var_name]))
        elseif format[0] == '^'
            call s:VIMIT_insert(toupper(s:vimit_var_state[var_name]))
        else
            call s:VIMIT_printf(format, s:vimit_var_state[var_name])
        endif
    elseif input == 1
        call s:VIMIT_insert(s:vimit_var_state[var_name])
    endif
    if input == 1
        let s:vimit_var_set[var_name] = 1
    endif
    return input
endfunction

function! s:VIMIT_reset(name)
    for key in keys(s:vimit_var_set)
        if stridx(key, a:name) == 0
            let s:vimit_var_set[key] = 0
        endif
    endfor
endfunction

function! s:VIMIT_clear_states(name)
    for key in keys(s:vimit_var_state)
        if stridx(key, a:name) == 0
            unlet s:vimit_var_state[key]
        endif
    endfor
endfunction

function! s:VIMIT_rep_len(string)
    let n = 0
    let c = 1
    let init = 0
    while n < strlen(a:string)
        if a:string[n] == '$' && a:string[n+1] == '{'
            let c += 1
        elseif a:string[n] == '$' && a:string[n+1] == '}'
            let c -= 1
        endif
        if c == 0
            if n+1 < strlen(a:string) && a:string[n+1] == '*'
                return n+2
            else
                return n+1
            endif
        endif
        let n += 1
    endwhile
    return -1
endfunction

function! s:VIMIT_cond_len(string)
    let n = 0
    let c = 1
    let init = 0
    while n < strlen(a:string)
        if a:string[n] == '$' && a:string[n+1] == '['
            let c += 1
        elseif a:string[n] == '$' && a:string[n+1] == ']'
            let c -= 1
        endif
        if c == 0
            return n+1
        endif
        let n += 1
    endwhile
    return -1
endfunction

function! s:VIMIT_backtrack(len)
    let n = 0
    while n < a:len
        if s:vimit_printed[strlen(s:vimit_printed)-1-n] == '\n'
            call execute("normal! J")
        else
            call execute("normal! x")
        endif
        let n += 1
    endwhile
endfunction

"parse string
function! s:VIMIT_parse(string, name)
    let parse_state = "text"
    let var_name = ""
    let rep_name = ""
    let rep_cont = ""
    let var_format = ""
    let cond_name = ""
    let cond = ""
    "let s:vimit_printed = ""
    let n = 0
    let cond_name = ""
    let s:vimit_var_set[a:name] = 1
    "Predefined
    let s:vimit_var_set[a:name . '#' . "FILENAME"] = 1
    let s:vimit_var_state[a:name . '#' . "FILENAME"] = expand("%:t")
    let s:vimit_var_set[a:name . '#' . "DIRECTORY"] = 1
    let s:vimit_var_state[a:name . '#' . "DIRECTORY"] = expand("%p:h")
    let s:vimit_var_set[a:name . '#' . "FULL_PATH"] = 1
    let s:vimit_var_state[a:name . '#' . "FULL_PATH"] = expand("%p")
    let s:vimit_var_set[a:name . '#' . "EXTENSION"] = 1
    let s:vimit_var_state[a:name . '#' . "EXTENSION"] = expand("%:e")

    while n < strlen(a:string)
        let char = a:string[n]
        let c = char2nr(char)
        if parse_state == "text" 
            if char == '$'
                let parse_state = "var"
            else
                call s:VIMIT_insert(char)
            endif
        elseif parse_state == "var" 
            if char == '('
                let var_name = ""
                let parse_state = "var_name"
            elseif char == '$'
                call s:VIMIT_insert(char)
                let parse_state = "text"
            elseif (c >= char2nr('a') && c <= char2nr('z') || c >= char2nr('A') && c <= char2nr('Z') || c >= char2nr('0') && c <= char2nr('9') || c == char2nr('_')) || c == char2nr('$')
                let var_name = char
                let parse_state = "var_name_nb"
            elseif char == '{'
                let rep_name = ""
                let parse_state = "rep_name"
            elseif char == '}'
                return n
            elseif char == '['
                let cond = ""
                let cond_name = ""
                let parse_state = "cond_name"
            elseif char == ']'
                return n
            else
                let parse_state = "error"
            endif
        elseif parse_state == "var_name" 
            if (c >= char2nr('a') && c <= char2nr('z') || c >= char2nr('A') && c <= char2nr('Z') || c >= char2nr('0') && c <= char2nr('9') || c == char2nr('_')) || c == char2nr('$')
                let var_name .= char
                let parse_state = "var_name"
            elseif char == '%' || char == '^'
                let var_format = "" . char
                let parse_state = "format"
            elseif char == ')'
                "global variables start with _
                let name = ""
                let is_expr = 0
                if var_name[0] == '$'
                    let is_expr = 1
                    let var_name = var_name[1:strlen(var_name)-1]
                endif
                if var_name[0] == '_'
                    let name = split(a:name, '#')[0] . "#" . var_name[1:strlen(var_name)-1]
                endif
                let name = a:name . "#" . var_name
                if s:VIMIT_input(name, "", is_expr) == 0
                    call s:VIMIT_clear_states(name)
                    return -1
                endif
                let parse_state = "text"
            else
                let parse_state = "error"
            endif
        elseif parse_state == "format"
            if char != ')'
                let var_format .= char
                let parse_state = "format"
            else
                let name = ""
                let is_expr = 0
                if var_name[0] == '$'
                    let is_expr = 1
                    let var_name = var_name[1:strlen(var_name)-1]
                endif
                if var_name[0] == '_'
                    let name = split(a:name, '#')[0] . "#" . var_name[1:strlen(var_name)-1]
                endif
                let name = a:name . "#" . var_name
                if s:VIMIT_input(name, var_format, is_expr) == 0
                    call s:VIMIT_clear_states(name)
                    return -1
                endif
                let parse_state = "text"
            endif
        elseif parse_state == "var_name_nb"
            if (c >= char2nr('a') && c <= char2nr('z') || c >= char2nr('A') && c <= char2nr('Z') || c >= char2nr('0') && c <= char2nr('9') || c == char2nr('_')) || c == char2nr('$')
                let var_name .= char
                let parse_state = "var_name_nb"
            elseif char == '%' || char == '^'
                let var_format = "" . char
                let parse_state = "format_nb"
            else
                let name = ""
                let is_expr = 0
                if var_name[0] == '$'
                    let is_expr = 1
                    let var_name = var_name[1:strlen(var_name)-1]
                endif
                if var_name[0] == '_'
                    let name = split(a:name, '#')[0] . "#" . var_name[1:strlen(var_name)-1]
                endif
                let name = a:name . "#" . var_name
                if s:VIMIT_input(name, "", is_expr) == 0
                    call s:VIMIT_clear_states(name)
                    return -1
                endif
                call s:VIMIT_insert(char)
                let parse_state = "text"
            endif
        elseif parse_state == "format_nb"
            if char != ' '
                let var_format .= char
                let parse_state = "format_nb"
            else
                let name = ""
                let is_expr = 0
                if var_name[0] == '$'
                    let is_expr = 1
                    let var_name = var_name[1:strlen(var_name)-1]
                endif
                if var_name[0] == '_'
                    let name = split(a:name, '#')[0] . "#" . var_name[1:strlen(var_name)-1]
                endif
                let name = a:name . "#" . var_name
                if s:VIMIT_input(name, var_format, is_expr) == 0
                    call s:VIMIT_clear_states(name)
                    return -1
                endif
                call s:VIMIT_insert(char)
                let parse_state = "text"
            endif
        elseif parse_state == "rep_name"
            if (c >= char2nr('a') && c <= char2nr('z') || c >= char2nr('A') && c <= char2nr('Z') || c >= char2nr('0') && c <= char2nr('9') || c == char2nr('_')) || c == char2nr('$')
                let rep_name .= char
                let parse_state = "rep_name"
            elseif char == ':'
                let parse_state = "rep_cont"
            else
                let parse_state = "error"
            endif
        elseif parse_state == "rep_cont"
            let printed_tmp = strlen(s:vimit_printed)
            let result = s:VIMIT_parse(a:string[n:strlen(a:string)-1], a:name . "#" . rep_name)
            if result >= 0
                let s:vimit_groups[a:name . "#" . rep_name] = 1
                if a:string[n+result+1] == '*'
                    let m = 1
                    let name = a:name . "#" . rep_name . m
                    while s:VIMIT_parse(a:string[n:strlen(a:string)-1], name) >= 0
                        let printed_tmp = strlen(s:vimit_printed)
                        let m += 1
                        let name = a:name . "#" . rep_name . m
                    endwhile
                    "backtrack using s:vimit_printed since it is reseted on
                    "start of s:VIMIT_parse
                    call s:VIMIT_backtrack(strlen(s:vimit_printed)-printed_tmp)
                    let n += 1
                    "need to parse to the end if lowest level
                    if len(split(a:name, '#')) > 1
                        return -1
                    endif
                endif
                let n += result
                let parse_state = "text"
            else
                call s:VIMIT_clear_states(a:name . "#" . rep_name)
                "backtrack
                call s:VIMIT_backtrack(strlen(s:vimit_printed)-printed_tmp)
                let result = s:VIMIT_rep_len(a:string[n:strlen(a:string)-1])
                if result >= 0
                    let n += result
                endif
                if a:string[n+1] == '*'
                    let n += 1
                endif
                let parse_state = "text"
                "need to parse to the end if lowest level
                if len(split(a:name, '#')) > 1
                    return -1
                endif
            endif
        elseif parse_state == "cond_name"
            if (c >= char2nr('a') && c <= char2nr('z') || c >= char2nr('A') && c <= char2nr('Z') || c >= char2nr('0') && c <= char2nr('9') || c == char2nr('_'))
                let cond_name .= char
                let parse_state = "cond_name"
            elseif char == ':'
                let parse_state = "cond"
            else
                let parse_state = "error"
            endif
        elseif parse_state == "cond"
            if char != '?' && char != '$'
                let cond .= char
                let parse_state = "cond"
            elseif char == '$' && a:string[n+1] == ']'
                call s:VIMIT_insert(s:VIMIT_eval(cond, a:name . "#" . cond_name))
            elseif char == '$'
                let cond .= char
                let parse_state = "cond"
            else
                let parse_state = "cond_cont"
            endif
        elseif parse_state == "cond_cont"
            let printed_tmp = strlen(s:vimit_printed)
            if s:VIMIT_eval(cond, a:name . "#" . cond_name) != 0
                let result = s:VIMIT_parse(a:string[n:strlen(a:string)-1], a:name . "#" . cond_name)
                if result >= 0
                    let result = s:VIMIT_cond_len(a:string[n:strlen(a:string)-1])
                    if result >= 0
                        let n += result
                    endif
                    let parse_state = "text"
                else
                    call s:VIMIT_clear_states(a:name . "#" . cond_name)
                    call s:VIMIT_backtrack(strlen(s:vimit_printed)-printed_tmp)
                    let result = s:VIMIT_rep_len(a:string[n:strlen(a:string)-1])
                    if result >= 0
                        let n += result
                    endif
                    let parse_state = "text"
                    if len(split(a:name, '#')) > 1
                        return -1
                    endif
                endif
            else
                let result = s:VIMIT_cond_len(a:string[n:strlen(a:string)-1])
                if result >= 0
                    let n += result
                endif
                if len(split(a:name, '#')) > 1
                    return n
                endif
                let parse_state = "text"
            endif
            let cond_name = ""
            let cond = ""
        else
            for key in keys(s:vimit_groups)
                call s:VIMIT_clear_states(key)
                unlet s:vimit_groups[key]
            endfor
            call s:VIMIT_reset(a:name)
            return -1
        endif
        let n += 1
    endwhile
    for key in keys(s:vimit_groups)
        call s:VIMIT_clear_states(key)
        unlet s:vimit_groups[key]
    endfor
    call s:VIMIT_reset(a:name)
    let s:vimit_printed = ""
    return 1
endfunction

function! s:VIMIT_record()
    if vimit_record_mode == 0
        let s:vimit_record_mode_line = line('.')
        let s:vimit_record_mode_col = line('.')
        let s:vimit_record_mode = 1
    else
        let col = col('.')
    endif
    echo "test"
endfunction

"execute from register
function! VIMIT_reg()
    echo "Register to use:"
    let c = nr2char(getchar())
    redraw
    call s:VIMIT_parse(getreg(c), c)
    "try
    "    call s:VIMIT_parse(getreg(c), c)
    "catch
    "    call s:VIMIT_clear_states(c)
    "    call s:VIMIT_reset(c)
    "endtry
endfunction

"noremap <silent> <unique> <script> <Plug>VIMIT_reg :set lz<CR>:call <SID>VIMIT_reg()<CR>:set nolz<CR>

"Public
if !hasmapto("VIMIT_reg()")
    nnoremap <unique> <leader>t :call VIMIT_reg()<CR>
endif






