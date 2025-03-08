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

  (* You can define custom sections where to put argument specifications in --help. *)
  let files = Clap.section "FILES" in

  (* Sections can have descriptions.
     They do not have to contain argument specifications. *)
  let _ =
    Clap.section
      ~description: "This is an example of custom section with a description."
      "EXAMPLE SECTION"
  in

  (* Sections can have both descriptions and argument specifications. *)
  let sizes =
    Clap.section
      ~description: "This is an example of custom section with a description and arguments."
      "SIZES"
  in

  (* Sections can be specific to subcommands. *)
  let copy_section = Clap.section "COPY OPTIONS" in

  (* We now define all named arguments.
     This is the first rule of Clap: define named arguments before unnamed ones.
     Clap works by consuming arguments: once they have been read, they are no longer
     in the list of remaining arguments. By consuming named arguments first, you
     make sure that their parameters are also consumed. Since the arity of named
     arguments can be 0 (for flags) or 1 (for everything else), Clap cannot determine
     whether, in "--input filename" for instance, "filename" is an unnamed argument
     or the argument of "--input". That is, until "--input" has been consumed.
     Clap will refuse to consume "--input" as an unnamed argument, since it starts
     with a dash. So if you want "--input" to be able to be specified before
     an unnamed argument, you must read "--input" before the unnamed argument. *)

  (* Here, input has type string. It contains the value of the --input (or -i)
     argument. Unless the argument does not exist, in which case input contains
     the empty string. This is why you are not supposed to use input yet:
     wait until Clap.close. *)
  let input = Clap.mandatory_string ~section: files ~long: "input" ~short: 'i' () in

  (* Here, output has type string option. If --output is specified,
     it contains its value. If it is not, it contains None.
     --output has synonyms --out and --result which can be used in its place. *)
  let output =
    Clap.optional_string
      ~section: files
      ~long: "output"
      ~long_synonyms: [ "out"; "result" ]
      ()
  in

  (* Here, max_size has type int. If --max-size is specified and is a valid integer,
     it contains its value. If --max-size is unspecified, max_size contains
     the default value 42. If --max-size is specified but is an invalid integer,
     max_size contains 0. Just like input, you should not use max_size for now:
     wait until Clap.close. *)
  let max_size = Clap.default_int ~section: sizes ~long: "max-size" 42 in

  (* You can also give a description to your argument, for the --help. *)
  let min_size =
    Clap.default_int
      ~section: sizes
      ~long: "min-size"
      ~description: "Minimum size of the output file."
      0
  in

  (* You can also give a placeholder for the value, for the --help.
     The synopsis for --input, which does not have a ~placeholder, is "--input <VALUE>".
     But here the synopsis for --log-file is "--log-file <FILENAME>". *)
  let log_file = Clap.default_string ~long: "log-file" ~placeholder: "FILENAME" "demo.log" in

  (* Flags are named arguments that don't take parameters: they are either
     here or not. So the type of fast is bool. Its value is false unless
     --fast is specified. *)
  let fast = Clap.flag ~set_long: "fast" false in

  (* It is good practice to give both a way to set a flag, and to unset it. *)
  let verbose = Clap.flag ~set_long: "verbose" ~unset_long: "short" false in

  (* It is also useful to give descriptions, which are used in --help.
     Newline characters (\n) become line breaks with indentation,
     and consecutive newline characters (\n\n) become paragraph separators
     (i.e. empty lines). *)
  let url =
    Clap.default_string ~long: "location" ~short: 'l'
      ~description: "Location of the ressource to multiplexate.

This can be either:
- a URL, such as: http://localhost:1234/file.txt
- a filename, such as: path/to/file.txt
- a philosophical meta-description that is passed to an AI and \
  is just an excuse for me to have a long line of text that will be automatically \
  split into several lines."
      ""
  in

  (* [flag_enum] is a generalization of [flag] for enums with more than 2 possible values. *)
  let color =
    Clap.flag_enum
      [
        [ "red"; "redish" ], [ 'r' ], "red";
        [ "orange" ], [], "orange";
        [], [ 'y' ], "yellow";
      ]
      "red"
  in

  (* Now that we defined some named arguments, let's define an unnamed argument,
     i.e. one with neither ~long nor ~short. It is best to specify the ~placeholder of those
     arguments, since "VALUE" is not very informative. *)
  let username = Clap.mandatory_string ~placeholder: "USERNAME" () in

  (* Subcommands are a form of named arguments.
     You could define a "command" argument with optional_string and then
     test its value with "match command with" and it would work fine,
     but it's better to use the subcommand function, which results in a better --help. *)
  let command =
    Clap.subcommand [
      (
        Clap.case "copy" ~description: "Copy input into output." @@ fun () ->
        (* Argument -f is a named arguments, are we breaking the rule?
           Actually no because since this argument is specific to "copy",
           it cannot appear before the command itself. But we do need to
           consume the named arguments which are specific to "copy" before we
           parse the unnamed arguments which are specific to "copy". *)
        let force = Clap.flag ~section: copy_section ~set_short: 'f' false in

        (* Let's expect a mandatory argument, for good measure. *)
        let chunk_size =
          Clap.mandatory_int ~section: copy_section ~placeholder: "CHUNK_SIZE" ()
        in

        (* Here we have two choices. We can either call Clap.close and run the command,
           or we can return a value that denotes the command and its arguments
           (and put the call to Clap.close outside of the Clap.subcommand call).
           We choose to do the latter as an example but both approaches are fine.
           Polymorphic variants are useful for this approach. *)
        `copy (force, chunk_size)
      );
      (
        Clap.case "move" ~description: "Move input into output." @@ fun () ->
        (* "move" expects no specific argument. *)
        `move
      );
      (
        Clap.case "concat" ~description: "Concatenate several files." @@ fun () ->
        (* Let's consume all remaining unnamed arguments into a list.
           Note that Clap.list also allows you to consume all remaining *named*
           arguments with a given name. Flags are actually an example of this
           (but only the last value is returned). *)
        let files = Clap.list_string ~placeholder: "FILENAME" () in
        `concat files
      );
      (
        Clap.case "dance" ~description: "Perform a dance." @@ fun () ->
        (* Let's demonstrate that we can easily have nested subcommands.
           Although since the dances do not expect any argument themselves,
           it would have been simpler to just use mandatory_string
           (or mandatory with a custom enum type). *)
        let dance =
          Clap.subcommand ~placeholder: "DANCE" [
            (* Subcommands can have default cases that are selected if no command
               is specified. It only makes sense to have a default case
               if there are no other unnamed arguments to read, otherwise
               the next unnamed argument will be understood as a value for
               the subcommand. *)
            Clap.default_case ~description: "Duck dance." (fun () -> `duck);
            Clap.case "rock" (fun () -> `rock);
            Clap.case "swing" (fun () -> `swing);
          ]
        in
        `dance dance
      );
    ]
  in

  (* There are other interesting things to do with Clap, like:
     - defining custom types (enums in particular);
     - controlling which value is returned in case the same argument
       is specified several times or if a flag is both set and unset;
     - ...
     But the above shows the most common use cases. *)

  (* The second rule of Clap is to run Clap.close before actually using
     the values that we parsed. Clap.error prints an error and exits
     if the user does not pass a mandatory argument or passes an invalid argument.
     Before calling Clap.close, you don't know whether your values
     can actually be used: they may hold dummy values.

     Why is Clap waiting for Clap.close to emit errors instead of emitting them
     immediately? This allows Clap to gather all argument specifications
     before displaying the --help and the error message.
     Otherwise the --help would be incomplete.

     By calling Clap.close, we also check that there is no remaining unused argument.
     For instance, if you expect only optional arguments --input and --output
     but the user makes a mistake and specifies --onput, this last check will cause an error:
     "don't know what to do with: --onput".

     There are actually some exceptions to this rule
     (see the documentation of Clap.close). *)
  Clap.close ();

  (* And now we can do stuff with our values. Here we just print them. *)
  Printf.printf "\
input = %S
output = %S
max_size = %d
min_size = %d
log_file = %S
fast = %b
verbose = %b
url = %S
color = %S
username = %S
%!" input (match output with None -> "N/A" | Some o -> o)
    max_size min_size log_file fast verbose url color username;

  match command with
    | `copy (force, chunk_size) ->
        Printf.printf "\
command = copy
force = %b
chunk_size = %d
%!" force chunk_size

    | `move ->
        Printf.printf "command = move\n%!"

    | `concat files ->
        Printf.printf "command = concat\nfiles = %s\n%!" (String.concat ", " files)

    | `dance `rock ->
        Printf.printf "command = dance (rock)\n%!"

    | `dance `swing ->
        Printf.printf "command = dance (swing)\n%!"

    | `dance `duck ->
        Printf.printf "command = dance (duck)\n%!"
