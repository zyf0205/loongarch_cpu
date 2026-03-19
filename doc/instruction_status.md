# LoongArch CPU Status

## Implemented Now

- Arithmetic and logic: `ADD.W`, `SUB.W`, `SLT`, `SLTU`, `NOR`, `AND`, `OR`, `XOR`
- Shift: `SLL.W`, `SRL.W`, `SRA.W`, `SLLI.W`, `SRLI.W`, `SRAI.W`
- Immediate: `ADDI.W`, `SLTI`, `SLTUI`, `ANDI`, `ORI`, `XORI`, `LU12I.W`, `PCADDU12I`
- Branch and jump: `BEQ`, `BNE`, `B`, `BL`, `JIRL`
- Load and store: `LD.W`, `LD.B`, `LD.BU`, `LD.H`, `LD.HU`, `ST.W`, `ST.B`, `ST.H`

## Needed Next

- Multiply: signed and unsigned low/high result variants required by the contest environment
- Divide and remainder: signed and unsigned variants
- Remaining contest-required base instructions not yet in the current RTL
- After ISA closure: pipeline, hazard control, then cache and branch prediction

## Verification Strategy

- `tb_alu.v`: focused ALU edge-case regression
- `tb_regfile.v`: register file semantics and `r0` protection
- `tb_pc_reg.v`: reset and branch PC behavior
- `tb_mycpu.v`: staged CPU integration checks, instruction coverage summary, and debug-port sanity checks

## Known Current Limitation

- The core is still a single-cycle CPU.
- No FPGA board integration is assumed.
- Multiply/divide are not implemented in the current RTL because the repository does not yet contain a confirmed contest ISA subset or opcode source for them.
