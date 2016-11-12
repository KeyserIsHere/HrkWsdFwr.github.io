## HUB Specification

This is the architecture overview for the hub computing units.

__All cycle values currently listed are for example purposes. Must test to see what works best.__

Overview
--------

Hubs are 8-bit computing devices that can talk with other hubs and modules through interface-able ports.

They consist of two operating pipelines:

* Normal - Normal execution
* Debug - Interactive execution

To operate in debugging mode, the special debug port must be used.


Ports
-----

Communicating between hubs or modules is done using ports. These ports are accessed using an ID from 0 to 255, which indicates the port used. Two hubs may have different ports connected together.

e.g. HubA may have its port 0 connected to HubB's port 55. For HubA to communicate to HubB, it will reference port 0. While for HubB to communicate to HubA, it will reference port 55.

Communication is done using two special instructions `send` (to send a message) and `recv` (to receive a message). For the communication to be successful the two communicating hubs must use the respective send/recv pair during the same timeout period. If neither gets the response during that time, the instruction will timeout and communication will have failed. It will then move onto the next instruction.

Port messages can be of various sizes, ranging from 0 to 255. The instructions provide no standard mechanism to know the size of the incoming data.

Data transmission is at a rate of _1/2 cycle per bit (4 cycles per byte)_. __To be tested.__


Registers
---------

Hubs have 4 general purpose registers available to them, and 2 specialty registers.

| Registers |      Type       |                                               Description                                               |
|:---------:|:---------------:|:-------------------------------------------------------------------------------------------------------:|
| r0        | General Purpose | Used to store both data and addresses                                                                   |
| r1        | General Purpose | Used to store both data and addresses                                                                   |
| r2        | General Purpose | Used to store both data and addresses                                                                   |
| r3        | General Purpose | Used to store both data and addresses                                                                   |
| pc        | Program Counter | Points to the instruction currently being executed                                                      |
| flags     | Status          | Contains the current state of the hub (`z` zero flag, `c` carry flag, `s` sign flag, `o` overflow flag) |

Accessing (both r/w) a register is done at a rate of _0 cycles_. __To be tested.__


Memory
------

Each hub has 255 bytes of r/w memory (mapped from 0 to 255) available to it to use for data and instructions. Accessing (both r/w) this memory is at a rate of _1 cycle per byte_. __To be tested. Writes could potentially be faster as there's no cache?__


Instructions
------------

| Cycles | Opcode  | Mnemonic | Operand 1 | Operand 2 | Operand 3 |                                       Description                                        |
|:------:|:-------:|:--------:|:---------:|:---------:|:---------:|:----------------------------------------------------------------------------------------:|
| 2      | 000000  | add      | r/m       | r         |           | Add the register value (operand 2) into the register or memory (operand 1)               |
| 2      | 000001  | add      | r         | r/m       |           | Add the register or memory value (operand 2) into the register (operand 1)               |
| 2      | 000010  | add      | r/m       | i         |           | Add the immediate value (operand 2) into the register or memory (operand 1)              |
| 1      | 000011  | jz       | rel       |           |           | Jump if zero/equal (ZF=0)                                                                |
| 2      | 000100  | sub      | r/m       | r         |           | Subtract the register value (operand 2) into the register or memory (operand 1)          |
| 2      | 000101  | sub      | r         | r/m       |           | Subtract the register or memory value (operand 2) into the register (operand 1)          |
| 2      | 000110  | sub      | r/m       | i         |           | Subtract the immediate value (operand 2) into the register or memory (operand 1)         |
| 1      | 000111  | jnz      | rel       |           |           | Jump if not zero/not equal (ZF=1)                                                        |
| 2      | 001000  | mul      | r/m       | r         |           | Multiply the register value (operand 2) into the register or memory (operand 1)          |
| 2      | 001001  | mul      | r         | r/m       |           | Multiply the register or memory value (operand 2) into the register (operand 1)          |
| 2      | 001010  | mul      | r/m       | i         |           | Multiply the immediate value (operand 2) into the register or memory (operand 1)         |
| 1      | 001011  | js       | rel       |           |           | Jump if sign (SF=1)                                                                      |
| 3      | 001100  | sdiv     | r/m       | r         |           | Signed divide by register value (operand 2) into register or memory (operand 1)          |
| 3      | 001101  | sdiv     | r         | r/m       |           | Signed divide by register or memory value (operand 2) into register (operand 1)          |
| 3      | 001110  | sdiv     | r/m       | i         |           | Signed divide by immediate value (operand 2) into register or memory (operand 1)         |
| 1      | 001111  | jns      | rel       |           |           | Jump if not sign (SF=0)                                                                  |
| 3      | 010000  | udiv     | r/m       | r         |           | Unsigned divide by register value (operand 2) into register or memory (operand 1)        |
| 3      | 010001  | udiv     | r         | r/m       |           | Unsigned divide by register or memory value (operand 2) into register (operand 1)        |
| 3      | 010010  | udiv     | r/m       | i         |           | Unsigned divide by immediate value (operand 2) into register or memory (operand 1)       |
| 1      | 010011  | jo       | rel       |           |           | Jump if overflow (OF=1)                                                                  |
| 3      | 010100  | smod     | r/m       | r         |           | Signed modulo by register value (operand 2) into register or memory (operand 1)          |
| 3      | 010101  | smod     | r         | r/m       |           | Signed modulo by register or memory value (operand 2) into register (operand 1)          |
| 3      | 010110  | smod     | r/m       | i         |           | Signed modulo by immediate value (operand 2) into register or memory (operand 1)         |
| 1      | 010111  | jno      | rel       |           |           | Jump if not overflow (OF=0)                                                              |
| 3      | 011000  | umod     | r/m       | r         |           | Unsigned modulo by register value (operand 2) into register or memory (operand 1)        |
| 3      | 011001  | umod     | r         | r/m       |           | Unsigned modulo by register or memory value (operand 2) into register (operand 1)        |
| 3      | 011010  | umod     | r/m       | i         |           | Unsigned modulo by immediate value (operand 2) into register or memory (operand 1)       |
| 4      | 011011  | send     | r         | r         | m         | Send message (operand 3) of size (operand 2) device interfacing with port (operand 1)    |
| 2      | 011100  | cmp      | r/m       | r         |           | Compare the register value (operand 2) with the register or memory (operand 1)           |
| 2      | 011101  | cmp      | r         | r/m       |           | Compare the register or memory value (operand 2) with the register (operand 1)           |
| 2      | 011110  | cmp      | r/m       | i         |           | Compare the immediate value (operand 2) with the register or memory (operand 1)          |
| 4      | 011111  | send     | r         |           |           | Send empty message to device interfacing with port (operand 1)                           |
| 1      | 100000  | shl      | r/m       | r         |           | Shift left by register value (operand 2) into register or memory (operand 1)             |
| 1      | 100001  | shl      | r         | r/m       |           | Shift left by register or memory value (operand 2) into register (operand 1)             |
| 1      | 100010  | shl      | r/m       | i         |           | Shift left by immediate value (operand 2) into register or memory (operand 1)            |
| 4      | 100011  | send     | i         | r         | m         | Send message (operand 3) of size (operand 2) device interfacing with port (operand 1)    |
| 1      | 100100  | shr      | r/m       | r         |           | Shift right by register value (operand 2) into register or memory (operand 1)            |
| 1      | 100101  | shr      | r         | r/m       |           | Shift right by register or memory value (operand 2) into register (operand 1)            |
| 1      | 100110  | shr      | r/m       | i         |           | Shift right by immediate value (operand 2) into register or memory (operand 1)           |
| 4      | 100111  | recv     | i         | m         |           | Store message (operand 2) received from port (operand 1)                                 |
| 1      | 101000  | xor      | r/m       | r         |           | Logical exclusive OR the register value (operand 2) into register or memory (operand 1)  |
| 1      | 101001  | xor      | r         | r/m       |           | Logical exclusive OR the register or memory value (operand 2) into register (operand 1)  |
| 1      | 101010  | xor      | r/m       | i         |           | Logical exclusive OR the immediate value (operand 2) into register or memory (operand 1) |
| 4      | 101011  | send     | r         | i         | m         | Send message (operand 3) of size (operand 2) device interfacing with port (operand 1)    |
| 1      | 101100  | or       | r/m       | r         |           | Logical inclusive OR the register value (operand 2) into register or memory (operand 1)  |
| 1      | 101101  | or       | r         | r/m       |           | Logical inclusive OR the register or memory value (operand 2) into register (operand 1)  |
| 1      | 101110  | or       | r/m       | i         |           | Logical inclusive OR the immediate value (operand 2) into register or memory (operand 1) |
| 4      | 101111  | send     | i         |           |           | Send empty message to device interfacing with port (operand 1)                           |
| 1      | 110000  | and      | r/m       | r         |           | Logical AND the register value (operand 2) into register or memory (operand 1)           |
| 1      | 110001  | and      | r         | r/m       |           | Logical AND the register or memory value (operand 2) into register (operand 1)           |
| 1      | 110010  | and      | r/m       | i         |           | Logical AND the immediate value (operand 2) into register or memory (operand 1)          |
| 0      | 110011  | hlt      |           |           |           | Halt the program                                                                         |
| 1      | 110100  | jsl      | rel       |           |           | Jump if (signed) less (SF!=OF)                                                           |
| 1      | 110101  | jsge     | rel       |           |           | Jump if (signed) greater or equal (SF=OF)                                                |
| 1      | 110110  | jsle     | rel       |           |           | Jump if (signed) less or equal ((ZF=1) OR (SF!=OF))                                      |
| 1      | 110111  | jsg      | rel       |           |           | Jump if (signed) greater ((ZF=0) AND (SF=OF))                                            |
| 1      | 111000  | jul      | rel       |           |           | Jump if (unsigned) less/carry (CF=1)                                                     |
| 1      | 111001  | juge     | rel       |           |           | Jump if (unsigned) greater or equal/not carry (CF=0)                                     |
| 1      | 111010  | jule     | rel       |           |           | Jump if (unsigned) less or equal (CF=1 AND ZF=1)                                         |
| 1      | 111011  | jug      | rel       |           |           | Jump if (unsigned) greater (CF=0 AND ZF=0)                                               |
| 4      | 111100  | send     | i         | i         | m         | Send message (operand 3) of size (operand 2) device interfacing with port (operand 1)    |
| 4      | 111101  | recv     | i         | m         |           | Store message (operand 2) received from port (operand 1)                                 |
| 0      | 111110  | nop      |           |           |           | No operation                                                                             |
| 1      | 111111  | jmp      | rel       |           |           | Jump                                                                                     |
