open Clg

let () =
  Clap.description "A small changelog generator";
  let input_dir = Clap.mandatory_string ~long:"input_dir" ~short:'i' () in
  let verbose = Clap.flag ~set_long:"verbose" false in

  let command =
    Clap.subcommand
      [
        ( Clap.case "check"
            ~description:"check current log files for consistency"
        @@ fun () -> `check );
        ( Clap.case "append"
            ~description:
              "append new changelog entries to existing changelog file"
        @@ fun () ->
          let prev_log = Clap.mandatory_string ~placeholder:"FILENAME" () in
          `append prev_log );
      ]
  in

  Clap.close ();

  Printf.printf "input: %s\nverbose: %b\n" input_dir verbose;

  let template = Clg_yaml.read_template input_dir in
  Yaml.pp (Format.get_std_formatter ()) template;

  match command with
  | `check -> print_endline "running check"
  | `append prev_log -> print_endline ("running append on: " ^ prev_log)
