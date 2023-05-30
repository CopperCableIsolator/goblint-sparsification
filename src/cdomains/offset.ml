(** Domains for offsets. *)

open GoblintCil

(** Special index expression for some unknown index.
    Weakly updates array in assignment.
    Used for exp.fast_global_inits. *)
let any_index_exp = CastE (TInt (Cilfacade.ptrdiff_ikind (), []), mkString "any_index")

(** Special index expression for all indices.
    Strongly updates array in assignment.
    Used for Goblint-specific witness invariants. *)
let all_index_exp = CastE (TInt (Cilfacade.ptrdiff_ikind (), []), mkString "all_index")

type 'i t = [
  | `NoOffset
  | `Field of CilType.Fieldinfo.t * 'i t
  | `Index of 'i * 'i t
] [@@deriving eq, ord, hash]

type 'i offs = 'i t [@@deriving eq, ord, hash]

module Index =
struct

  (** Subinterface of IntDomain.Z which is sufficient for Printable (but not Lattice) Offset. *)
  module type Printable =
  sig
    include Printable.S
    val equal_to: IntOps.BigIntOps.t -> t -> [`Eq | `Neq | `Top]
    val to_int: t -> IntOps.BigIntOps.t option
  end

  module type Lattice = IntDomain.Z


  module Unit: Printable with type t = unit =
  struct
    include Printable.Unit
    let equal_to _ _ = `Top
    let to_int _ = None
  end

  module Exp: Printable with type t = exp =
  struct
    include CilType.Exp

    (* Override output *)
    let pretty () x =
      if equal x any_index_exp then
        Pretty.text "?"
      else
        dn_exp () x

    include Printable.SimplePretty (
      struct
        type nonrec t = t
        let pretty = pretty
      end
      )

    let equal_to _ _ = `Top (* TODO: more precise for definite indices *)
    let to_int _ = None (* TODO: more precise for definite indices *)
  end
end

module MakePrintable (Idx: Index.Printable) =
struct
  type t = Idx.t offs [@@deriving eq, ord, hash]
  include Printable.StdLeaf

  let name () = "offset"

  let is_first_field x = match x.fcomp.cfields with
    | [] -> false
    | f :: _ -> CilType.Fieldinfo.equal f x

  let rec cmp_zero_offset : t -> [`MustZero | `MustNonzero | `MayZero] = function
    | `NoOffset -> `MustZero
    | `Index (x, o) -> (match cmp_zero_offset o, Idx.equal_to (IntOps.BigIntOps.zero) x with
      | `MustNonzero, _
      | _, `Neq -> `MustNonzero
      | `MustZero, `Eq -> `MustZero
      | _, _ -> `MayZero)
    | `Field (x, o) ->
      if is_first_field x then cmp_zero_offset o else `MustNonzero

  let rec show = function
    | `NoOffset -> ""
    | `Index (x,o) -> "[" ^ (Idx.show x) ^ "]" ^ (show o)
    | `Field (x,o) -> "." ^ (x.fname) ^ (show o)

  include Printable.SimpleShow (
    struct
      type nonrec t = t
      let show = show
    end
    )

  let pretty_diff () (x,y) =
    Pretty.dprintf "%s: %a not leq %a" (name ()) pretty x pretty y

  let name () = "Offset"

  let from_offset x = x

  let rec is_definite = function
    | `NoOffset -> true
    | `Field (f,o) -> is_definite o
    | `Index (i,o) ->  Idx.to_int i <> None && is_definite o

  (* append offset o2 to o1 *)
  let rec add_offset o1 o2 =
    match o1 with
    | `NoOffset -> o2
    | `Field (f1,o1) -> `Field (f1,add_offset o1 o2)
    | `Index (i1,o1) -> `Index (i1,add_offset o1 o2)

  let rec remove_offset = function
    | `NoOffset -> `NoOffset
    | `Index (_,`NoOffset) | `Field (_,`NoOffset) -> `NoOffset
    | `Index (i,o) -> `Index (i, remove_offset o)
    | `Field (f,o) -> `Field (f, remove_offset o)

  let rec to_cil_offset (x:t) = (* TODO: rename/move *)
    match x with
    | `NoOffset -> NoOffset
    | `Field(f,o) -> Field(f, to_cil_offset o)
    | `Index(i,o) -> NoOffset (* array domain can not deal with this -> leads to being handeled as access to unknown part *)

  let rec to_exp: t -> exp offs = function
    | `NoOffset    -> `NoOffset
    | `Index (i,o) ->
      let i_exp = match Idx.to_int i with
        | Some i -> Const (CInt (i, Cilfacade.ptrdiff_ikind (), Some (Z.to_string i)))
        | None -> any_index_exp
      in
      `Index (i_exp, to_exp o)
    | `Field (f,o) -> `Field (f, to_exp o)

  let rec contains_index = function
    | `NoOffset -> false
    | `Field (_, os) -> contains_index os
    | `Index _ -> true
end

module MakeLattice (Idx: IntDomain.Z) =
struct
  include MakePrintable (Idx)

  let rec leq x y =
    match x, y with
    | `NoOffset, `NoOffset -> true
    | `Index (i1,o1), `Index (i2,o2) when Idx.leq i1 i2 -> leq o1 o2
    | `Field (f1,o1), `Field (f2,o2) when CilType.Fieldinfo.equal f1 f2 -> leq o1 o2
    | _ -> false

  let rec merge cop x y =
    let op = match cop with `Join -> Idx.join | `Meet -> Idx.meet | `Widen -> Idx.widen | `Narrow -> Idx.narrow in
    match x, y with
    | `NoOffset, `NoOffset -> `NoOffset
    | `Field (x1,y1), `Field (x2,y2) when CilType.Fieldinfo.equal x1 x2 -> `Field (x1, merge cop y1 y2)
    | `Index (x1,y1), `Index (x2,y2) -> `Index (op x1 x2, merge cop y1 y2)
    | _ -> raise Lattice.Uncomparable (* special case not used for AddressDomain any more due to splitting *)

  let join x y = merge `Join x y
  let meet x y = merge `Meet x y
  let widen x y = merge `Widen x y
  let narrow x y = merge `Narrow x y

  let rec drop_ints = function
    | `Index (x, o) -> `Index (Idx.top (), drop_ints o)
    | `Field (x, o) -> `Field (x, drop_ints o)
    | `NoOffset -> `NoOffset

  (* NB! Currently we care only about concrete indexes. Base (seeing only a int domain
     element) answers with any_index_exp on all non-concrete cases. *)
  let rec of_exp: exp offs -> t = function
    | `NoOffset    -> `NoOffset
    | `Index (Const (CInt (i,ik,s)),o) -> `Index (Idx.of_int ik i, of_exp o)
    | `Index (_,o) -> `Index (Idx.top (), of_exp o)
    | `Field (f,o) -> `Field (f, of_exp o)
end

module Unit =
struct
  include MakePrintable (Index.Unit)

  (* TODO: rename to of_poly? *)
  let rec of_offs: 'i offs -> t = function
    | `NoOffset -> `NoOffset
    | `Field (f,o) -> `Field (f, of_offs o)
    | `Index (i,o) -> `Index ((), of_offs o)

  let rec of_cil: offset -> t = function
    | NoOffset    -> `NoOffset
    | Index (i,o) -> `Index ((), of_cil o)
    | Field (f,o) -> `Field (f, of_cil o)
end

module Exp =
struct
  include MakePrintable (Index.Exp)

  let rec of_cil: offset -> t = function
    | NoOffset    -> `NoOffset
    | Index (i,o) -> `Index (i, of_cil o)
    | Field (f,o) -> `Field (f, of_cil o)

  let rec to_cil: t -> offset = function
    | `NoOffset    -> NoOffset
    | `Index (i,o) -> Index (i, to_cil o)
    | `Field (f,o) -> Field (f, to_cil o)
end
