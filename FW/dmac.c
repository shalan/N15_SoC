#include "ahb_regs.h"


void dmac_init(uint32 saddr, uint32 daddr, uint32 size, uint8 ai_src, uint8 ai_dest){
    *DMAC_SADDR = saddr;
    *DMAC_DADDR = daddr;
    *DMAC_CTRL  = 0x060600;
    //*DMAC_CTRL  |= (2<<8);
    //*DMAC_CTRL  |= (2<<16);
    //if(ai_src) *DMAC_CTRL  != (1<<10);
    //if(ai_dest) *DMAC_CTRL  != (1<<18);
    *DMAC_SIZE = size;
}

void dmac_start(){
    *DMAC_CTRL |= 1;
    *DMAC_TRIG = 1;
}

uint32 A[]={1, 2, 3, 4, 5, 6};
uint32 B[20];

main(){
    int sum = 0;
    dmac_init(A, B, 5, 1, 1);
    dmac_start();
    for(int i=0; i<25; i++) sum += i*A[i%4];
    return sum;
}