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

`timescale 1ns/1ns

`include    "test_file.vh"
`include    "tb_util.vh"

`define     SIM_TIME        500_000_000
`define     SIM_LEVEL       0
//`define   VCD

module n15_soc_tb;

    parameter   AW = 14, 
                GPIO_SZ=8;

    reg clk; 
    reg rst;

    wire            FSCK;
    wire            FCEN;
    wire [3:0]      FDI;
    wire [3:0]      FDO;
    wire            FDOEN;

    wire [GPIO_SZ-1:0]   GPIO_DIN;
	wire [GPIO_SZ-1:0]   GPIOD_OUT;
	wire [GPIO_SZ-1:0]   GPIO_PU;
	wire [GPIO_SZ-1:0]   GPIO_PD;
	wire [GPIO_SZ-1:0]   GPIO_OE;


    wire UART0_RX, UART0_TX, UART1_RX, UART1_TX;

    wire [31:0] cycles = CHIP_CORE.SoC.N15_CP.N5_CPU.CORE.CSR_CYCLE;
    wire [31:0] instr = CHIP_CORE.SoC.N15_CP.N5_CPU.CORE.CSR_INSTRET;
    wire [31:0] PC = CHIP_CORE.SoC.N15_CP.N5_CPU.CORE.PC;


    //`define TDI_TEST

`ifdef TDI_TEST
    reg [31:0]  tdi_rdata;
    reg [15:0]  tdi_cycles;
    reg [7:0]   tdi_res;
    
    `include "tdi_dv_tasks.vh"

    initial begin
        #3000;
        tdi_send_ping(tdi_res);
        #500;
        tdi_send_cycles(tdi_cycles);
        #500;
        tdi_send_halt(tdi_res);
        #500;
        tdi_send_write(32'h2000_0100, 32'h600DBAD0);
        #500;
        tdi_send_read(32'h2000_0100, tdi_rdata);
        #300;
        tdi_send_resume(tdi_res);
        #1000;
        tdi_send_reset(tdi_res);
    end

`endif

    N15_CHIP_CORE   #(  .RST_LEVEL(1'b0),
                        .CP_SRAM_AW(12),
                        .NB_SRAM_AW(14),
                        .SYSTICK_CLK_DIV(8'd10),
                        .GPIO_SZ(8)
                    ) 
        CHIP_CORE (
            .clk(clk),
            .rst(rst),

            // QSPI FLASH Port
            .FSCK(FSCK),
            .FCEN(FCEN),
            .FDI(FDI),
            .FDO(FDO),
            .FDOEN(FDOEN),

            .SCK(SCK),
            .SDI(SDI),
            .SDO(SDO),
            .SDOE(SDOE),

            // GPIO
            .GPIO_DIN(GPIO_DIN),
            .GPIOD_OUT(GPIOD_OUT),
            .GPIO_PU(GPIO_PU),
            .GPIO_PD(GPIO_PD),
            .GPIO_OE(GPIO_OE),
            
            // S0: UART 0
            .UART0_RX(UART0_RX),
            .UART0_TX(UART0_TX),
            
            // S1: UART 1
            .UART1_RX(UART1_RX),
            .UART1_TX(UART1_TX)
        );


    // The Quad I/O Flash Memory
    wire [3:0] fdio = FDOEN ? FDO : 4'bzzzz;
    assign FDI = fdio;

    sst26wf080b flash(
        .SCK(FSCK),
        .SIO(fdio),
        .CEb(FCEN)
    );

    initial begin
	    #1  $readmemh(`TEST_FILE, flash.I0.memory);
    end

    // The testbench infrastructure
    `TB_INIT(n15_soc_tb, "n15_soc_tb.vcd", `SIM_LEVEL, `SIM_TIME)

    `TB_CLK_GEN(clk, 10)

    `TB_RESET_ASYNC(rst, 0, 327)

    // Terminate the smulation with ebreak instruction.
    // Calculate the CPI using the CSRs
    wire ebreak = CHIP_CORE.SoC.N15_CP.N5_CPU.CORE.instr_ebreak & CHIP_CORE.SoC.N15_CP.N5_CPU.CORE.C2;
    always @ (posedge clk) 
        if(ebreak) begin
            $display("CPI=%d.%0d", cycles/instr,(cycles/instr)*10/instr );
            $display("CYC:%d", cycles);
            $display("INSTR:%d", instr);
            $finish;
        end


endmodule

