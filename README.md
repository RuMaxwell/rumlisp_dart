# RUMLISP dart

Dart version of **RUMLISP** project. This will be the only main and long-term implementation of RUMLISP.

> The first implementation: [rumlisp-hs](https://github.com/RuMaxwell/rumlisp-hs).

**RUMLISP** is a Lisp dialect. Features are expanding.

Now its main features are implemented and it is stable enough to be a formal version (1.0).

## Features
```
[+] Types
    [+] Numeric types
        [*] Int (64-bit), Float (64-bit ISO-IEEE Double)
        [ ] Integer (big int), Complex, Fraction (Exact real number)
    [*] Boolean type
    [ ] Basic functional types
        String [, Enum, Tuple], List [, Array], Map (Dictionary)
    [*] Function type
        Functions as closures.
    [ ] User-defined data types
        Object, arithmetic data type, record type
[+] Typing system
    [+] Dynamic, strong
        [*] Runtime simple type-checking
        [ ] Type inference
        [ ] Type synonym
[*] Functions
    [*] One-argument lambda function
    [*] Multiple-argument lambda function (uncurrying)
    [*] Named-function
        [*] Global function
        [*] Self-recursive function
    [*] Closure (lexical-scoping)
    [*] Function as data
        [*] First-order function
        [*] Function passed as value
    [*] Typing of a function
        [*] Dynamic argument types (Int or Lambda)
        [*] Dynamic evaluation type (Int or Lambda)
[+] Practicability / IO / Operating Systems
    [*] Numeric computation
    [ ] String operations
    [ ] Standard input / output
    [ ] File system operations
[+] Macros
    [ ] Environment import
        Simple pattern substitution, which enables importing environment (`let` bindings) from multiple files.
    [ ] User-defined syntax
        Powerful code generator. Produce endless fun and flexibility.
[*] Characteristics
    [*] Absolutely immutable data
    [*] Functional programming
```

## How to Use

### Install

Install the Dart language at first, clone this repo, go into the directory, and then invoke

```bash
$ dart ./bin/main.dart <with_some_directions>
```

You can use `--help` flag to do what you think it is.

### Write programs

If you are familiar with other Lisp dialects, you will probably get almost all you need for writing rumlisp programs, rarely from reading the examples in the `example` directory. However I still give some notes of the language here (last changed: stable version 1.0):

1. A program can contain more than 1 expressions, and produce only more than 1 result;
2. There's **no** way of **input** (now), and the only way of output is the program showing the exact one result;
3. **No strings** (now), if you type something enclosed by quotes, it is treated as an identifier;
4. Identifiers can be everything excepts for what is a number. e.g. `+1, '', 5apples` are all identifiers;
5. **Currying** is implemented by nature;
6. Source file extension doesn't matter;
7. Comments are surrounded by `;` and another `;`;
8. Booleans are represented by `#t` and `#f`, following Common Lisp style.

### Basic program structure

To write a program, you usually writes several `let` bindings at the beginning like:

```rumlisp
(def globalConstant (...))
(def (globalFunction args...) (...))

(let foo (...)
(let bar (...)
(let baz (...)
    ; comments ;
    (do-something))))
```

Notice that there's no multiple-bindings-at-once feature. If you bind two things with one name, the inner will shadow the outer, as the implementation checks bindings that come later first.

### Function definition

You can define functions in two ways, **lambda** or **named**. By defining a lambda function you do not specify the name. This lambda function is approximately that lambda expression in Lambda Calculus Theory (wiki). There's no way to reference itself if you want to create a recursive function. One way to create recursive function with lambda is using a programmable Y-combinator (see the example in `example/fact.rlsp`). The Y-combinator defined in the Wiki page is not programmable due to creating infinite function construction.

Syntax of defining a lambda function:

```rumlisp
(\ <bindName> <boundExpression>)
```

or

```rumlisp
(\ (<bindName> [<bindName>]*) <boundExpression>)
```

This creates a lambda function that takes one or several `bindName` as argument(s) and `boundExpression` as the "function body". e.g.

```rumlisp
(let ++ (\ x (+ x 1))
    (++ 1))             ; 2 ;

(let add2 (\ (x y) (+ x y))
    (add2 1 2))         ; 3 ;
```

The function body can reference values outside of the lambda itself (which is called a *free variable*), causing it to be enclosed in the function *closure*. Because the language is lexically scoped, and values are immutable, no matter where you invoke the lambda function, the bound free variables will always keep what they initially are when creating the lambda. e.g. Following `(f 1)` is always `1` wherever `f` is invoked.

```rumlisp
(let x 1
(let f (\ _ x)
    (f 0)))            ; 1 ;

(let x 1
(let f (\ _ x)
(let x 2
    f)))               ; 1 ;
```

Another method to create a function is `def` which creates named functions. These functions are created in their sequence of definition, and stored globally. e.g.

```rumlisp
(def (++ x) (+ x 1))
(++ 1)                 ; 2 ;
```

The syntax of `def` is to put a function invocation at the second item of the expression. For example, if you want to have a function invoked like `(f 1 2 3)`, you should define it like `(def (f a b c) ...)`.

While it is most usual to define a function, `def` syntax can also define global constants:

```rumlisp
; Define a constant name ;
(def DEFAULT_LEN 100)
(def DEFAULT_AREA (* DEFAULT_LEN DEFAULT_LEN))
(DEFAULT_AREA)          ; 10000 ;

; Define a constant function (equals to a constant name) ;
(def (width) 6)
(def (rectArea height) (* width height))
(rectArea width)        ; 36 ;
```


