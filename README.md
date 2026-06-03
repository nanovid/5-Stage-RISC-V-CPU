# Unified RISC-V 5-Stage Pipelined Processor
A complete RTL-to-Silicon hardware design stack implementing a custom 32-bit RISC-V processor in Verilog. This project covers the entire processor development lifecycle—from building a basic single-cycle datapath to engineering a fully pipelined architecture with hazard resolution, and ultimately deploying the core onto the PYNQ-Z1 ARM+FPGA SoC platform.

## 🚀 Project Overview & Architecture
The primary objective of this project is to construct a fully functional 32-bit RISC-V CPU capable of executing standard instruction benchmarks, mapped directly onto physical FPGA hardware.

Key Architectural Features:
5-Stage Pipeline: Implements the classic Fetch (F), Decode (D), Execute (E), Memory (M), and Writeback (W) processor stages.

Hazard Resolution: Features comprehensive data bypassing (forwarding) and pipeline stalling logic to resolve Read-After-Write (RAW) and structural hazards natively.

Hardware-Optimized Memory: Instruction, Data, and Register memories are mapped directly to hardware Block RAMs (BRAMs), supporting byte/half-word/word unaligned accesses.

On-Chip Debugging: Integrates hardware probes (Integrated Logic Analyzers) via Xilinx XDC constraints for live on-board signal monitoring.

🛠️ Technical Progression & Accomplishments
### Phase 1: Datapath Foundations (Fetch & Decode)
Goal: Establish the instruction memory interface and instruction parsing logic.

Fetch Stage: Built a byte-addressable behavioral instruction memory initialized via $readmemh. Implemented the Program Counter (PC) sequential logic to fetch 32-bit instruction words.

Decode Stage: Engineered a combinational decoding network to parse the RISC-V base integer instruction set. Extracted operational fields including opcodes, source/destination registers (rs1, rs2, rd), immediate values (with proper sign extension), and shift amounts.

### Phase 2: Execution & Single-Cycle Core
Goal: Complete the datapath to execute instructions in a single clock cycle.

Register File: Designed a synchronous 32-register file with combinational reads and sequential writes, properly initializing the stack pointer.

Execute Stage: Implemented the Arithmetic Logic Unit (ALU) and branch comparison logic. Calculated effective memory addresses and branch targets.

Memory & Writeback: Built the Data Memory interface supporting encoded access sizes (byte, half-word, word) for load/store operations. Routed ALU, Memory, and PC outputs back to the Register File, successfully completing a fully functional Single-Cycle RISC-V core.

### Phase 3: Pipelining & Hazard Resolution
Goal: Segment the single-cycle core into a high-throughput 5-stage pipeline.

Pipeline Registers: Segmented the datapath into F, D, E, M, and W stages, ensuring multi-cycle instruction overlaps without data corruption.

Data Bypassing (Forwarding): Implemented complex forwarding paths (Memory-to-Execute, Writeback-to-Execute, Writeback-to-Memory) to resolve data dependencies without losing clock cycles. Included custom bypass paths directly into the branch comparator.

Stalling Logic: Developed hazard detection units to inject pipeline bubbles (NOPs / addi x0, x0, 0) when RAW hazards could not be resolved via forwarding, ensuring strict architectural correctness.

### Phase 4: FPGA Deployment & Hardware Debugging
Goal: Map the pipeline to the PYNQ-Z1 FPGA and resolve hardware-specific timing constraints.

BRAM Inference: Re-engineered the Register File, Instruction Memory, and Data Memory using Verilog ram_style = "block" attributes to force mapping to dedicated hardware Block RAMs.

Latency Adjustments: Handled the transition from combinational memory reads to realistic 1-cycle BRAM read latencies, retrofitting the pipelining and stalling logic to accommodate the delay.

Hardware Verification: Ran Post-Synthesis and Post-Implementation static timing analysis and simulations (xsim) to guarantee timing closure at 50MHz.

Silicon Deployment: Embedded mark_debug attributes and XDC constraints to instantiate hardware probes. Generated bitstreams, pushed them to the FPGA via Python scripts, and verified live execution traces directly on the silicon.

## 💻 Tech Stack
Hardware Description: Verilog

Simulation & Verification: Verilator (C++), Xilinx xsim, GTKWave

Synthesis & Implementation: Xilinx Vivado (Static Timing Analysis, Place & Route)

Target Hardware: PYNQ-Z1 (Zynq-7000 ARM/FPGA SoC)

Testing: Custom RISC-V Assembly Benchmarks
