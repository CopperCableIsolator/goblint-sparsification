module Level =
struct
  type t =
    | Debug
    | Info
    | Warning
    | Error
  [@@deriving eq, hash, show { with_path = false }, enum]
  (* TODO: fix ord Error: https://github.com/ocaml-ppx/ppx_deriving/issues/254 *)

  let compare x y = Stdlib.compare (to_enum x) (to_enum y)

  let of_string = function
    | "debug" -> Debug
    | "info" -> Info
    | "warning" -> Warning
    | "error" -> Error
    | _ -> invalid_arg "Logs.Level.of_string"

  let current = ref Debug

  let should_log l =
    compare l !current >= 0

  let stag = function
    | Error -> "red"
    | Warning -> "yellow"
    | Info -> "blue"
    | Debug -> "white" (* non-bright white is actually some gray *)
end


module type Kind =
sig
  type b
  type c
  val log: Level.t -> ('a, b, c, unit) format4 -> 'a
end

module PrettyKind =
struct
  open GoblintCil

  type b = unit
  type c = Pretty.doc
  let log level fmt =
    (* Pretty.eprintf returns doc instead of unit *)
    let finish doc =
      Pretty.fprint stderr ~width:max_int doc;
      if !AnsiColors.stderr then
        prerr_string (List.assoc "reset" AnsiColors.table);
      prerr_newline ()
    in
    if Level.should_log level then (
      if !AnsiColors.stderr then
        prerr_string (List.assoc (Level.stag level) AnsiColors.table);
      Pretty.gprintf finish fmt
    )
    else
      GobPretty.igprintf () fmt
end

module FormatKind =
struct
  type b = Format.formatter
  type c = unit
  let log level fmt =
    let finish ppf =
      Format.fprintf ppf "@}\n%!"
    in
    if Level.should_log level then (
      Format.eprintf "@{<%s>" (Level.stag level);
      Format.kfprintf finish Format.err_formatter fmt
    )
    else
      Format.ifprintf Format.err_formatter fmt
end

module BatteriesKind =
struct
  type b = unit BatIO.output
  type c = unit
  let log level fmt =
    let finish out =
      if !AnsiColors.stderr then
        prerr_string (List.assoc "reset" AnsiColors.table);
      BatPrintf.fprintf out "\n%!"
    in
    if Level.should_log level then (
      if !AnsiColors.stderr then
        prerr_string (List.assoc (Level.stag level) AnsiColors.table);
      BatPrintf.kfprintf finish BatIO.stderr fmt
    )
    else
      BatPrintf.ifprintf BatIO.stderr fmt
end


module MakeKind (Kind: Kind) =
struct
  open Kind

  let log = log

  (* must eta-expand to get proper (non-weak) polymorphism for format *)
  let debug fmt = log Debug fmt
  let info fmt = log Info fmt
  let warn fmt = log Warning fmt
  let error fmt = log Error fmt

  let newline () =
    prerr_newline ()
end

module Pretty = MakeKind (PrettyKind)
module Format = MakeKind (FormatKind)
module Batteries = MakeKind (BatteriesKind)

include Pretty (* current default *)
