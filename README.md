# RUMLISP dart

Dart version of **RUMLISP** project. This will be the only main and long-term implementation of RUMLISP.

> The first implementation: [rumlisp-hs](https://github.com/RuMaxwell/rumlisp-hs).

**RUMLISP** is a LISP dialect. Features are expanding.

## Features
```
[+] Types
    [+] Numeric types
        [*] Int (64-bit), Float (64-bit ISO-IEEE Double)
        [ ] Integer (big int), Complex, Fraction (Exact real number)
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
