#include "ahb_regs.h"


void dmac_init(uint32 saddr, uint32 daddr, uint32 size, uint8 src_type, uint8 ai_src, uint8 dest_type, uint8 ai_dest){
    *DMAC_SADDR = saddr;
    *DMAC_DADDR = daddr;
    *DMAC_CTRL  = 0x0;
    *DMAC_CTRL  |= (src_type<<8);
    *DMAC_CTRL  |= (src_type<<16);
    *DMAC_CTRL  |= (ai_src<<10);
    *DMAC_CTRL  |= (ai_dest<<18);
    *DMAC_SIZE = size;
}

void dmac_start(){
    *DMAC_CTRL |= 1;
    *DMAC_TRIG = 1;
}

void gpio_init(uint32 dir, uint32 pu, uint32 pd, uint32 im){
    *GPIO_OE = dir;
    *GPIO_PU = pu;
    *GPIO_PD = pd;
    *GPIO_IM = im;
}

uint32 A[]={1, 2, 3, 4, 5, 6};
uint32 B[20];
vuint32 * const IRAM = (vuint32 *) 0x60000000;

main(){
    int sum = 0;
    vuint32 *p = IRAM;
    for(int i=0; i<25; i++) {
        sum += i;
        *p++ = sum;
    }
    gpio_init(0xFF, 0x0, 0x0, 0x0);
    dmac_init(IRAM, GPIO_DATA, 25, 2, 1, 2, 0);
    dmac_start();
    for(int i=0; i<25; i++) sum += i*A[i%4];
    return sum;
}




