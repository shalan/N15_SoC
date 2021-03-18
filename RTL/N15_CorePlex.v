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

`timescale                  1ns/1ps
`default_nettype            none

/*
    A CorePlex for the N5 CPU. 
    It consists of the following:
        + FLASH Controller w/ RO DMC cache (@ 0x0000_0000)
        + SRAM Controller (@ 0x2000_0000)
        + CorePlex Peripherals: 
            - DMA Controller (@ 0xD000_0000)
            - Flash writer (@ 0xD100_0000)
        + AHB-Lite Master Port for
            - I/O Peripherals (@ 0x4000_0000)
            - Internal SRAM Controller (@ 0x6000_0000)
            - External Quad/Octa PSRAM Controller (@ 0x6000_0000)

    IRQ Lines:
        + IRQ0-7    :   For CorePlex Peripherals (DMAC: IRQ0)
        + IRQ8-15   :   For NB
        + IRQ16-31  :   FOE SB
*/

module N15_CorePlex #(
    parameter AW = 14
)
(
    input wire              HCLK,
    input wire              HRESETn,
    
    // AHB-Lite Master Port
    output wire [31:0]      HADDR,
    output wire [31:0]      HWDATA, 
    output wire [1:0]       HTRANS,
    output wire [2:0]       HSIZE,
    output wire             HWRITE,
    input  wire [31:0]      HRDATA,
    input  wire             HREADY,
    
        // MISC
    input	wire 		    NMI,				
  	input	wire [23:0]	    IRQ,				
  	input	wire [7:0]	    SYSTICKCLKDIV,				
	//input 	wire		    HALT,

    // SRAM Port
    input  wire [31:0]      SRAMRDATA,        
    output wire [3:0]       SRAMWEN,      
    output wire [31:0]      SRAMWDATA,    
    output wire             SRAMCS,       
    output wire [AW-3:0]    SRAMADDR,     
    
    // QSPI FLASH Port
    output  wire            FSCK,
    output  wire            FCEN,
    input   wire [3:0]      FDI,
    output  wire [3:0]      FDO,
    output  wire            FDOEN,

    // DMAC
    output  wire            DMAC_IRQ,

    // DBG IFC
    input  wire SCK,
    input  wire SDI,
    output wire SDO,
    output wire SDOE
);
    
    wire [3:0]  PAGE = HADDR_CPU[31:28];
    reg  [3:0]  APAGE;

    wire [31:0] HRDATA_CPU;
    wire        HREADY_CPU;
    wire [31:0] HADDR_CPU;
    wire [31:0] HWDATA_CPU; 
    wire [1:0]  HTRANS_CPU;
    wire        HWRITE_CPU;
    wire [2:0] 	HSIZE_CPU;

    wire [31:0] HRDATA_MUX;
    wire        HREADY_MUX;

    wire [31:0] HRDATA_DMAC;
    wire        HREADY_DMAC;
    wire [31:0] HADDR_DMAC;
    wire [31:0] HWDATA_DMAC; 
    wire [1:0]  HTRANS_DMAC;
    wire        HWRITE_DMAC;
    wire [2:0] 	HSIZE_DMAC;
    
    wire [31:0] HRDATA_FLASH;
    wire        HREADY_FLASH;

    wire [31:0] HRDATA_SRAM;
    wire        HREADY_SRAM;

    wire [31:0] HRDATA_SYSCTRL;
    wire        HREADY_SYSCTRL;

    wire [31:0] HRDATA_CPP;
    wire        HREADY_CPP;


    wire [31:0] HRDATA_IO = HRDATA;
    wire        HREADY_IO = HREADY;
    
    wire         fr_sck;
    wire         fr_ce_n;
    wire [3:0]   fr_din;
    wire [3:0]   fr_dout;
    wire         fr_douten;
    
    
    // DECODER
    wire HSEL_FLASH     = (PAGE == 4'h0);
    wire HSEL_SRAM      = (PAGE == 4'h2);
    wire HSEL_IO        = (PAGE == 4'h4);
    wire HSEL_IRAM      = (PAGE == 4'h6);
    wire HSEL_ERAM      = (PAGE == 4'h7);
    wire HSEL_CPP       = (PAGE == 4'hD);
    wire HSEL_SYSCTRL   = (PAGE == 4'hE);

    wire    HSEL_EXT_ACCESS = HSEL_IRAM | HSEL_ERAM | HSEL_IO;
    reg     AHSEL_EXT_ACCESS;
       
    always@ (posedge HCLK or negedge HRESETn) begin
    if(!HRESETn)
        APAGE <= 4'h0;
    else if(HREADY_CPU & HTRANS_CPU[1])
        APAGE <= PAGE;
    end

    always@ (posedge HCLK or negedge HRESETn) begin
    if(!HRESETn)
        AHSEL_EXT_ACCESS <= 1'h0;
    else if(HREADY_CPU & HTRANS_CPU[1])
        AHSEL_EXT_ACCESS <= HSEL_EXT_ACCESS;
    end

    assign HREADY_CPU =
        (APAGE == 4'h0) ? HREADY_FLASH      :
        (APAGE == 4'h2) ? HREADY_SRAM       :
        (APAGE == 4'hD) ? HREADY_CPP        :
        AHSEL_EXT_ACCESS ? HREADY_MUX       :
        1'b1;

    assign HRDATA_CPU =
        (APAGE == 4'h0) ? HRDATA_FLASH      :
        (APAGE == 4'h2) ? HRDATA_SRAM       :
        (APAGE == 4'hD) ? HRDATA_CPP        :
        AHSEL_EXT_ACCESS ? HRDATA_MUX       :
        32'hDEAD_BEEF;

    AHB_SRAM_CTRL #( .AW(AW) ) 
        SRAM_CTRL (
            .HCLK(HCLK),
            .HRESETn(HRESETn),
            .HSEL(HSEL_SRAM),
            .HREADY(HREADY_CPU),
            .HTRANS(HTRANS_CPU),
            .HSIZE(HSIZE_CPU),
            .HWRITE(HWRITE_CPU),
            .HADDR(HADDR_CPU),
            .HREADYOUT(HREADY_SRAM),
            .HRDATA(HRDATA_SRAM),
            .HWDATA(HWDATA_CPU),
            
            .SRAMRDATA(SRAMRDATA),    
            .SRAMWEN(SRAMWEN),      
            .SRAMWDATA(SRAMWDATA),    
            .SRAMCS(SRAMCS),       
            .SRAMADDR(SRAMADDR)      
    ); 

    AHB_FLASH_CTRL FLASH_CTRL (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        
        .HSEL(HSEL_FLASH),
        .HREADY(HREADY_CPU),
        .HTRANS(HTRANS_CPU),
        .HWRITE(HWRITE_CPU),
        .HADDR(HADDR_CPU),
        .HREADYOUT(HREADY_FLASH),
        .HRDATA(HRDATA_FLASH),

        .sck(fr_sck),
        .ce_n(fr_ce_n),
        .din(fr_din),
        .dout(fr_dout),
        .douten(fr_douten)     
    );

    // IRQ Lines
    wire [31:0] CPU_IRQ;
    assign CPU_IRQ[0] = DMAC_IRQ;
    assign CPU_IRQ[7:1] = 7'h0;     // Not Used
    assign CPU_IRQ[31:8] = IRQ;

    NfiVe32_CPU N5_CPU (
	    .HCLK(HCLK),
		.HRESETn(HRESETn),

		// AHB-LITE MASTER PORT for Instructions and Data
		.HADDR(HADDR_CPU),             
		.HSIZE(HSIZE_CPU),             
		.HTRANS(HTRANS_CPU),           
		.HWDATA(HWDATA_CPU),           
		.HWRITE(HWRITE_CPU),           
		.HRDATA(HRDATA_CPU),           
		.HREADY(HREADY_CPU),          
			
	    // MISCELLANEOUS 
  	    .NMI(NMI),				    
  	    .IRQ(CPU_IRQ),				    
  	    .SYSTICKCLKDIV(SYSTICKCLKDIV),
	    //.HALT(HALT)

        .SCK(SCK),
		.SDI(SDI),
		.SDO(SDO),
		.SDOE(SDOE)
    );

    // The following are the CorePlex Peripherals
    wire [3:0]  SPAGE       = HADDR_CPU[27:24];
    reg  [3:0]  ASPAGE;
    wire        HSEL_DMAC   = HSEL_CPP & (SPAGE == 4'h0);
    wire        HSEL_FW     = HSEL_CPP & (SPAGE == 4'h1);
    wire [31:0] HRDATA_DMAC_S;
    wire [31:0] HRDATA_FW;
    wire        HREADYOUT_DMAC_S;
    wire        HREADYOUT_FW;
    
    always@ (posedge HCLK or negedge HRESETn) begin
    if(!HRESETn)
        ASPAGE <= 4'h0;
    else if(HREADY_CPU & HTRANS_CPU[1])
        ASPAGE <= SPAGE;
    end  

    assign HREADY_CPP =
        (ASPAGE == 4'h0) ? HREADYOUT_DMAC_S :
        (ASPAGE == 4'h1) ? HREADYOUT_FW     :
        1'b1;

    assign HRDATA_CPP =
        (ASPAGE == 4'h0) ? HRDATA_DMAC_S   :
        (ASPAGE == 4'h1) ? HRDATA_FW       :
        32'hDEADBEEF;

    AHB_FLASH_WRITER FW (
        .HCLK(HCLK),
        .HRESETn(HRESETn),

        .HSEL(HSEL_FW),
        .HREADY(HREADY_CPU),
        .HTRANS(HTRANS_CPU),
        .HWRITE(HWRITE_CPU),
        .HADDR(HADDR_CPU),
        .HWDATA(HWDATA_CPU),
        .HREADYOUT(HREADYOUT_FW),
        .HRDATA(HRDATA_FW),
        
        .fr_sck(fr_sck),
        .fr_ce_n(fr_ce_n),
        .fr_din(fr_din),
        .fr_dout(fr_dout),
        .fr_douten(fr_douten), 

        .fm_sck(FSCK),
        .fm_ce_n(FCEN),
        .fm_din(FDI),
        .fm_dout(FDO),
        .fm_douten(FDOEN)   
    );

    AHB_DMAC_1CH DMAC(
        .HCLK(HCLK),
		.HRESETn(HRESETn),
    
        .IRQ(DMAC_IRQ),

        // AHB-Lite Slave Interface
        .HSEL(HSEL_DMAC),
        .HREADY(HREADY_CPU),
        .HTRANS(HTRANS_CPU),
        .HWRITE(HWRITE_CPU),
        .HADDR(HADDR_CPU),
        .HWDATA(HWDATA_CPU),
        .HREADYOUT(HREADYOUT_DMAC_S),
        .HRDATA(HRDATA_DMAC_S),

        // AHB-Lite Master Interface
        .M_HADDR(HADDR_DMAC),             
		.M_HSIZE(HSIZE_DMAC),             
		.M_HTRANS(HTRANS_DMAC),           
		.M_HWDATA(HWDATA_DMAC),           
		.M_HWRITE(HWRITE_DMAC),           
		.M_HRDATA(HRDATA_DMAC),           
		.M_HREADY(HREADY_DMAC)
    );


    // 2x1 Mux multiplexor for the CorePlex AHB-lite Master port
    // The inputs to the MUX are the N5 CPU and the DMAC master ports
    AHB_MUX_2M1S #(.SZ(32)) MMUX (
	    .HCLK(HCLK),
		.HRESETn(HRESETn),
    
        // Port 1
        .HADDR_M1(HADDR_CPU),             
		.HSIZE_M1(HSIZE_CPU),             
		.HTRANS_M1(HTRANS_CPU & {HSEL_EXT_ACCESS,HSEL_EXT_ACCESS}),           
		.HWDATA_M1(HWDATA_CPU),           
		.HWRITE_M1(HWRITE_CPU),           
		.HRDATA_M1(HRDATA_MUX),           
		.HREADY_M1(HREADY_MUX), 
	
        // Port 2
	    .HADDR_M2(HADDR_DMAC),             
		.HSIZE_M2(HSIZE_DMAC),             
		.HTRANS_M2(HTRANS_DMAC),           // comment the mask for testing
		.HWDATA_M2(HWDATA_DMAC),           
		.HWRITE_M2(HWRITE_DMAC),           
		.HRDATA_M2(HRDATA_DMAC),           
		.HREADY_M2(HREADY_DMAC),
	
        // Master Port
	    .HADDR(HADDR),             
		.HSIZE(HSIZE),             
		.HTRANS(HTRANS),           
		.HWDATA(HWDATA),           
		.HWRITE(HWRITE),           
		.HRDATA(HRDATA),
		.HREADY(HREADY)
);

endmodule
