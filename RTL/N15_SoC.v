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
    N15 SoC top level
    it consists of:
        - N5 CorePlex
        - AHB NB
        - APB SB
*/

module  N15_SoC #(parameter 
                                CP_SRAM_AW=12,
                                NB_SRAM_AW=14,
                                SYSTICK_CLK_DIV=8'd10,
                                GPIO_SZ=8
                        ) 
        (
            input wire                      HCLK,
            input wire                      HRESETn,

            // CP SRAM Port
            input  wire [31:0]              CPSRAMRDATA,        
            output wire [3:0]               CPSRAMWEN,      
            output wire [31:0]              CPSRAMWDATA,    
            output wire                     CPSRAMCS,       
            output wire [CP_SRAM_AW-3:0]    CPSRAMADDR,

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
            
            // NB SRAM Port
            input  wire [31:0]              NBSRAMRDATA,        
            output wire [3:0]               NBSRAMWEN,      
            output wire [31:0]              NBSRAMWDATA,    
            output wire                     NBSRAMCS,       
            output wire [NB_SRAM_AW-3:0]    NBSRAMADDR,  

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

    wire            NMI;
    wire [23:0]     IRQ;

    wire [31:0]     PRDATA;
    wire            PREADY;
    wire [31:0]     PWDATA;
    wire            PENABLE;
    wire [31:0]     PADDR;
    wire            PWRITE;

    wire [31:0]     HRDATA;
    wire            HREADY;
    wire [31:0]     HADDR;
    wire [31:0]     HWDATA; 
    wire [1:0]      HTRANS;
    wire            HWRITE;
    wire [2:0] 	    HSIZE;

    wire            PCLK;
    wire            PRESETn;


    N15_CorePlex #(
                        .AW(CP_SRAM_AW)
                    ) 
        N15_CP(
            .HCLK(HCLK),
            .HRESETn(HRESETn),

            // AHB-LITE MASTER PORT 
            .HADDR(HADDR),           
            .HSIZE(HSIZE),           
            .HTRANS(HTRANS),         
            .HWDATA(HWDATA),         
            .HWRITE(HWRITE),         
            .HRDATA(HRDATA),         
            .HREADY(HREADY),         
            
            // MISC
            .NMI(NMI),               
            .IRQ(IRQ),               
            .SYSTICKCLKDIV(SYSTICK_CLK_DIV),		
            //.HALT(1'b0),

            // SRAM Port
            .SRAMRDATA(CPSRAMRDATA), 
            .SRAMWEN(CPSRAMWEN),     
            .SRAMWDATA(CPSRAMWDATA), 
            .SRAMCS(CPSRAMCS),       
            .SRAMADDR(CPSRAMADDR),   
            
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
            .SDOE(SDOE)
    );

    AHB_NB #(
                .SRAM_AW(NB_SRAM_AW), 
                .GPIO_SZ(GPIO_SZ)
            ) 
        AHBBUS
        (
            .HCLK(HCLK),
            .HRESETn(HRESETn),

            // AHB-LITE Slave PORT 
            .HADDR(HADDR),            
            .HSIZE(HSIZE),            
            .HTRANS(HTRANS),          
            .HWDATA(HWDATA),          
            .HWRITE(HWRITE),          
            .HRDATA(HRDATA),          
            .HREADY(HREADY),          
            .HREADYOUT(HREADY),

            .IRQ(IRQ),

            // Internal SRAM Port
            .SRAMRDATA(NBSRAMRDATA),     
            .SRAMWEN(NBSRAMWEN),         
            .SRAMWDATA(NBSRAMWDATA),     
            .SRAMCS(NBSRAMCS),           
            .SRAMADDR(NBSRAMADDR),       
            
            // GPIO
            .GPIO_DIN(GPIO_DIN),
            .GPIOD_OUT(GPIOD_OUT),
            .GPIO_PU(GPIO_PU),
            .GPIO_PD(GPIO_PD),
            .GPIO_OE(GPIO_OE),

            // APB Master Port
            .PCLK(PCLK),
            .PRESETn(PRESETn),
            .PRDATA(PRDATA),
            .PREADY(PREADY),
            .PWDATA(PWDATA),
            .PENABLE(PENABLE),
            .PADDR(PADDR),
            .PWRITE(PWRITE)
    );


    APB_SB SB (
            // APB Master Port
            .PCLK(PCLK),
            .PRESETn(PRESETn),

            .PRDATA(PRDATA),
            .PREADY(PREADY),
            .PWDATA(PWDATA),
            .PENABLE(PENABLE),
            .PADDR(PADDR),
            .PWRITE(PWRITE),

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

endmodule

