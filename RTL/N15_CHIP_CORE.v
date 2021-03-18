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

`include            "../RTL/Peripherals/rtl/ip_util.vh"

/*
    The Chip Core
    It has everything other than the I/O pads.
        - SoC
        - SRAM Blocks
        - Reset Synchronizer
        - Clock Control (if any)
        - Analog Peripherals (if any)
*/

module  N15_CHIP_CORE   #(  parameter 
                                RST_LEVEL=1'b0,
                                CP_SRAM_AW=12,
                                NB_SRAM_AW=14,
                                SYSTICK_CLK_DIV=8'd10,
                                GPIO_SZ=8
                        ) 
        (
            input wire                      clk,
            input wire                      rst,

            // QSPI FLASH Port
            output  wire                    FSCK,
            output  wire                    FCEN,
            input   wire [3:0]              FDI,
            output  wire [3:0]              FDO,
            output  wire                    FDOEN,

            // DBG IFC
            input  wire                     SCK,
            input  wire                     SDI,
            output wire                     SDO,
            output wire                     SDOE, 

            // NB GPIO
            input  wire [GPIO_SZ-1:0]       GPIO_DIN,
            output wire [GPIO_SZ-1:0]       GPIOD_OUT,
            output wire [GPIO_SZ-1:0]       GPIO_PU,
            output wire [GPIO_SZ-1:0]       GPIO_PD,
            output wire [GPIO_SZ-1:0]       GPIO_OE,
            
            // SB Peripherals
            // S0: UART 0
            `UART_PORT(0),
            
            // S1: UART 1
            `UART_PORT(1),

            // S2: I2C 0
            `I2C_PORT(0),

            // S3: I2C 1
            `I2C_PORT(1),

            // S4: SPI 0
            `SPI_PORT(0),  

            // S5: SPI 1
            `SPI_PORT(1),  

            // S6 : TMR32 0
            `TMR_PORT(0),

            // S7 : TMR32 1
            `TMR_PORT(1),

            // S8 : TMR32 2
            `TMR_PORT(2),

            // S9 : TMR32 3
            `TMR_PORT(3)

        );

        //clock control
        wire HCLK = clk;

        // Reset Synchronizer
        reg [1:0] rst_sync;
        always @(posedge HCLK)
            rst_sync <= {rst_sync[0], rst};
        
        wire    HRESETn;
        generate
            if(RST_LEVEL == 1'b0)
                assign HRESETn = rst_sync[1];
            else
                assign HRESETn = ~ rst_sync[1];
        endgenerate

        // The SoC 
        wire [31:0]              CPSRAMRDATA;        
        wire [3:0]               CPSRAMWEN;      
        wire [31:0]              CPSRAMWDATA;    
        wire                     CPSRAMCS;       
        wire [CP_SRAM_AW-3:0]    CPSRAMADDR;

        wire [31:0]              NBSRAMRDATA;
        wire [3:0]               NBSRAMWEN;      
        wire [31:0]              NBSRAMWDATA;    
        wire                     NBSRAMCS;       
        wire [NB_SRAM_AW-3:0]    NBSRAMADDR; 

        N15_SoC #(  .CP_SRAM_AW(12),
                    .NB_SRAM_AW(14),
                    .SYSTICK_CLK_DIV(8'd10),
                    .GPIO_SZ(8)
                ) 
        SoC (
            .HCLK(HCLK),
            .HRESETn(HRESETn),

            // CP SRAM Port
            .CPSRAMRDATA(CPSRAMRDATA), 
            .CPSRAMWEN(CPSRAMWEN),     
            .CPSRAMWDATA(CPSRAMWDATA), 
            .CPSRAMCS(CPSRAMCS),       
            .CPSRAMADDR(CPSRAMADDR), 

            // QSPI FLASH Port
            .FSCK(FSCK),
            .FCEN(FCEN),
            .FDI(FDI),
            .FDO(FDO),
            .FDOEN(FDOEN),

            // TDI
            .SCK(SCK),
            .SDI(SDI),
            .SDO(SDO),
            .SDOE(SDOE),

            // NB Internal SRAM Port
            .NBSRAMRDATA(NBSRAMRDATA),     
            .NBSRAMWEN(NBSRAMWEN),         
            .NBSRAMWDATA(NBSRAMWDATA),     
            .NBSRAMCS(NBSRAMCS),           
            .NBSRAMADDR(NBSRAMADDR),  

             // GPIO
            .GPIO_DIN(GPIO_DIN),
            .GPIOD_OUT(GPIOD_OUT),
            .GPIO_PU(GPIO_PU),
            .GPIO_PD(GPIO_PD),
            .GPIO_OE(GPIO_OE),
            
            // SB Peripherals
            // S0: UART 0
            `UART_PORT_CONN(0),
            
            // S1: UART 1
            `UART_PORT_CONN(1),

            // S2: I2C 0
            `I2C_PORT_CONN(0),

            // S3: I2C 1
            `I2C_PORT_CONN(1),

            // S4: SPI 0
            `SPI_PORT_CONN(0),

            // S5: SPI 1
            `SPI_PORT_CONN(1),

            // S6 : TMR32 0
            `TMR_PORT_CONN(0),

            // S7 : TMR32 1
            `TMR_PORT_CONN(1),

            // S8 : TMR32 2
            `TMR_PORT_CONN(2),

            // S9 : TMR32 3
            `TMR_PORT_CONN(3)
        );

        // The SRAM MACROS
        // The CorePlex SRAM 
        SRAM #(.AW(CP_SRAM_AW)) CP_SRAM(
            .HCLK(HCLK),
            .SRAMRDATA(CPSRAMRDATA),    
            .SRAMWEN(CPSRAMWEN),      
            .SRAMWDATA(CPSRAMWDATA),  
            .SRAMCS(CPSRAMCS),       
            .SRAMADDR(CPSRAMADDR)   
        );

        // The NB SRAM
        SRAM #(.AW(NB_SRAM_AW)) NB_SRAM(
            .HCLK(HCLK),
            .SRAMRDATA(NBSRAMRDATA),    
            .SRAMWEN(NBSRAMWEN),      
            .SRAMWDATA(NBSRAMWDATA),  
            .SRAMCS(NBSRAMCS),       
            .SRAMADDR(NBSRAMADDR)   
        );        


endmodule

