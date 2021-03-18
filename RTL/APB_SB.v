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

`include            "../rtl/apb_util.vh"
`include            "../rtl/Peripherals/ip_util.vh"

/*
    APB South Bridge. Up to 16 peripherals.
    Only 10 Peripherals are implemented:
        2 x UART (0-1)
        2 x I2C Masters (2-3)
        2 x SPI Masters (4-5)
        4 x TIMERS (6-9)
*/

module APB_SB (
    // APB Master Port
    input wire              PCLK,
    input wire              PRESETn,

    `APB_MASTER_S_IFC,
    output wire [15:0]      PIRQ,

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

    `APB_DEC_MUX_16(40, DEAD_BEEF)
    
    APB_UART S0 (
            `APB_SLAVE_CONN(0),
            `UART_PORT_PCONN(0)  
        );

    APB_UART S1 (
            `APB_SLAVE_CONN(1),
            `UART_PORT_PCONN(1) 
        );

    APB_I2C S2 (
            `APB_SLAVE_CONN(2),
            `I2C_PORT_PCONN(0)   
    );

    APB_I2C S3 (
            `APB_SLAVE_CONN(3),
            `I2C_PORT_PCONN(1) 
    );

    APB_SPI S4(
            `APB_SLAVE_CONN(4),
            `SPI_PORT_PCONN(0)
    );


    APB_SPI S5(
            `APB_SLAVE_CONN(5),
            `SPI_PORT_PCONN(1)
    );

    APB_TMR32 S6(
            `APB_SLAVE_CONN(6),
            `TMR_PORT_PCONN(0)
    );

    APB_TMR32 S7(
            `APB_SLAVE_CONN(7),
            `TMR_PORT_PCONN(1)
    );

    APB_TMR32 S8(
            `APB_SLAVE_CONN(8),
            `TMR_PORT_PCONN(2)
    );

    APB_TMR32 S9(
            `APB_SLAVE_CONN(9),
            `TMR_PORT_PCONN(3)
    );

    `SLAVE_NOT_USED(10, DEAD_BEEF)
    `SLAVE_NOT_USED(11, DEAD_BEEF)
    `SLAVE_NOT_USED(12, DEAD_BEEF)
    `SLAVE_NOT_USED(13, DEAD_BEEF)
    `SLAVE_NOT_USED(14, DEAD_BEEF)
    `SLAVE_NOT_USED(15, DEAD_BEEF)
    
endmodule


