# VimIT: Vim Interactive Template

## Introduction

VimIT enables you to write repetitive structures more efficiently.
Programming for embedded systems often requires writing similar 
lines of code with minor differences for example when defining GPIO-registers
```c
#define GPIOA *((uint32_t *)0x40014000)
#define GPIOB *((uint32_t *)0x40014004)
...
```
Most of the time these values are given by a datasheet and only have to be implemented.
This takes far to long by hand. There are snippet plugins for Vim such as [ultisnap](https://github.com/sirver/UltiSnips)
or [vim-snipmate](https://github.com/garbas/vim-snipmate) but these are made to simplify structures
used in a programming language as a whole. VimIT is made to be a simpler and more light weight
solution where you are easily able write your templates on the fly. 

## Writing a Template:

After installing it ([guide](#installation)) you can use VimIT as it is.
To create a template write it any where you want or just copy one from the internet.
The structure of a template can be as follows:
```c
#define $regname *((uint32_t *)0x$(regaddr%08x))
```
Variables are denoted with a "$" symbol and their name can either be inside a bracket or 
terminated with a whitespace. It is also possible to specify a format string after the
variable name (e.g. "%08x", "%f", "%d") these are the standard format strings for
c-like printf functions as used by Vim.

## Printing a Template:

Templates can be printed into your programm by pressing "<leader>t" followed by the register in which
the template is located. If you have written the template in the same document you have to
copy it into a register. VimIT will now parse the template and the first time it encounters an undefined
variable it will ask you to enter a list of expressions for this variable. These expressions 
are delimited with a semicolon ";" (e.g. 10;n+2 "GPIOA" GPIOA). The variable will be set to the first expression once you
hit enter. Any subsequent expressions are saved and will be applied once the template is printed
again. In the expressions "n" refers to the last instance of the variable. VimIT tries to evaluate
the expressions as mathematical ones if it fails it will evaluate it as a string, therefore you can
enter alphanumerical strings without using quotation marks.

## Installation 
    1. using vim-plug:
        put this in your .vimrc file: Plug 'DoeringChristian/VimIT'
    2. manually:
        put the plugins folder into your .vim folder.

