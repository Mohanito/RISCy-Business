## RISCy-Business
This ECE 411 machine problem involves the design of a pipelined microprocessor that can execute the RV32I Instruction Set. 
Instruction pipelining is a technique for implementing instruction-level parallelism within a single processor. 
Compared with multiple-cycle processors, pipelined processors greatly increase the overall instruction throughput. 
In this processor design, the instructions flow through 5 different stages: **fetch(IF), decode(ID), execute(EX), memory access(MEM) and writeback(WB)**. 
We also added support for hazard detection and data forwarding, as well as integrating a basic cache system. 
##### Advanced Design Options:
- RISC-V M-Extension with hardware multiplier & divider
- L2 Cache
- 4-way set-associative cache

10th place in Fall 2020 Design Competition (out of 20 groups)
