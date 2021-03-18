#include "apb_regs.h"
#include "ahb_regs.h"

int uart_init(unsigned int n, unsigned int prescaler){
    if(n>1) return -1;
    if(n==1){
        *UART1_PRESCALER = prescaler;
        *UART1_IM = 0;
        *UART1_CTRL = 1;
    }
    else {
        *UART0_PRESCALER = prescaler;
        *UART0_IM = 0;
        *UART0_CTRL = 1;
    }
}

int uart_puts(unsigned int n, unsigned char *msg, unsigned int len){
    int i;
    if(n>1) return -1;
    if(n==0){
        for(i=0; i<len; i++){
            while(*UART0_STATUS&1); // TX Not Full
            *UART0_DATA = msg[i]; 
        }
    }  else {
        for(i=0; i<len; i++){
            while(*UART1_STATUS&1); // TX Not Full
            *UART1_DATA = msg[i]; 
        }
    }   
    return 0;
}

int uart_gets(unsigned int n, unsigned char *msg, unsigned int len){
    int i;
    if(n>1) return -1;
    if(n==0){
        for(i=0; i<len; i++){
            while(*UART0_STATUS&8); // RX Not Empty
            msg[i] = *UART0_DATA;  
        }
    } else {
        for(i=0; i<len; i++){
            while(*UART1_STATUS&8); // RX Not Empty
            msg[i] = *UART1_DATA;  
        }
    }    
    return 0;
}

int volatile x;
main(){
    //gpio_init(0xFF, 0x0, 0x0, 0x0);
    uart_init (0, 3);
    uart_puts(0, "hello", 5);
    for(int i=0; i<1000; i++) x = i;

}




