AXI4 Interface Library
======================

Interfaces reperesents only connections and can be used for synthesis.

If you want to drive them for simulation purposes, use classes listed below.

For example projects refer to ./example directory.

You can make yourself convinced by running

    vsim -do make.tcl

in ./example directory and following the instructions. 

Tested in QuestaSim 10.4e and ModelSim 10.5b
 
Interfaces
==========

## AXI4

./src/interface/axi4_if.sv

## AXI4-Lite

./src/interface/axi4_lite_if.sv

## AXI4-Stream

./src/interface/axi4_stream_if.sv

Classes
=======

## Common parameters for all classes

**DATA_WIDTH, ADDR_WIDTH, ID_WIDTH, DEST_WIDTH, USER_WIDTH, AWUSER_WIDTH, WUSER_WIDTH, BUSER_WIDTH, ARUSER_WIDTH RUSER_WIDTH**

Must be equal to connected interface.

**VERBOSE**

Enbales debug text output (higher the value, more information will be outputed).

**WATCHDOG_EN**

Enbales watchdog for handshakes.

**WATCHDOG_LIMIT**

Amount of ticks before watchdog timeout.

## AXI4 Master

./src/class/AXI4Master.sv

### Constructor

**axi4_if axi4_if_v**

**mailbox rd_data_mbx**

### Parameters

**RANDOM_WVALID**

Random deassertion of wvalid signal during write transaction

**RANDOM_RREADY**

Random deassertion of rready signal during read transaction

### Methods

**wr_transaction_byte(** bit [ADDR_WIDTH - 1 : 0] start_addr, bit [7 : 0] wr_byte_q [$] **)**

Nonblocking task that takes byte queue as input, splits it by bursts and sends it.

**wr_transaction_word(** bit [ADDR_WIDTH - 1 : 0] start_addr, bit [DATA_WIDTH - 1 : 0] wr_word_q [$] **)**

Nonblocking task that takes word size queue as input, splits it by bursts and sends it.

**rd_transaction(** bit [ADDR_WIDTH - 1 : 0] start_addr, int words_amount **)**

Non blocking task that reads required amount of data and puts it as word size queue into rd_data_mbx mailbox

**run()**

Enables internal mailbox scanning. Executes at class construction

**stop()**

Disables internal mailbox scanning

### Objects

**event wr_transaction_start**

Triggers when first handshake of firts burst of write transaction appears

**event wr_transaction_end**

Triggers when last handshake of last burst of write transaction appears

**event rd_transaction_start**

Triggers when first handshake of first burst of read transaction appears

**event rd_transaction_end**

Triggers when last handshake of last burst of read transaction appears

## AXI4 Slave

./src/class/AXI4Slave.sv

### Constructor

**axi4_if axi4_if_v**

### Parameters

**RANDOM_WREADY**

Random deassertion of wready signal during write transaction

**RANDOM_RVALID**

Random deassertion of rvalid signal during write transaction

**INIT_PATH**

Relative path to initialization file

### Methods

**init_memory()**

Initialize memory with file specified in INIT_PATH parameter

**run()**

Enables interface listening. Executes at class construction

**stop()**

Disable interface listening

### Objects

**event wr_transaction_start**

Triggers when first handshake of firts burst of write transaction appears

**event wr_transaction_end**

Triggers when last handshake of last burst of write transaction appears

**event rd_transaction_start**

Triggers when first handshake of first burst of read transaction appears

**event rd_transaction_end**

Triggers when last handshake of last burst of write transaction appears

## AXI4-Lite Master

./src/class/AXI4LiteMaster.sv

### Constructor

**axi4_lite_if axi4_lite_if_v**

### Methods

**wr_data(** bit [ADDR_WIDTH - 1 : 0] addr, bit [DATA_WIDTH - 1 : 0] data **)**

Blocking task that writes one word to specified address

**rd_data(** bit [ADDR_WIDTH - 1 : 0] addr, bit [DATA_WIDTH - 1 : 0] data **)**

Blocking task that reads one word from specified address and writes it to passed data signal

## AXI4-Lite Slave

./src/class/AXI4LiteSlave.sv

### Constructor

**axi4_lite_if axi4_lite_if_v**

### Parameters

**INIT_PATH**

Relative path to initialization file

### Methods

**init_memory()**

Initialize memory with file specified in INIT_PATH parameter

**run()**

Enables interface listening. Executes at class construction

**stop()**

Disables interface listening

## AXI4-Stream Master

./src/class/AXI4StreamMaster.sv

### Constructor

**axi4_stream_if axi4_stream_if_v**

### Parameters

**RANDOM_TVALID**

Random deassertion of tvalid signal during packet transmitting

### Methods

**send_pkt(** bit [7 : 0] byte_q [$] **)**

Nonblocking task that takes queue as input and puts it into internal mailbox

**run()**

Runs mailbox scanning. Executed at class creation.

**stop()**

Stops mailbox scanning after last packet will be sent

### Objects

**event pkt_start**

Triggers right after packet was get from mailbox

**event pkt_end**

Triggers right after tready/tvalid/tlast handshake

## AXI4-Stream Slave

./src/class/AXI4StreamSlave.sv

### Constructor

**axi4_stream_if axi4_stream_if_v**

**mailbox rx_data_mbx**

### Parameters

**RANDOM_TREADY**

Random deassertion of tready signal during packet receiving

### Methods

**run()**

Starts receiving incoming data. Every incoming packet will be puted to shared mailbox. Executed at class creation

**stop()**

Stops receiving incoming data.

### Objects

**event pkt_start**

Triggers right after first tvalid detection in incoming packet

**event pkt_end**

Triggers right after received packet was puted in shared mailbox
