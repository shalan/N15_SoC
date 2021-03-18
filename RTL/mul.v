/*
 	 _   _  __ ___     __   _________  
	| \ | |/ _(_) \   / /__|___ /___ \ 
	|  \| | |_| |\ \ / / _ \ |_ \ __) |
	| |\  |  _| | \ V /  __/___) / __/ 
	|_| \_|_| |_|  \_/ \___|____/_____|
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

`define INST_MUL    3'b000
`define INST_MULH   3'b001
`define INST_MULHSU 3'b010
`define INST_MULHU  3'b011

module mul #(parameter size = 32) (
    input clk, 
    input rst_n,
    input [size-1:0] op1, op2,
    input [2:0] op,
    output wire [size-1:0] result,
    output done,
    input start
);

    reg[2*size-1:0] mul_temp;
    reg[2*size-1:0] mul_temp_invert;
    
    reg [size-1:0] mul_op1, mul_op2;
    wire [size-1:0] reg1_data_invert = ~op1 + 1;
    wire [size-1:0] reg2_data_invert = ~op2 + 1;

    reg [1:0] cntr;
    always @(posedge clk or negedge rst_n)
        if(~rst_n) cntr <= 2'b00;
        else 
            if(start) 
                cntr <= cntr + 1'b1; 
            else 
                cntr <= 2'b00;

    always @ (posedge clk) if(start) begin
        case (op)
                `INST_MUL, `INST_MULHU: begin
                    mul_op1 <= op1;
                    mul_op2 <= op2;
                end
                `INST_MULHSU: begin
                    mul_op1 <= (op1[31] == 1'b1)? (reg1_data_invert): op1;
                    mul_op2 <= op2;
                end
                `INST_MULH: begin
                    mul_op1 <= (op1[31] == 1'b1)? (reg1_data_invert): op1;
                    mul_op2 <= (op2[31] == 1'b1)? (reg2_data_invert): op2;
                end
                default: begin
                    mul_op1 <= op1;
                    mul_op2 <= op2;
                end
        endcase
    end

    
    always @(posedge clk) begin
        mul_temp <= mul_op1 * mul_op2;
        mul_temp_invert <= ~mul_temp + 1;
    end
    //assign mul_temp = mul_op1 * mul_op2;
    //assign mul_temp_invert = ~mul_temp + 1;

    reg [31:0] reg_wdata;
    always @* begin
        case (op)
            `INST_MUL: reg_wdata = mul_temp[31:0];
            `INST_MULHU: reg_wdata = mul_temp[63:32];
            `INST_MULH: 
                case ({op1[31], op2[31]})
                    2'b00: reg_wdata = mul_temp[63:32];
                    2'b11: reg_wdata = mul_temp[63:32];
                    2'b10: reg_wdata = mul_temp_invert[63:32];
                    default: reg_wdata = mul_temp_invert[63:32];
                endcase
            `INST_MULHSU: begin
                if (op1[31] == 1'b1) begin
                    reg_wdata = mul_temp_invert[63:32];
                end else begin
                    reg_wdata = mul_temp[63:32];
                end
            end
        endcase
    end
    
    assign result = reg_wdata;

    //assign done = start;
    assign done = (cntr == 2'b10);
endmodule
