(** High-level abstraction of a vector. *)
module type Vector =
sig
  type num
  type t [@@deriving eq, ord, hash]

  val show: t -> string

  val copy: t -> t

  val of_list: num list -> t

  val of_array: num array -> t

  val of_sparse_list: int -> (int * num) list -> t

  val to_list: t -> num list

  val to_array: t -> num array

  val to_sparse_list: t -> (int * num) list

  val length: t -> int

  val compare_length_with: t -> int -> int

  val zero_vec: int -> t

  val is_const_vec: t -> bool

  val nth: t -> int -> num

  val set_nth: t -> int -> num ->  t

  val remove_nth: t -> int ->  t

  val keep_vals: t -> int ->  t

  val map2i: (int -> num -> num -> num) -> t -> t -> t

  val rev: t -> t
end

module type ArrayVector = 
sig 
  include Vector
  val mapi_with: (int -> num -> num) -> t -> unit

  val map_with: (num -> num) -> t -> unit

  val map2_with: (num -> num -> num) -> t -> t -> unit

  val map2i_with: (int -> num -> num -> num) -> t -> t -> unit

  val filteri: (int -> num -> bool) -> t -> t

  val findi: (num -> bool) ->  t -> int

  val find2i: (num -> num -> bool) -> t -> t -> int

  val exists: (num -> bool) -> t -> bool

  val set_nth_with: t -> int -> num -> unit

  val insert_val_at: t -> int -> num ->  t

  val apply_with_c_with: (num -> num -> num) -> num -> t -> unit

  val rev_with: t -> unit

  val append: t -> t -> t
end

module type SparseVector = 
sig 
  include Vector
  val is_zero_vec: t -> bool

  val insert_zero_at_indices: t -> (int * int) list -> int -> t

  val remove_at_indices: t -> int list -> t

  (* Returns the part of the vector starting from index n*)
  val starting_from_nth : t -> int -> t

  val find_first_non_zero : t -> (int * num) option

  val map_f_preserves_zero: (num -> num) -> t -> t

  val mapi_f_preserves_zero: (int -> num -> num) -> t -> t

  val map2_f_preserves_zero: (num -> num -> num) -> t ->  t -> t

  val find2i_f_false_at_zero: (num -> num -> bool) -> t -> t -> int

  val apply_with_c_f_preserves_zero: (num -> num -> num) -> num ->  t ->  t
end