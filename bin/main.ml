let () = match Yaml.of_string "foo: somebody said I should put a colon here: so I did" with
  | Ok value -> Yaml.pp (Format.get_std_formatter ()) value
  | Error (`Msg err) -> prerr_string ("Error: " ^ err)
