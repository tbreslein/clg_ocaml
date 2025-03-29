let read_file_to_string path =
  let ic = open_in path in
  let str = really_input_string ic (in_channel_length ic) in
  close_in ic;
  str

let read_file_to_yaml path = read_file_to_string path |> Yaml.of_string_exn

let read_template input_dir =
  read_file_to_yaml @@ input_dir ^ "/clg_template.yml"
