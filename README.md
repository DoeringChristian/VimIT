# VimIT: Vim Interactive Template

VimIT is an interactive template plugin for [Vim](https://github.com/vim/vim) and [neovim](https://github.com/neovim/neovim). You can use it to write repetitive structures more efficiently by using a snippet like language.

## Rationale 

Programming for embedded systems often requires writing similar 
lines of code with minor differences for example when defining GPIO-registers
```c
#define GPIOA *((uint32_t *)0x40014000)
#define GPIOB *((uint32_t *)0x40014004)
...
```
Most of the time the values are given by a datasheet and only have to be implemented.
This takes far to long by hand. Unfortunately Vim provides no such feature out of the box 
(Vim provides macros but they are only siutable for operations that do not change). 
Of course there are snippet plugins for Vim such as [utilsnip](https://github.com/sirver/UltiSnips)
or [vim-snipmate](https://github.com/garbas/vim-snipmate) but these are made to simplify structures
used in a programming language and their snipptets are supposed to be stored in a file. VimIT is made to be a simpler and more light weight
solution where you are easily able write your templates on the fly. 

# Usage

## Writing a Template:

### A simple Template

After installing it ([guide](#installation)) you can use VimIT as it is.
To create a template write it any where you want or just copy one from the internet.
The structure of a simple template can be as follows:
```c
#define $regname *((uint32_t *)0x$($regaddr%08x))
```
Variables are denoted with a "$" symbol and their name can either be inside a bracket or 
terminated with a whitespace. There are string and number variables. String variables can only contain strings whereas number variables can contain both.
Number variables are explicitly declared with a "$" symbol inside the bracket (they can not be declated without brackets). 
It is also possible to specify a format string after the
variable name (e.g. "%08x", "%f", "%d") these are the standard format strings for
the c-like printf functions as used by Vim. 

### Groups and Repeating variables in Templates

To repeat a variable within a template n times a group has to be used. The structure of a group in ebnf is as follows:
```ebnf
<group> ::= "${" <group_name> ":" <group_content> "$}" ["*"]
```
Where <group_content> can be anny group, variable, text or condition. 
Groups can also be repeated a constant ammount of times or n times inside a template.
```c
struct $(struct_name)_ops{
    ${functions:$(ret) (*$(_struct_name)_$(function_name))($(to_pass));$}*
};

${functions:$(ret) $(_struct_name)_$(function_name)($(to_pass));
$}*
```
The "*" after the group indicates that when printing the template it can be repeated n times.
Variables inside a group are in their own scope. To acces a variable in the global scope, a "_" has to be prepended.
The "_" to specify the use of a global variable has to be put after the "$" symbol to specify a number variable.
It is possible to recursively use groups for example:
```c
${functions:void $(function_name)(${to_pass$}*)$}*
```

### Conditionals

Anny text, variable or group can be inserted conditionally. The structure of a condition in ebnf is as follows:
```ebnf
<condition> ::= "$[" <condition_name> ":" <condition> "?" <condition_content> "$]"
```
The condition_name is the name of the condition similar to the name of a group it initializes a scope. A condition can be anny valid 
vim expression where anny variable defined beforehand can be used, example:
```c
$(ret) $(function_name)($(to_pass)){

    $[returned:$(_ret)!="void"?return ;$]
}
```
Variables used in a condition have to be accessed through the global prefix "_" bacause the condition has its own scope.
Predifined variables can be used currentyl: FILENAME EXTENSION FULL_PATH DIRECTORY. They are normal vim variables and can be either
accessed in an expression as such or using VimIT variables.

## Printing a Template:

Templates can be printed into your programm by pressing "<leader>t" followed by the register in which
the template is located. If you have written the template in the same document you have to
copy it into a register first. VimIT will now parse the template and the first time it encounters an undefined
variable it will either ask you to enter a list of exprssion (if the variable is defined as a number variable) or a string (if it has been defined as a string). Expressions 
are delimited with a semicolon ";" (e.g. 10;n+2 "GPIOA" GPIOA). The variable will be set to the first expression once it has been entered.
Any subsequent expressions are saved and will be applied once the template is printed again.
In the expressions "n" refers to the last instance of the variable. The variables FILENAME, EXTENSION, FULL_PATH and DIRECTORY can also be used. VimIT tries to evaluate
the expressions of number variables as vim internal expressions if it fails it will evaluate it as a string, therefore you can
enter alphanumerical strings in number variables without using quotation marks though this is not recomended.
When printing a template again anny expressions of number variables can be applied by pressing enter without entering anny number or text.
In a repeating group entering an empty string will result in the termination of that repitition.

## Installation 
    1. using vim-plug:
        put this in your .vimrc file: Plug 'DoeringChristian/VimIT'
    2. manually:
        put the plugins folder into your .vim folder.

