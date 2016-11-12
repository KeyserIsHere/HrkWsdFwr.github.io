## HUB Specification

This is the architecture overview for the hub computing units.

__All cycle values currently listed are for example purposes. Must test to see what works best.__

Overview
--------

Hub's are 8-bit computing devices that can talk with other hub's and modules through interface-able ports.

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
