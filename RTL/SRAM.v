/*
     _  _ _ ___   ___       ___ 
    | \| / | __| / __| ___ / __|
    | .` | |__ \ \__ \/ _ \ (__ 
    |_|\_|_|___/ |___/\___/\___|
	Copyright 2020 Mohamed Shalan
	
	Licensed under the Apache License, Version 2.0 (the "License"); 
	you may not use this file except in compliance with the License. 
	You may obtain a copy of the License at:

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software 
	distributed under the License is distributed on an "AS IS" BASIS, 
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
	See the License for the specific language governing permissions and 
	limitations under the License.
*/

/*
    This is a wrapper for the SRAM Macro.
    Change it to use technologu specific SRAM.
    Currently, an RTL model (just for simulation)
*/

module SRAM #(parameter AW=14) (
    input   wire            HCLK,
    output  reg  [31:0]     SRAMRDATA,      // SRAM Read Data
    input   wire [3:0]      SRAMWEN,        // SRAM write enable (active high)
    input   wire [31:0]     SRAMWDATA,      // SRAM write data
    input   wire            SRAMCS,         // SRAM Chip Select
    input   wire [AW-3:0]   SRAMADDR        // SRAM address
);

    localparam SIZE = 2**AW;
    reg [31:0] MEM[SIZE-1:0];
    
    always @(posedge HCLK) begin
        if(SRAMCS) begin
            SRAMRDATA = MEM[SRAMADDR];
            if(SRAMWEN[0]) MEM[SRAMADDR][7:0] <= SRAMWDATA[7:0];
            if(SRAMWEN[1]) MEM[SRAMADDR][15:8] <= SRAMWDATA[15:8];
            if(SRAMWEN[2]) MEM[SRAMADDR][23:16] <= SRAMWDATA[23:16];
            if(SRAMWEN[3]) MEM[SRAMADDR][31:24] <= SRAMWDATA[31:24];
        end
    end

endmodule