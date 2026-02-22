#include "xil_printf.h"
#include "xscugic.h"
#include "xscutimer.h"
#include "xgpiops.h"
#include "xparameters.h"
#include "xil_exception.h"

// SCU timer: CPU_CLK/2 = 333333343 Hz
// for 20ms: 333333343 * 0.02 = 6666666
#define DEBOUNCE_LOAD_VALUE  6666666

// LED raw registers
#define DIR_LED    (*((volatile unsigned int *)0xE000A204))
#define enable_LED (*((volatile unsigned int *)0xE000A208))
#define write_LED  (*((volatile unsigned int *)0xE000A040))

volatile int button_flag     = 0;
volatile int debounce_active = 0;

XScuGic   gic;
XScuTimer timer;
XGpioPs   gpio;

// ── Debounce Timer ISR ──
void debounce_isr(void *CallBackRef) {
    XScuTimer *t = (XScuTimer *)CallBackRef;

    // clear timer interrupt
    XScuTimer_ClearInterruptStatus(t);

    // stop timer
    XScuTimer_Stop(&timer);

    // unlock debounce
    debounce_active = 0;

    // re-enable button interrupt
    XGpioPs_IntrEnablePin(&gpio, 50);
    XScuGic_Enable(&gic, XPAR_XGPIOPS_0_INTR);
}

// ── Button ISR ──
void button_isr(void *CallBackRef) {

    if (debounce_active == 0) {
        debounce_active = 1;

        // disable button interrupt
        XScuGic_Disable(&gic, XPAR_XGPIOPS_0_INTR);
        XGpioPs_IntrDisablePin(&gpio, 50);

        // tell main loop
        button_flag = 1;

        // load and start 20ms debounce timer
        XScuTimer_LoadTimer(&timer, DEBOUNCE_LOAD_VALUE);
        XScuTimer_Start(&timer);
    }

    // clear GPIO interrupt
    XGpioPs_IntrClearPin(&gpio, 50);
}

int main() {
    xil_printf("Task 4: Interrupt-Driven Button\r\n");

    // configure LED
    DIR_LED    = DIR_LED    |  (0x1 << 7);
    enable_LED = enable_LED |  (0x1 << 7);

    // initialise GIC
    XScuGic_Config *gic_cfg;
    gic_cfg = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
    XScuGic_CfgInitialize(&gic, gic_cfg, gic_cfg->CpuBaseAddress);

    // initialise GPIO
    XGpioPs_Config *gpio_cfg;
    gpio_cfg = XGpioPs_LookupConfig(0);
    XGpioPs_CfgInitialize(&gpio, gpio_cfg, gpio_cfg->BaseAddr);

    // configure button as input
    XGpioPs_SetDirectionPin(&gpio, 50, 0);

    // configure button interrupt
    XGpioPs_SetIntrTypePin(&gpio, 50, XGPIOPS_IRQ_TYPE_EDGE_RISING);
    XGpioPs_IntrEnablePin(&gpio, 50);

    // initialise SCU timer
    XScuTimer_Config *tmr_cfg;
    tmr_cfg = XScuTimer_LookupConfig(XPAR_SCUTIMER_DEVICE_ID);
    XScuTimer_CfgInitialize(&timer, tmr_cfg, tmr_cfg->BaseAddr);

    // no auto reload (one shot for debounce)
    XScuTimer_DisableAutoReload(&timer);

    // connect button ISR
    XScuGic_Connect(&gic,
        XPAR_XGPIOPS_0_INTR,
        (Xil_InterruptHandler)button_isr,
        (void *)&gpio);

    // connect debounce timer ISR
    XScuGic_Connect(&gic,
        XPAR_SCUTIMER_INTR,
        (Xil_InterruptHandler)debounce_isr,
        (void *)&timer);

    // enable everything
    XScuTimer_EnableInterrupt(&timer);
    XScuGic_Enable(&gic, XPAR_XGPIOPS_0_INTR);
    XScuGic_Enable(&gic, XPAR_SCUTIMER_INTR);

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
        (Xil_ExceptionHandler)XScuGic_InterruptHandler,
        &gic);
    Xil_ExceptionEnable();

    while(1) {
        if (button_flag == 1) {
            button_flag = 0;
            write_LED = write_LED ^ (0x1 << 7);
            xil_printf("Button pressed!\r\n");
        }
    }

    return 0;
}