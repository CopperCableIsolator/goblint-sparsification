  $ goblint --set ana.base.privatization protection --enable witness.yaml.enabled --set ana.activated[+] mutexGhosts --set witness.yaml.entry-types '["flow_insensitive_invariant", "ghost_instrumentation"]' 92-idx_priv.c
  [Success][Assert] Assertion "data == 0" will succeed (92-idx_priv.c:22:3-22:29)
  [Info][Deadcode] Logical lines of code (LLoC) summary:
    live: 14
    dead: 0
    total lines: 14
  [Info][Witness] witness generation summary:
    total generation entries: 2
  [Info][Race] Memory locations race summary:
    safe: 1
    vulnerable: 0
    unsafe: 0
    total memory locations: 1

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
          file_name: 92-idx_priv.c
          file_hash: $FILE_HASH
          line: 8
          column: 3
          function: t_fun
        updates: []
      - location:
          file_name: 92-idx_priv.c
          file_hash: $FILE_HASH
          line: 11
          column: 3
          function: t_fun
        updates: []
      - location:
          file_name: 92-idx_priv.c
          file_hash: $FILE_HASH
          line: 20
          column: 3
          function: main
        updates:
        - variable: multithreaded
          value: "1"
          format: c_expression
      - location:
          file_name: 92-idx_priv.c
          file_hash: $FILE_HASH
          line: 21
          column: 3
          function: main
        updates: []
      - location:
          file_name: 92-idx_priv.c
          file_hash: $FILE_HASH
          line: 23
          column: 3
          function: main
        updates: []
  - entry_type: flow_insensitive_invariant
    flow_insensitive_invariant:
      string: '! multithreaded || (0 <= data && data <= 1)'
      type: assertion
      format: C

TODO: protected invariant with m_4_locked without making 56-witness/68-ghost-ambiguous-idx unsound
