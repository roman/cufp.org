open Core.Std
open Async.Std
module Html = Cufp_html

type t = {
  name : string;
  email : string option;
  affiliation : string option;
  link : string option;
}

let make ?email ?affiliation ?link ~name () =
  let f = (function None | Some "" -> None | Some x -> Some x) in
  if name = "" then
    (failwith "person name cannot be empty string")
  else
    {
      name;
      email = f email;
      affiliation = f affiliation;
      link = f link
    }

let of_strings
    ?(on=',')
    ?(emails="")
    ?(affiliations="")
    ?(links="")
    ?(names="")
    ()
    =
  let split s =
    String.split s ~on |>
    List.map ~f:String.strip |>
    function [""] -> [] | l -> l
  in
  let names_l = split names in
  let n = List.length names_l in
  let split_n s =
    split s |> fun l ->
    let m = List.length l in
    if m = 0 then
      List.init n ~f:(fun _ -> None)
    else if m = n then
      List.map l ~f:Option.some
    else
      failwithf "list %s not of same length as %s" s names ()
  in
  let emails_l = split_n emails in
  let affiliations_l = split_n affiliations in
  let links_l = split_n links in
  if n <> List.length emails_l then
    failwith "number of names does not match number of emails"
  else if n <> List.length affiliations_l then
    failwith "number of names does not match number of affiliations"
  else if n <> List.length links_l then
    failwith "number of names does not match number of links"
  else
    List.mapi names_l ~f:(fun i name ->
      make
        ~name
        ?email:(List.nth_exn emails_l i)
        ?affiliation:(List.nth_exn affiliations_l i)
        ?link:(List.nth_exn links_l i)
        ()
    )

let to_html {name; affiliation; link; _ } =
  let open Html in
  [span ~a:["class", "person"]
      (match link with
      | None -> [data name]
      | Some link -> [a ~a:["href",link] [data name]]
      )
  ]@
  (match affiliation with
  | None -> []
  | Some affiliation ->
    [
      data " ";
      span ~a:["class", "affiliation"] [data affiliation];
    ]
  )

let to_html_ul tl =
  let open Html in
  ul (List.map tl ~f:(fun t -> li (to_html t)))

let to_string_rss {name; email; _} =
  match email with
  | Some email -> Some (sprintf "%s (%s)" email name)
  | None -> None
