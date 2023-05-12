(** Globally accessible flags and utility functions. *)

open GoblintCil
open GobConfig


(** Outputs information about what the goblin is doing *)
(* let verbose = ref false *)

(** The file where everything is output *)
let out = ref stdout

(** Command for assigning an id to a varinfo. All varinfos directly created by Goblint should be modified by this method *)
let create_var (var: varinfo) =
  (* TODO Hack: this offset should preempt conflicts with ids generated by CIL *)
  let start_id = 10_000_000_000 in
  let hash = Hashtbl.hash { var with vid = 0 } in
  let hash = if hash < start_id then hash + start_id else hash in
  { var with vid = hash }

(* Type invariant variables. *)
let type_inv_tbl = Hashtbl.create 13
let type_inv (c:compinfo) : varinfo =
  try Hashtbl.find type_inv_tbl c.ckey
  with Not_found ->
    let i = create_var (makeGlobalVar ("{struct "^c.cname^"}") (TComp (c,[]))) in
    Hashtbl.add type_inv_tbl c.ckey i;
    i

let is_blessed (t:typ): varinfo option =
  let me_gusta x = List.mem x (get_string_list "exp.unique") in
  match unrollType t with
  | TComp (ci,_) when me_gusta ci.cname -> Some (type_inv ci)
  | _ -> (None : varinfo option)


(** Another hack to see if earlyglobs is enabled *)
let earlyglobs = ref false


let dummy_obj = Obj.repr ()

let jobs () =
  match get_int "jobs" with
  | 0 -> Cpu.numcores ()
  | n -> n
