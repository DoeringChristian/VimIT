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
    if !has_key(s:vimit_var_set, var_name) || s:vimit_var_set[var_name] == 0
        redraw
        let in = input("var " . var_name . a:format . ":")
        let in_split = split(in, ';')
        if empty(in)
            let in_split = split(s:vimit_var_expr[var_name], ';')
            for expr in in_split
                let n = s:vimit_var_state[var_name]
                try
                    let s:vimit_var_state[var_name] = eval(expr)
                catch
                    let s:vimit_var_state[var_name] = eval("\"" . expr . "\"")
                endtry
            endfor
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
    else
        call s:VIMIT_insert(s:vimit_var_state[var_name])
    endif
    let s:vimit_var_set[var_name] = 1
endfunction

"parse string
function! s:VIMIT_parse(string)
    let parse_state = "text"
    let var_name = ""
    let var_format = ""
    let s:vimit_printed = ""
    let n = 0
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
            elseif (c >= char2nr('a') && c <= char2nr('z') || c >= char2nr('A') && c <= char2nr('Z') || c >= char2nr('0') && c <= char2nr('9'))
                let var_name = char
                let parse_state = "var_name_nb"
            else
                let parse_state = "error"
            endif
        elseif parse_state == "var_name" 
            if (c >= char2nr('a') && c <= char2nr('z') || c >= char2nr('A') && c <= char2nr('Z') || c >= char2nr('0') && c <= char2nr('9'))
                let var_name .= char
                let parse_state = "var_name"
            elseif char == '%'
                let var_format = '%'
                let parse_state = "format"
            elseif char == ')'
                call s:VIMIT_input(var_name, "")
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
                call s:VIMIT_input(var_name, var_format)
                let parse_state = "text"
            endif
        elseif parse_state == "var_name_nb"
            if (c >= char2nr('a') && c <= char2nr('z') || c >= char2nr('A') && c <= char2nr('Z') || c >= char2nr('0') && c <= char2nr('9'))
                let var_name .= char
                let parse_state = "var_name_nb"
            elseif char == '%'
                let var_format = '%'
                let parse_state = "format_nb"
            else
                call s:VIMIT_input(var_name, "")
                call s:VIMIT_insert(char)
                let parse_state = "text"
            endif
        elseif parse_state == "format_nb"
            if char != ' '
                let var_format .= char
                let parse_state = "format_nb"
            else
                let s:vimit_var_format[var_name] = var_format
                call s:VIMIT_input(var_name, var_format)
                call s:VIMIT_insert(char)
                let parse_state = "text"
            endif
        else

        endif
        let n += 1
    endwhile
    for key in keys(s:vimit_var_set)
        let s:vimit_var_set[key] = 0
    endfor

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
    call s:VIMIT_parse(getreg(c))
endfunction

"noremap <silent> <unique> <script> <Plug>VIMIT_reg :set lz<CR>:call <SID>VIMIT_reg()<CR>:set nolz<CR>

"Public
if !hasmapto("VIMIT_reg()")
    nnoremap <unique> t :call VIMIT_reg()<CR>
endif






