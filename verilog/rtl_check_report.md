# RTL Check Report

## Tools

- Icarus Verilog: syntax/elaboration check
- Verilator: lint check

## Latest Result

- Icarus Verilog syntax check: PASS
- Verilator lint: COMPLETED WITH WARNINGS

## Main Verilator Warning Groups

- `MULTITOP`: expected because RTL folder contains several standalone modules and `animalnet_top_skeleton.v` does not instantiate the compute engines yet.
- `WIDTHTRUNC` / `WIDTHEXPAND`: address and intermediate arithmetic use `integer` helpers, then assign into narrower address ports. This is common in early parameterized RTL, but should be cleaned before synthesis.
- `BLKSEQ`: blocking assignments are used inside clocked FSMs for temporary counter/state arithmetic. It passes syntax, but a stricter synthesis-ready rewrite should split next-state combinational logic from sequential register updates.
- `ASCRANGE`: default parameters such as `LENGTH = 1` or `DEPTH = 1` produce `$clog2(1)-1:0`. Real instantiations should use depth/length greater than 1, but generic modules need safer address-width helpers.
- `CASEINCOMPLETE`: FSM case statements need `default` branches for lint-clean RTL.

## Current Status

The RTL is syntax-valid and the toolchain works. Before synthesis or hardware simulation, the next cleanup step should be making Verilator lint clean by fixing address widths, adding default case branches, and rewriting FSM register updates more strictly.
