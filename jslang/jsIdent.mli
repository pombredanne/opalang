(*
    Copyright © 2011 MLstate

    This file is part of OPA.

    OPA is free software: you can redistribute it and/or modify it under the
    terms of the GNU Affero General Public License, version 3, as published by
    the Free Software Foundation.

    OPA is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
    FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
    more details.

    You should have received a copy of the GNU Affero General Public License
    along with OPA. If not, see <http://www.gnu.org/licenses/>.
*)
(**
   The identifier used in the js ast
*)

(**
   The documentation of these type is in JsAst
*)

type native_ident = [ `global | `local ]

type t =
  | ExprIdent of Ident.t
  | Native of native_ident * string

val compare : t -> t -> int
val equal : t -> t -> bool
val to_string : t -> string
val hash : t -> int
val stident : t -> string
