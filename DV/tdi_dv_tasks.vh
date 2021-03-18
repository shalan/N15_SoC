
    localparam  CMD_PING    = 8'hA1,
                CMD_CYCLES  = 8'hA2,
                CMD_HALT    = 8'hA4,
                CMD_RESUME  = 8'hA5,
                CMD_RESET   = 8'hA6,
                CMD_READ    = 8'hA8,
                CMD_WRITE   = 8'hA9;

    reg     SCK, SDI;
    wire    SDO, SDOE;
    reg     SCK_en;

    initial begin 
        SCK_en = 0;
        SCK = 1'b1;
    end

    always #(150/2) if(SCK_en) SCK = ~ SCK;

    task tdi_send_ping;
    output [7:0] res;
    reg [31:0] tmp;
    begin
        send_cmd(CMD_PING);
        #555;
        read_data(tmp, 8);
        res = tmp[31:24];
    end
    endtask

    task tdi_send_cycles;
    output [15:0] res;
    reg [31:0] tmp;
    begin
        send_cmd(CMD_CYCLES);
        #555;
        read_data(tmp, 16);
        res = tmp[31:16];
    end
    endtask

    task tdi_send_halt;
    output [7:0] res;
    reg [31:0] tmp;
    begin
        send_cmd(CMD_HALT);
        #555;
        read_data(tmp, 8);
        res = tmp[31:24];
    end
    endtask

    task tdi_send_resume;
    output [7:0] res;
    reg [31:0] tmp;
    begin
        send_cmd(CMD_RESUME);
        #555;
        read_data(tmp, 8);
        res = tmp[31:24];
    end
    endtask

    task tdi_send_reset;
    output [7:0] res;
    reg [31:0] tmp;
    begin
        send_cmd(CMD_RESET);
        #555;
        read_data(tmp, 8);
        res = tmp[31:24];
    end
    endtask

    task tdi_send_read;
    input [31:0] addr;
    output [31:0] rdata;
    begin
        send_cmd(CMD_READ);
        #555;
        send_data(addr, 32);
        #500;
        read_data(rdata, 32);
    end
    endtask

    task tdi_send_write;
    input [31:0] addr;
    input [31:0] wdata;
    begin
        send_cmd(CMD_WRITE);
        #555;
        send_data(addr, 32);
        #500;
        send_data(wdata, 32);
    end
    endtask
    
    task send_cmd;
    input [7:0] cmd;
        send_data(cmd, 8);
    endtask

    task send_data;
    input [31:0] data;
    input [7:0] size;
    integer i;
        begin
            SCK_en = 1;
            SDI = data[0];
            @(posedge SCK)
            for(i=0; i<size-1; i=i+1) begin
                @(negedge SCK);
                data = data >> 1;
                SDI = data[0];
            end
            @(posedge SCK);
            SCK_en = 0;
        end
    endtask

    task read_data;
    output [31:0] data;
    input [7:0] size;
    integer i;
        begin
            data = 0;
            SCK_en = 1;
            for(i=0; i<size; i=i+1) begin
                @(posedge SCK);
                data = {SDO, data[31:1]};
            end
            SCK_en = 0;
        end
    endtask

    