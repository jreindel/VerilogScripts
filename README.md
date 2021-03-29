# These are python scripts for creating verilog instantiation templates and test benches for use in VIVADO projects (or otherwise).

### Create Instantiation Template usage:
```
./Create_Instantiation_Template.py <file> <debug>
    <file> is required; verilog code for the module you want a template of.
    <debug> is optional; 0 for off (default), 1 for some, 2 for verbose
```    
### Create Testbench usage:
```
./Create_Testbench.py <file> <debug>
    "<file> is required; verilog code for the module you want a testbench of.
    <debug> is optional; 0 for off (default), 1 for some, 2 for verbose
```    
### *Generated files are saved into the same directory as the source file specified*
   
    
Example-... files 
---
These are examples of a verilog module file, an instantiation template (.veo) and a test bench for your reference.


Disclaimer
---
I created these scripts to work mainly with the way I like to specify input and output ports in a module.
If you use a different method the scripts may not work correctly. Here is an example of something which
will work correctly.
```
module Ethernet_Frame_Builder_AXIS(
    input wire cclk, // clock
    input wire reset_n, // asyncronous active low reset
    
    // Header info
    input wire [47:0] dMAC, // destination MAC
    input wire [47:0] sMAC, // source MAC 
    output reg [15:0] eType, // ethernet type. Should be 0x0800 for IPv4 
);
```
Note that `input wire cclk` is all on one line. 
In particular the older style of declaring ports only by name, then later specifying as input wire within the module will not work.

Multiple ports can also be declared on the same line like this:
```
module XGbE_PHY_InitAndResetController(
        input wire CCLK, rst, // clock and reset. This should be clocked by gtrefclk, reset can be global reset
        input wire [5:0] gtpowergood, txprgdivresetdone, txpmaresetdone, gt_tx_reset_done, // input tx triggers
        output reg rxpmaresetdone,gt_rx_cdr_stable, rxprgdivresetdone, gt_rx_reset_done, // input rx triggers 
```


Comments
---
Comments at the end of a port description are preserved and added as comments to the instantiation template. Comments one their own line are not.
```
    // Header info
    input wire [47:0] dMAC, // destination MAC
    input wire [47:0] sMAC, // source MAC 
    input wire [15:0] eType, // ethernet type. Should be 0x0800 for IPv4 
```
The above produces the following. Notice that the first comment `// Header info` is dropped.
```
    .dMAC(dMAC),	// input [47:0] dMAC (destination MAC)
    .sMAC(sMAC),	// input [47:0] sMAC (source MAC)
    .eType(eType),	// input [15:0] eType (ethernet type. Should be 0x0800 for IPv4)
```

The scripts dont always handle the use of /* comment */ comments well. Using this type of comment for port group titles or to commment out ports is not supported.


White Space
---
The scripts dont parse extra white space correctly.
As an example, the following will not work correctly:
```
input  wire [63:0]  tx_axis_tdata,
input  wire [7:0]   tx_axis_tkeep,
input  wire         tx_axis_tvalid,
output wire         tx_axis_tready,
input  wire         tx_axis_tlast,
input  wire         tx_axis_tuser, 
```
To fix this, remove the extra white space so there are single spaces or tabs seperating each item on a line, like this:
```
    input wire [63:0] tx_axis_tdata,
    input wire [7:0] tx_axis_tkeep,
    input wire tx_axis_tvalid,
    output wire tx_axis_tready,
    input wire tx_axis_tlast,
    input wire tx_axis_tuser, 
```


Final Notes
---
I hope this is helpful. It has already saved me hours of manually creating templates in Vivado. Why Xilinx dumped these two featurs moving from ISE I will never understand.

If you can make these scripts *more* helpful, feel free to pull them down and create a branch. Once you have done some testing, make a merge request and your featurs can 
become part of the solution.