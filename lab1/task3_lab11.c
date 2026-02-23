#include "xil_printf.h"
#include "xscugic.h"
#include "xttcps.h"
#include "xparameters.h"
#include "xil_exception.h"

volatile int counter    = 0;
volatile int timer_flag = 0;

XScuGic  gic;
XTtcPs   timer;

void timer_isr(void *CallBackRef) {
    XTtcPs *t = (XTtcPs *)CallBackRef;
    XTtcPs_ClearInterruptStatus(t, XTtcPs_GetInterruptStatus(t));
    counter++;
    timer_flag = 1;
}

int main() {
    xil_printf("Task 3: Timer Interrupts\r\n");

    // initialise GIC
    XScuGic_Config *gic_cfg;
    gic_cfg = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
    XScuGic_CfgInitialize(&gic, gic_cfg, gic_cfg->CpuBaseAddress);

    // initialise TTC timer
    XTtcPs_Config *tmr_cfg;
    tmr_cfg = XTtcPs_LookupConfig(XPAR_XTTCPS_0_DEVICE_ID);
    XTtcPs_CfgInitialize(&timer, tmr_cfg, tmr_cfg->BaseAddress);

    // set interval
    XInterval interval;
    u8 prescaler;
    XTtcPs_CalcIntervalFromFreq(&timer, 1, &interval, &prescaler);
    XTtcPs_SetInterval(&timer, interval);
    XTtcPs_SetPrescaler(&timer, prescaler);

    // connect ISR
    XScuGic_Connect(&gic,
        XPAR_XTTCPS_0_INTR,
        (Xil_InterruptHandler)timer_isr,
        (void *)&timer);

    XTtcPs_EnableInterrupts(&timer, XTTCPS_IXR_INTERVAL_MASK);
    XScuGic_Enable(&gic, XPAR_XTTCPS_0_INTR);

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
        (Xil_ExceptionHandler)XScuGic_InterruptHandler,
        &gic);
    Xil_ExceptionEnable();

    XTtcPs_Start(&timer);

    while(1) {
        if (timer_flag == 1) {
            timer_flag = 0;
            xil_printf("Tick! Counter = %d\r\n", counter);
        }
    }

    return 0;
}