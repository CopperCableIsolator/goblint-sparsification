  $ goblint --set ana.base.privatization protection --enable witness.yaml.enabled --set ana.activated[+] mutexGhosts --set witness.yaml.entry-types '["flow_insensitive_invariant", "ghost_instrumentation"]' 65-ghost-ambiguous-lock.c
  [Info][Deadcode] Logical lines of code (LLoC) summary:
    live: 23
    dead: 0
    total lines: 23
  [Info][Witness] witness generation summary:
    total generation entries: 3
  [Info][Race] Memory locations race summary:
    safe: 2
    vulnerable: 0
    unsafe: 0
    total memory locations: 2

  $ yamlWitnessStrip < witness.yml
  - entry_type: ghost_instrumentation
    content:
      ghost_variables:
      - name: multithreaded
        scope: global
        type: int
        initial:
          value: "0"
          format: c_expression
      ghost_updates:
      - location:
          file_name: 65-ghost-ambiguous-lock.c
          file_hash: $FILE_HASH
          line: 10
          column: 3
          function: t_fun
        updates: []
      - location:
          file_name: 65-ghost-ambiguous-lock.c
          file_hash: $FILE_HASH
          line: 13
          column: 3
          function: t_fun
        updates: []
      - location:
          file_name: 65-ghost-ambiguous-lock.c
          file_hash: $FILE_HASH
          line: 14
          column: 3
          function: t_fun
        updates: []
      - location:
          file_name: 65-ghost-ambiguous-lock.c
          file_hash: $FILE_HASH
          line: 17
          column: 3
          function: t_fun
        updates: []
      - location:
          file_name: 65-ghost-ambiguous-lock.c
          file_hash: $FILE_HASH
          line: 22
          column: 3
          function: fun
        updates: []
      - location:
          file_name: 65-ghost-ambiguous-lock.c
          file_hash: $FILE_HASH
          line: 24
          column: 3
          function: fun
        updates: []
      - location:
          file_name: 65-ghost-ambiguous-lock.c
          file_hash: $FILE_HASH
          line: 29
          column: 3
          function: main
        updates:
        - variable: multithreaded
          value: "1"
          format: c_expression
      - location:
          file_name: 65-ghost-ambiguous-lock.c
          file_hash: $FILE_HASH
          line: 35
          column: 3
          function: main
        updates: []
      - location:
          file_name: 65-ghost-ambiguous-lock.c
          file_hash: $FILE_HASH
          line: 37
          column: 3
          function: main
        updates: []
  - entry_type: flow_insensitive_invariant
    flow_insensitive_invariant:
      string: '! multithreaded || (0 <= g2 && g2 <= 1)'
      type: assertion
      format: C
  - entry_type: flow_insensitive_invariant
    flow_insensitive_invariant:
      string: '! multithreaded || (0 <= g1 && g1 <= 1)'
      type: assertion
      format: C
