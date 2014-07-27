open Types
open Ast
open Printf

type token =
    |Goto of int
    |Left
    |Right
    |Incr
    |Decr
    |Out
    |In
    |OBrac
    |CBrac
    |Debug of string

type brainfuck = token list

(* string_of_token : token -> string *)
let string_of_token = function
    |Goto x -> sprintf "Goto(%d)" x
    |Left -> "Left"
    |Right -> "Right"
    |Incr -> "Incr"
    |Decr -> "Decr"
    |Out -> "Out"
    |In -> "In"
    |OBrac -> "OBrac"
    |CBrac -> "CBrac"
    |Debug x -> sprintf "Debug(%s)" x

(* string_of_brainfuck : brainfuck -> string *)
let rec string_of_brainfuck = function
    |[] -> ""
    |t::[] -> string_of_token t
    |t::q -> (string_of_token t) ^ ", " ^ (string_of_brainfuck q)

(* compile_brainfuck : brainfuck -> string *)
let compile_brainfuck =
    let rec aux pos = function
        |[] -> ""
        |Goto(x)::q ->
            if x >= pos then (String.make (x - pos) '>') ^ (aux x q)
            else (String.make (pos - x) '<') ^ (aux x q)
        |Left::q -> "<" ^ (aux (pos - 1) q)
        |Right::q -> ">" ^ (aux (pos + 1) q)
        |Incr::q -> "+" ^ (aux pos q)
        |Decr::q -> "-" ^ (aux pos q)
        |Out::q -> "." ^ (aux pos q)
        |In::q -> "," ^ (aux pos q)
        |OBrac::q -> "[" ^ (aux pos q)
        |CBrac::q -> "]" ^ (aux pos q)
        |Debug(x)::q -> x ^ (aux pos q)
    in
    aux 0

(* repeat : 'a -> int -> 'a list *)
let repeat x n =                      
    let rec aux p accu =
        if p = 0 then accu else aux (p-1) (x::accu) in
    aux n []

(* range : int -> int -> int list *)
let range a b =
    let rec aux accu p =
        if p < a then accu else aux (p::accu) (p-1) in
    aux [] b;;

(* helpful operations *)
(* see http://esolangs.org/wiki/Brainfuck_algorithms *)

(* bf_clean : int -> brainfuck
 * reset the value in x
 *
 * precondition: no
 * postcondition: x' = 0 *)
let bf_clean x = [Goto(x); OBrac; Decr; CBrac]

(* bf_move : int -> int -> brainfuck
 * move the value from src to dst
 *
 * precondition: dst = 0
 * postcondition: src' = 0 && dst' = src *)
let bf_move src dst = [Goto(src); OBrac; Goto(dst); Incr; Goto(src); Decr; CBrac]

(* bf_copy : int -> int -> int -> brainfuck
 * copy the value from src to dst
 *
 * precondition: dst = 0 && temp = 0
 * condition: src = src' = dst' && temp' = 0 *)
let bf_copy src dst temp = [
    Goto(src); OBrac; Goto(dst); Incr; Goto(temp); Incr; Goto(src); Decr; CBrac;
    Goto(temp); OBrac; Goto(src); Incr; Goto(temp); Decr; CBrac]

(* bf_add : int -> int -> brainfuck
 * add y to x
 *
 * precondition: no
 * postcondition: x' = x + y && y' = 0
 *)
let bf_add x y = [Goto(y); OBrac; Goto(x); Incr; Goto(y); Decr; CBrac]

(* bf_sub : int -> int -> brainfuck
 * subtract y to x
 *
 * precondition: no
 * postcondition: x' = x - y && y' = 0
 *)
let bf_sub x y = [Goto(y); OBrac; Goto(x); Decr; Goto(y); Decr; CBrac]

(* bf_mul : int -> int -> int -> int -> brainfuck
 * multiply y to x
 *
 * precondition: temp1 = 0 && temp2 = 0
 * postcondition: x' = x * y && y' = y && temp1' = temp2' = 0 *)
let bf_mul x y temp1 temp2 = [
    Goto(x); OBrac; Goto(temp2); Incr; Goto(x); Decr; CBrac;
    Goto(temp2); OBrac;
        Goto(y); OBrac; Goto(x); Incr; Goto(temp1); Incr; Goto(y); Decr; CBrac;
        Goto(temp1); OBrac; Goto(y); Incr; Goto(temp1); Decr; CBrac;
    Goto(temp2); Decr;
    CBrac]

(* bf_div : int -> int -> int -> int -> int -> int -> brainfuck
 * divide x by y
 *
 * precondition: temp1 = temp2 = temp3 = temp4 = 0
 * postcondition: x' = x / y && y' = y && temp1' = temp2' = temp3' = temp4' = 0 *)
let bf_div x y temp1 temp2 temp3 temp4 = [
    Goto(x); OBrac; Goto(temp1); Incr; Goto(x); Decr; CBrac;
    Goto(temp1);
    OBrac;
        Goto(y); OBrac; Goto(temp2); Incr; Goto(temp3); Incr; Goto(y); Decr; CBrac;
        Goto(temp3); OBrac; Goto(y); Incr; Goto(temp3); Decr; CBrac;
        Goto(temp2);
        OBrac;
            Goto(temp3); Incr;
            Goto(temp1); Decr; OBrac; Goto(temp3); OBrac; Decr; CBrac; Goto(temp4); Incr; Goto(temp1); Decr; CBrac;
            Goto(temp4); OBrac; Goto(temp1); Incr; Goto(temp4); Decr; CBrac;
            Goto(temp3);
            OBrac;
                Goto(temp2); Decr;
                OBrac; Goto(x); Decr; Goto(temp2); OBrac; Decr; CBrac; CBrac; Incr;
                Goto(temp3); Decr; CBrac;
            Goto(temp2); Decr;
            CBrac;
        Goto(x); Incr;
        Goto(temp1);
    CBrac]

(* bf_minus : int -> int -> brainfuck
 * x = -x
 *
 * precondition: temp = 0
 * postcondition: x' = -x && temp' = 0 *)
let bf_minus x temp = [
    Goto(x); OBrac; Goto(temp); Decr; Goto(x); Decr; CBrac;
    Goto(temp); OBrac; Goto(x); Decr; Goto(temp); Incr; CBrac]

(* bf_eq : int -> int -> brainfuck
 * x = x == y
 *
 * precondition: no
 * postcondition: x' = x == y && y' = 0 *)
let bf_eq x y = [
    Goto(x); OBrac; Decr; Goto(y); Decr; Goto(x); CBrac;
    Incr; Goto(y); OBrac; Goto(x); Decr; Goto(y); OBrac; Decr; CBrac; CBrac]

(* bf_not : int -> int -> brainfuck
 * x = not x
 *
 * precondition: temp = 0
 * postcondition: x' = not x && temp' = 0 *)
let bf_not x temp = [
    Goto(x); OBrac; Goto(temp); Incr; Goto(x); OBrac; Decr; CBrac; CBrac; Incr;
    Goto(temp); OBrac; Goto(x); Decr; Goto(temp); Decr; CBrac]

(* bf_and : int -> int -> int -> int -> brainfuck
 * x = x and y
 *
 * precondition: temp1 = temp2 = 0
 * postcondition: x' = x and y && y' = y && temp1 = temp2 = 0 *)
let bf_and x y temp1 temp2 = [
    Goto(x); OBrac; Goto(temp2); Incr; Goto(x); Decr; CBrac;
    Goto(temp2);
    OBrac;
        Goto(temp2); OBrac; Decr; CBrac;
        Goto(y); OBrac; Goto(temp2); Incr; Goto(temp1); Incr; Goto(y); Decr; CBrac;
        Goto(temp1); OBrac; Goto(y); Incr; Goto(temp1); Decr; CBrac;
        Goto(temp2); OBrac; Goto(x); Incr; Goto(temp2); OBrac; Decr; CBrac; CBrac;
    CBrac]

(* bf_or : int -> int -> int -> brainfuck
 * x = x or y
 *
 * precondition: temp = 0
 * postcondition: x' = x or y && y' = temp' = 0 *)
let bf_or x y temp = [
    Goto(x); OBrac; Goto(temp); Incr; Goto(x); Decr; CBrac;
    Goto(temp); OBrac; Goto(x); Incr; Goto(temp); OBrac; Decr; CBrac; CBrac;
    Goto(y); OBrac; Goto(x); Incr; Goto(y); OBrac; Decr; CBrac; CBrac;
    Goto(x); OBrac; Goto(temp); Incr; Goto(x); Decr; CBrac;
    Goto(temp); OBrac; Goto(x); Incr; Goto(temp); OBrac; Decr; CBrac; CBrac]

(* bf_inf_eq : int -> int -> int -> brainfuck
 * x = x <= y
 *
 * precondition: temp = temp + 1 = temp + 2 = 0
 * postcondition: x' = x <= y && y' = temp' = temp'+1 = temp'+2 = 0 *)
let bf_inf_eq x y temp = [
    Goto(temp + 1); Incr;
    Goto(x); OBrac; Goto(temp); Incr; Goto(x); Decr; CBrac;
    Goto(temp); OBrac; Right; Decr; CBrac; Right; OBrac; Debug(">"); Goto(x); Incr; Goto(y); OBrac; Decr; CBrac; Goto(temp); Right; Decr; Right; CBrac; Left; Incr;
    Goto(y); OBrac; Goto(temp); Decr; OBrac; Right; Decr; CBrac; Right; OBrac; Debug(">"); Goto(x); Incr; Goto(y); OBrac; Decr; CBrac; Incr; Goto(temp); Right; Decr; Right; CBrac; Left; Incr; Goto(y); Decr; CBrac;
    Goto(temp); OBrac; Decr; CBrac;
    Goto(temp + 1); Decr]

(* program_to_brainfuck : program -> brainfuck *)
let program_to_brainfuck prog =
    (* bf_clean_range: int -> int -> brainfuck *)
    let bf_clean_range a b =
        List.fold_left (fun r pos -> bf_clean pos @ r) [] (range a b)
    in
    (* compute the expression and put the result in the position `pos`
     *
     * warning: don't assume anything about the cursor position
     * precondition: for all x > pos, V[x] = 0
     * postcondition: for all x > pos, V[x] = 0 *)
    let rec compile_expression symbols_table pos = function
        |Var name ->
            let var_pos = List.assoc name symbols_table in
            bf_copy var_pos pos (pos + 1)

        (* constants *)
        |Const(IntConst x) -> Goto(pos)::(repeat Incr x)
        |Const(BoolConst true) -> [Goto(pos); Incr]
        |Const(BoolConst false) -> []
        |Const(CharConst c) -> Goto(pos)::(repeat Incr (int_of_char c))

        (* operators *)
        |Add(left, right) ->
            let left_bf = compile_expression symbols_table pos left in
            let right_bf = compile_expression symbols_table (pos + 1) right in
            left_bf @ right_bf @ bf_add pos (pos + 1)
        |Sub(left, right) ->
            let left_bf = compile_expression symbols_table pos left in
            let right_bf = compile_expression symbols_table (pos + 1) right in
            left_bf @ right_bf @ bf_sub pos (pos + 1)
        |Mul(left, right) ->
            let left_bf = compile_expression symbols_table pos left in
            let right_bf = compile_expression symbols_table (pos + 1) right in
            left_bf @ right_bf @ bf_mul pos (pos + 1) (pos + 2) (pos + 3) @ bf_clean(pos + 1)
        |Div(left, right) ->
            let left_bf = compile_expression symbols_table pos left in
            let right_bf = compile_expression symbols_table (pos + 1) right in
            left_bf @ right_bf @ bf_div pos (pos + 1) (pos + 2) (pos + 3) (pos + 4) (pos + 5) @ bf_clean (pos + 1)
        |Minus expr ->
            let expr_bf = compile_expression symbols_table pos expr in
            expr_bf @ bf_minus pos (pos + 1)
        |InfEq(left, right) ->
            let left_bf = compile_expression symbols_table pos left in
            let right_bf = compile_expression symbols_table (pos + 1) right in
            left_bf @ right_bf @ bf_inf_eq pos (pos + 1) (pos + 2)
        |Inf(left, right) ->
            let left_bf = compile_expression symbols_table pos left in
            let right_bf = compile_expression symbols_table (pos + 1) right in
            (* x < y <=> x + 1 <= y *)
            left_bf @ [Goto(pos); Incr] @ right_bf @ bf_inf_eq pos (pos + 1) (pos + 2)
        |Eq(left, right) ->
            let left_bf = compile_expression symbols_table pos left in
            let right_bf = compile_expression symbols_table (pos + 1) right in
            left_bf @ right_bf @ bf_eq pos (pos + 1)
        |NotEq(left, right) ->
            (* x != y <=> not(x == y) *)
            compile_expression symbols_table pos (Not(Eq(left, right)))
        |Sup(left, right) ->
            (* x > y <=> not(x <= y) *)
            compile_expression symbols_table pos (Not(InfEq(left, right)))
        |SupEq(left, right) ->
            (* x >= y <=> not(x < y) *)
            compile_expression symbols_table pos (Not(Inf(left, right)))
        |And(left, right) ->
            let left_bf = compile_expression symbols_table pos left in
            let right_bf = compile_expression symbols_table (pos + 1) right in
            left_bf @ right_bf @ bf_and pos (pos + 1) (pos + 2) (pos + 3) @ bf_clean (pos + 1)
        |Or(left, right) -> 
            let left_bf = compile_expression symbols_table pos left in
            let right_bf = compile_expression symbols_table (pos + 1) right in
            left_bf @ right_bf @ bf_or pos (pos + 1) (pos + 2)
        |Not expr ->
            let expr_bf = compile_expression symbols_table pos expr in
            expr_bf @ bf_not pos (pos + 1)
        |ReadChar -> [Goto(pos); In]
    in
    (* compile the program : (string * int) list -> int -> brainfuck * int *)
    let rec compile_program symbols_table offset = function
        |[] -> [], offset
        |Define(_, name, expr)::q ->
            let bf_expr = compile_expression symbols_table offset expr in
            let bf_end, offset_end = compile_program ((name, offset)::symbols_table) (offset + 1) q in
            bf_expr @ bf_end, offset_end
        |Assign(name, expr)::q ->
            let var_pos = List.assoc name symbols_table in
            let bf_expr = compile_expression symbols_table offset expr in
            let bf_end, offset_end = compile_program symbols_table offset q in
            bf_expr @ (bf_clean var_pos) @ (bf_move offset var_pos) @ bf_end, offset_end
        |WriteChar(expr)::q ->
            let bf_expr = compile_expression symbols_table offset expr in
            let bf_end, offset_end = compile_program symbols_table offset q in
            bf_expr @ [Goto(offset); Out] @ (bf_clean offset) @ bf_end, offset_end
        |If(cond, statements_true, statements_false)::q ->
            let bf_cond = compile_expression symbols_table offset cond in
            let bf_true, offset_true = compile_program symbols_table (offset + 2) statements_true in
            let bf_clean_true = bf_clean_range (offset + 2) (offset_true - 1) in
            let bf_false, offset_false = compile_program symbols_table (offset + 2) statements_false in
            let bf_clean_false = bf_clean_range (offset + 2) (offset_false - 1) in
            let bf_end, offset_end = compile_program symbols_table offset q in
            bf_cond
            @ [Goto(offset + 1); Incr; Goto(offset); OBrac]
            @ bf_true @ bf_clean_true
            @ [Goto(offset + 1); Decr] @ (bf_clean offset)
            @ [CBrac; Goto(offset + 1); OBrac]
            @ bf_false @ bf_clean_false
            @ [Goto(offset + 1); Decr; CBrac]
            @ bf_end, offset_end
        |While(cond, statements)::q ->
            let bf_cond = compile_expression symbols_table (offset + 1) cond in
            let bf_statements, offset_statements = compile_program symbols_table (offset + 2) statements in
            let bf_clean_statements = bf_clean_range (offset + 2) (offset_statements - 1) in
            let bf_end, offset_end = compile_program symbols_table offset q in
            [Goto(offset); Incr; OBrac]
            @ bf_cond @ [Goto(offset + 1); OBrac]
            @ bf_statements @ bf_clean_statements
            @ (bf_clean (offset + 1))
            @ [Goto(offset); Incr; Goto(offset+1); CBrac; Goto(offset); Decr; CBrac]
            @ bf_end, offset_end
        |For(init, cond, incr, statements)::q ->
            let bf_for, offset_for = compile_program symbols_table offset [init; While(cond, statements @ [incr])] in
            let bf_clean_for = bf_clean_range offset (offset_for - 1) in
            let bf_end, offset_end = compile_program symbols_table offset q in
            bf_for @ bf_clean_for @ bf_end, offset_end
    in
    fst (compile_program [] 0 prog)