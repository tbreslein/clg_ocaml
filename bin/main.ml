(* NOTE
 - I don't need to parse the template into a dictionary or anything, instead I
     can keep as the tree that it is, and when a change log file is read, I just
     check whether that tree is a subtree of the template.
 *)

(*
 TEMPLATE STRUCTURE:
   # relative to this file, or absolute
   changelog_path: string

   # file name format for the change log files
   #
   # example: "^PR_*\.log\.yml$"
   #
   # supports capture groups, which you can use in the message formatting
   #
   # example: "^PR_(\d+)\.log\.yml$"
   # this would capture digits between "PR_" and ".log.yml" as the first capture
   # group
   file_regex: string

   # each changelog message has to fulfill the following regex, otherwise a
   # parse error is thrown
   #
   # example: "^(feat|fix|chore): \+"
   # this would throw whenever a message does not start with feat, fix, or chore,
   # followed by a ": " and then at least one more character
   msg_regex: string

   # string to prefix each change log message.
   # can include a capture group captured by file_regex with regular regex
   # references \1, \2, etc.
   #
   # example: "\[PR \1\] "
   # taking the second example from the file_regex field to capture the PR
   # number, if you parsed a file like "PR_1234.log.yml", this would prefix each
   # change message in the log file with the string "[PR 1234] ", where "1234"
   # is captured from the file name.
   msg_prefix: string

   # string to append to each change log message.
   # can include a capture group captured by file_regex with regular regex
   # references \1, \2, etc.
   #
   # example: " \(PR \1\)"
   # similar to the example for msg_prefix, for a file like "PR_420.log.yml"
   # this would suffix each log message in that file with the string " (PR 420)"
   msg_suffix: string

   # Define the template tree for your change log files.
   # The full tree underneath the "template" node is taken as is, and each
   # parsed change log message must be a subtree of this template tree.
   # Each leaf of this tree must be a string saying either "list" or "string"
 *)

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

  match command with
  | `check -> print_endline "running check"
  | `append prev_log -> print_endline ("running append on: " ^ prev_log)
