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

`timescale          1ns/1ps
`default_nettype    none

`include            "./include/ahb_util.vh"

/*
    NB (AHB BUS) Components
        + SRAM Controller (@ 0x6000_0000)
        + External PSRAM Controller (@ 0x7000_0000), not implemented yet!
        + GPIO (@ 0x4800_0000)
        + APB Bridge (@ 0x4000_0000)


*/
module AHB_NB #(
    parameter SRAM_AW = 14,
    parameter GPIO_SZ = 8
)(
    input wire              HCLK,
    input wire              HRESETn,

    `AHB_SLAVE_IFC(),

    output wire [23:0]          IRQ,

    // Internal SRAM Port
    input  wire [31:0]          SRAMRDATA,        
    output wire [3:0]           SRAMWEN,      
    output wire [31:0]          SRAMWDATA,    
    output wire                 SRAMCS,       
    output wire [SRAM_AW-3:0]   SRAMADDR,     

    // GPIO
    input  wire [GPIO_SZ-1:0]   GPIO_DIN,
	output wire [GPIO_SZ-1:0]   GPIOD_OUT,
	output wire [GPIO_SZ-1:0]   GPIO_PU,
	output wire [GPIO_SZ-1:0]   GPIO_PD,
	output wire [GPIO_SZ-1:0]   GPIO_OE,

    // APB Master Port
    output wire                 PCLK,
    output wire                 PRESETn,

    input wire  [31:0]          PRDATA,
    input wire                  PREADY,
    output wire [31:0]          PWDATA,
    output wire                 PENABLE,
    output wire [31:0]          PADDR,
    output wire                 PWRITE,
    input  wire [15:0]          PIRQ

);

    wire [7:0]  PAGE = HADDR[31:24];
    reg  [7:0]  APAGE;

    wire [3:0]  SPAGE = HADDR[23:20];
    reg  [3:0]  ASPAGE;

    wire [31:0] HRDATA_SRAM, 
                HRDATA_APB,
                HRDATA_GPIO;

    wire        HREADYOUT_SRAM,
                HREADYOUT_APB,
                HREADYOUT_GPIO;

    wire        HSEL_SRAM   =   (PAGE == 8'h60);
    wire        HSEL_GPIO   =   (PAGE == 8'h48);
    wire        HSEL_APB    =   (PAGE == 8'h40);
    
    always@ (posedge HCLK or negedge HRESETn) begin
    if(!HRESETn)
        APAGE <= 8'h0;
    else if(HREADY & HTRANS[1])
        APAGE <= PAGE;
    end

    always@ (posedge HCLK or negedge HRESETn) begin
    if(!HRESETn)
        ASPAGE <= 4'h0;
    else if(HREADY & HTRANS[1])
        ASPAGE <= SPAGE;
    end

    assign HREADYOUT =  (APAGE == 8'h60) ? HREADYOUT_SRAM   :
                        (APAGE == 8'h48) ? HREADYOUT_GPIO   :
                        (APAGE == 8'h40) ? HREADYOUT_APB    :
                        1'b1;

    assign HRDATA   =   (APAGE == 8'h60) ? HRDATA_SRAM   :
                        (APAGE == 8'h48) ? HRDATA_GPIO   :
                        (APAGE == 8'h40) ? HRDATA_APB    :
                        32'hDEADBEEF;

    AHB_SRAM_CTRL #(.AW(SRAM_AW)) SRAM_CTRL (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        
        .HSEL(HSEL_SRAM),
        .HREADYOUT(HREADYOUT_SRAM),
        .HRDATA(HRDATA_SRAM),
        .HREADY(HREADY),
        .HTRANS(HTRANS),
        .HSIZE(HSIZE),
        .HWRITE(HWRITE),
        .HADDR(HADDR),
        .HWDATA(HWDATA),
        
        .SRAMRDATA(SRAMRDATA),    
        .SRAMWEN(SRAMWEN),      
        .SRAMWDATA(SRAMWDATA),    
        .SRAMCS(SRAMCS),       
        .SRAMADDR(SRAMADDR)      
    ); 

    // The GPIO 
    wire GPIO_IRQ;

    AHB_GPIO_PORT #(.SZ(GPIO_SZ)) GPIO_PORT (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        
        .HSEL(HSEL_GPIO),
        .HREADYOUT(HREADYOUT_GPIO),
        .HRDATA(HRDATA_GPIO),
        .HREADY(HREADY),
        .HTRANS(HTRANS),
        .HSIZE(HSIZE),
        .HWRITE(HWRITE),
        .HADDR(HADDR),
        .HWDATA(HWDATA),
        
        .GPIO_DIN(GPIO_DIN),
        .GPIOD_OUT(GPIOD_OUT),
        .GPIO_PU(GPIO_PU),
        .GPIO_PD(GPIO_PD),
        .GPIO_OE(GPIO_OE),    

        .IRQ(GPIO_IRQ)
    ); 


    // PCLK = HCLK/2
    // Change the folowing to change PCLK 
    // Just assign PCLKEN=1 to have PCLK=HCLK
    reg PCLKEN = 0;             
    always @(posedge HCLK)
        PCLKEN = ~ PCLKEN;

    //AHB_APB_BRIDGE 
    AHB_APB_BRIDGE #(.SLOW_PCLK(1)) APB_BRIDGE (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .PCLKEN(PCLKEN),
        
        .HSEL(HSEL_APB),
        .HREADYOUT(HREADYOUT_APB),
        .HRDATA(HRDATA_APB),
        .HREADY(HREADY),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HADDR(HADDR),
        .HWDATA(HWDATA),
        
    // APB Master Port
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PWDATA(PWDATA),
        .PENABLE(PENABLE),
        .PADDR(PADDR),
        .PWRITE(PWRITE),

        .PCLK(PCLK),
        .PRESETn(PRESETn)
    );

    // IRQ Lines
    assign IRQ[7:0]     =   {7'h0, GPIO_IRQ};
    assign IRQ[23:8]    =   PIRQ;

endmodule

