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

`timescale              1ns/1ps
`default_nettype        none
`include                "./include/ahb_util.vh"

module AHB_GPIO_PORT #(parameter SZ=8) (
    input  wire        HCLK,    
    input  wire        HRESETn, // Reset

    `AHB_SLAVE_IFC(),
    
    output wire IRQ,
	
    // IP Interface
	input  wire [SZ-1:0] GPIO_DIN,
	output wire [SZ-1:0] GPIOD_OUT,
	output wire [SZ-1:0] GPIO_PU,
	output wire [SZ-1:0] GPIO_PD,
	output wire [SZ-1:0] GPIO_OE
);
    localparam  GPIO_OUT_OFF   =   8'h00, 
                GPIO_DATA_OFF   =   8'h0,
                GPIO_PU_OFF    =   8'h04, 
                GPIO_PD_OFF    =   8'h08,
                GPIO_OE_OFF    =   8'h0C,
                GPIO_IM_OFF    =   8'h10,
                GPIO_RIS_OFF   =   8'h14;
                
   
    wire [31:0] GPIO_DATA_REG;
    wire [31:0] GPIO_RIS_REG;
    
    `AHB_SLAVE_EPILOGUE()

    `AHB_REG(GPIO_OUT_REG, SZ, GPIO_OUT_OFF, 0, )
    `AHB_REG(GPIO_PU_REG, SZ, GPIO_PU_OFF, 0, )
    `AHB_REG(GPIO_PD_REG, SZ, GPIO_PD_OFF, 0, )
    `AHB_REG(GPIO_OE_REG, SZ, GPIO_OE_OFF, 0, )
    `AHB_REG(GPIO_IM_REG, SZ, GPIO_IM_OFF, 0, )
    
    `AHB_READ
        `AHB_REG_READ(GPIO_DATA_REG, GPIO_DATA_OFF)
        `AHB_REG_READ(GPIO_PU_REG, GPIO_PU_OFF)
        `AHB_REG_READ(GPIO_PD_REG, GPIO_PD_OFF)
        `AHB_REG_READ(GPIO_OE_REG, GPIO_OE_OFF)
        `AHB_REG_READ(GPIO_IM_REG, GPIO_IM_OFF)
        `AHB_REG_READ(GPIO_RIS_REG, GPIO_RIS_OFF)
        32'hDEAD_BEEF; 
    
    assign GPIO_DATA_REG    = GPIO_DIN;

	assign GPIOD_OUT        = GPIO_OUT_REG;
	assign GPIO_PU          = GPIO_PU_REG;
	assign GPIO_PD          = GPIO_PD_REG;
	assign GPIO_OE          = GPIO_OE_REG;

	assign HREADYOUT = 1'b1;     // Always ready

    assign IRQ = |(GPIO_IM_REG & GPIO_DATA_REG & ~GPIO_OE_REG);

endmodule