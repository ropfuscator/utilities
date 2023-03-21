# ROPfuscator TOML Configuration Files

You can provide a configuration file to ROPfuscator. The different configuration options are listed in the "Configuration Options" table below.

## Comparison Table

The following table summarizes the main differences between the configurations:

| Configuration Name | Gadget Addresses | Stack Values | Immediate Operands | Branch Targets | Opaque Predicates | Contextual Opaque Predicates | Algorithm | Input Algorithm |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `alladdresses` | Opaque Constants | - | - | - | Enabled | Enabled | Multcomp | - |
| `full` | Opaque Constants | Opaque Constants | Opaque Constants | Opaque Constants | Enabled | Enabled | Multcomp | - |
| `half addresses` | Opaque Constants (50%) | - | - | - | Enabled | Enabled | Multcomp | - |
| `ROPonly` | Not Opaque | Not Opaque | Not Opaque | Not Opaque | Not Enabled | Not Enabled | - | - |

## Configuration Options

The following table provides a brief description of each available configuration option and the accepted values:

| Option | Description | Accepted Values | Default |
| --- | --- | --- | --- |
| avoid_multiversion_symbol | If set to true, symbols which have multiple versions are not used | `true` or `false` | `false` |
| contextual_opaque_predicates_enabled | When true, use contextual opaque predicate as well as invariant opaque predicate. It has no effect when opaque_predicates_algorithm == "mov". | `true` or `false` | `true` |
| custom_library_path | Library path where the gadgets are extracted from | Absolute path or empty | Empty |
| gadget_addresses_obfuscation_percentage | Set percentage of addresses to obfuscate in current function | Integer between 0 and 100 | 100 |
| library_hash_sha1 | Expected library SHA1 to avoid using different version of library unexpectedly | SHA1 hash string or empty | Empty |
| linked_libraries | Extra library paths which are finally linked with the program | Absolute paths or empty | Default libraries or empty |
| obfuscation_enabled | Toggle obfuscation globally | `true` or `false` | `true` |
| print_instr_stat | If set to true, print a number of instruction obfuscated for each opcode | `true` or `false` | `false` |
| rng_seed | If set, seeds the RNG with the value defined | Random or integer value | Random |
| search_segment_for_gadget | If set to true, ropfuscator will look for gadgets in the code segment instead of the code section | `true` or `false` | `true` |
| show_progress | If set to true, print progress of each function obfuscation | `true` or `false` | `false` |
| opaque_branch_targets_enabled | When true, branch target address is obfuscated with opaque predicate. Ignored when opaque predicate is turned off. | `true` or `false` | `false` |
| opaque_gadget_addresses_enabled | Toggle obfuscation of gadget addresses | `true` or `false` | `true` |
| opaque_immediate_operands_enabled | When true, immediate operand is obfuscated with opaque predicate. Ignored when opaque predicate is turned off. | `true` or `false` | `true` |
| opaque_immediate_operands_percentage | Set the percentage of immediate operands to obfuscate in the current function | Integer between 0 and 100 | 100 |
| opaque_predicates_algorithm | Specify opaque predicate algorithm. Available algorithms are: mov, r3sat32, multcomp | `mov`, `r3sat32`, `multcomp` | `mov` |
| opaque_predicates_enabled | Toggles the usage of opaque predicates | `true` or `false` | `false` |
| opaque_saved_stack_values_enabled | When true, registers and random immediate values are saved onto stack and used by opaque predicates to compute initial values. Ignored when opaque predicate is turned off. | `true` or `false` | `true` |

