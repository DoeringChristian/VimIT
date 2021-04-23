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

"wip
function! s:VIMIT_eval(expr, var_name)
    let n = s:vimit_var_state[a:var_name]
    let s:vimit_var_state[a:var_name] = eval(a:expr)
endfunction

"get user input and evaluate expressions
function! s:VIMIT_input(name, format)
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
            let in_split = split(s:vimit_var_expr[var_name], ';')
            for expr in in_split
                let n = s:vimit_var_state[var_name]
                try
                    let s:vimit_var_state[var_name] = eval(expr)
                catch
                    let s:vimit_var_state[var_name] = eval("\"" . expr . "\"")
                endtry
            endfor
        elseif empty(in)
            let input = 0
        else
            try
                let s:vimit_var_state[var_name] = eval(in_split[0])
            catch
                let s:vimit_var_state[var_name] = eval("\"" . in_split[0] . "\"")
            endtry
            call remove(in_split, 0)
            let s:vimit_var_expr[var_name] = join(in_split, ';')
        endif
    endif
    if has_key(s:vimit_var_format, var_name)
        call s:VIMIT_printf(s:vimit_var_format[var_name], s:vimit_var_state[var_name])
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
        let n+= 1
    endwhile
    return -1
endfunction
        

"parse string
function! s:VIMIT_parse(string, name)
    let parse_state = "text"
    let var_name = ""
    let rep_name = ""
    let rep_cont = ""
    let var_format = ""
    let s:vimit_printed = ""
    let n = 0
    let s:vimit_var_set[a:name] = 1
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
            elseif (c >= char2nr('a') && c <= char2nr('z') || c >= char2nr('A') && c <= char2nr('Z') || c >= char2nr('0') && c <= char2nr('9') || c == char2nr('_'))
                let var_name = char
                let parse_state = "var_name_nb"
            elseif char == '{'
                let rep_name = ""
                let parse_state = "rep_name"
            elseif char == '}'
                return n
            else
                let parse_state = "error"
            endif
        elseif parse_state == "var_name" 
            if (c >= char2nr('a') && c <= char2nr('z') || c >= char2nr('A') && c <= char2nr('Z') || c >= char2nr('0') && c <= char2nr('9') || c == char2nr('_'))
                let var_name .= char
                let parse_state = "var_name"
            elseif char == '%'
                let var_format = '%'
                let parse_state = "format"
            elseif char == ')'
                "global variables start with _
                let name = a:name . "#" . var_name
                if var_name[0] == '_'
                    let name = split(a:name, '#')[0] . "#" . var_name[1:strlen(var_name)-1]
                endif
                if s:VIMIT_input(name, "") == 0
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
                let s:vimit_var_format[var_name] = var_format
                let name = a:name . "#" . var_name
                if var_name[0] == '_'
                    let name = split(a:name, '#')[0] . "#" . var_name[1:strlen(var_name)-1]
                endif
                if s:VIMIT_input(name, "") == 0
                    return -1
                endif
                let parse_state = "text"
            endif
        elseif parse_state == "var_name_nb"
            if (c >= char2nr('a') && c <= char2nr('z') || c >= char2nr('A') && c <= char2nr('Z') || c >= char2nr('0') && c <= char2nr('9') || c == char2nr('_'))
                let var_name .= char
                let parse_state = "var_name_nb"
            elseif char == '%'
                let var_format = '%'
                let parse_state = "format_nb"
            else
                let name = a:name . "#" . var_name
                if var_name[0] == '_'
                    let name = split(a:name, '#')[0] . "#" . var_name[1:strlen(var_name)-1]
                endif
                if s:VIMIT_input(name, "") == 0
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
                let s:vimit_var_format[var_name] = var_format
                let name = a:name . "#" . var_name
                if var_name[0] == '_'
                    let name = split(a:name, '#')[0] . "#" . var_name[1:strlen(var_name)-1]
                endif
                if s:VIMIT_input(name, "") == 0
                    return -1
                endif
                call s:VIMIT_insert(char)
                let parse_state = "text"
            endif
        elseif parse_state == "rep_name"
            if (c >= char2nr('a') && c <= char2nr('z') || c >= char2nr('A') && c <= char2nr('Z') || c >= char2nr('0') && c <= char2nr('9') || c == char2nr('_'))
                let rep_name .= char
                let parse_state = "rep_name"
            elseif char == ':'
                let parse_state = "rep_cont"
            else
                let parse_state = "error"
            endif
        elseif parse_state == "rep_cont"
            let result = s:VIMIT_parse(a:string[n:strlen(a:string)-1], a:name . "#" . rep_name)
            if result >= 0
                if a:string[n+result+1] == '*'
                    let m = 1
                    let name = a:name . "#" . rep_name . m
                    while s:VIMIT_parse(a:string[n:strlen(a:string)-1], name) >= 0
                        let m += 1
                        let name = a:name . "#" . rep_name . m
                    endwhile
                    call s:VIMIT_clear_states(a:name . "#" . rep_name)
                    "backtrack using s:vimit_printed since it is reseted on
                    "start of s:VIMIT_parse
                    for j in str2list(s:vimit_printed)
                        if j == '\n'
                            call execute("normal! J")
                        else
                            call execute("normal! x")
                        endif
                    endfor
                    let n += 1
                endif
                let n += result
                let parse_state = "text"
            else
                call s:VIMIT_clear_states(a:name . "#" . rep_name)
                "backtrack
                for j in str2list(s:vimit_printed)
                    if j == '\n'
                        call execute("normal! J")
                    else
                        call execute("normal! x")
                    endif
                endfor
                let result = s:VIMIT_rep_len(a:string[n:strlen(a:string)-1])
                if result >= 0
                    let n += result
                endif
                let parse_state = "text"
            endif
        else
            call s:VIMIT_reset(a:name)
            return -1
        endif
        let n += 1
    endwhile
    call s:VIMIT_reset(a:name)
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
endfunction

"noremap <silent> <unique> <script> <Plug>VIMIT_reg :set lz<CR>:call <SID>VIMIT_reg()<CR>:set nolz<CR>

"Public
if !hasmapto("VIMIT_reg()")
    nnoremap <unique> <leader>t :call VIMIT_reg()<CR>
endif






