// 

what i need ? 
1. A timer that fires every X seconds
2. An ISR that runs when it fires
3. ISR increments a counter
4. Main loop prints the counter
5. No printing inside ISR // 

//  what i need to learn about 

   1. What is the TTC timer and how does it work?
2. What is the GIC and what does it do?
3. What is an ISR and how does it connect to both? //

//  

TTC counts to interval
    ↓
TTC signals GIC
    ↓
GIC signals CPU
    ↓
CPU runs ISR
    ↓
ISR clears interrupt, increments counter, sets flag
    ↓
CPU returns to main loop
    ↓
Main loop sees flag, prints counter // 

#include "xil_printf.h"
#include "xscugic.h"
#include "xscutimer.h"
#include "xparameters.h"
#include "xil_exception.h"

// SCU timer runs at CPU_CLK/2 = 666666687/2 = 333333343 Hz
// for 1 second: load value = 333333343
#define TIMER_LOAD_VALUE  333333343

volatile int counter    = 0;
volatile int timer_flag = 0;

XScuGic   gic;
XScuTimer timer;

void timer_isr(void *CallBackRef) {
    XScuTimer *t = (XScuTimer *)CallBackRef;

    // clear interrupt
    XScuTimer_ClearInterruptStatus(t);

    counter++;
    timer_flag = 1;
}

int main() {
    xil_printf("Task 3: Timer Interrupts\r\n");

    // initialise GIC
    XScuGic_Config *gic_cfg;
    gic_cfg = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
    XScuGic_CfgInitialize(&gic, gic_cfg, gic_cfg->CpuBaseAddress);

    // initialise SCU timer
    XScuTimer_Config *tmr_cfg;
    tmr_cfg = XScuTimer_LookupConfig(XPAR_SCUTIMER_DEVICE_ID);
    XScuTimer_CfgInitialize(&timer, tmr_cfg, tmr_cfg->BaseAddr);

    // load timer value for 1 second
    XScuTimer_LoadTimer(&timer, TIMER_LOAD_VALUE);

    // set auto reload so it repeats
    XScuTimer_EnableAutoReload(&timer);

    // connect ISR to GIC
    XScuGic_Connect(&gic,
        XPAR_SCUTIMER_INTR,
        (Xil_InterruptHandler)timer_isr,
        (void *)&timer);

    // enable everything
    XScuTimer_EnableInterrupt(&timer);
    XScuGic_Enable(&gic, XPAR_SCUTIMER_INTR);

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
        (Xil_ExceptionHandler)XScuGic_InterruptHandler,
        &gic);
    Xil_ExceptionEnable();

    // start timer
    XScuTimer_Start(&timer);

    while(1) {
        if (timer_flag == 1) {
            timer_flag = 0;
            xil_printf("Tick! Counter = %d\r\n", counter);
        }
    }

    return 0;
}

