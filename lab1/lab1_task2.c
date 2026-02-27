#define DIR_LED (*((volatile unsigned int *)0xE000A204))
#define enable_LED  (*((volatile unsigned int*)0xE000A208))
#define write_LED  (*((volatile unsigned int *)0xE000A040))
#define DIR_button  (*((volatile unsigned int *)0xE000A244))
 
#define read_button (*((volatile unsigned int *)0xE000A064))
int pressed_button(void)
{ 
   if ((read_button >> 18) & 1) {
        return 1 ; 
   }   else {
        return 0 ;
    }
    }
    
int main() 
{ 
    DIR_button = DIR_button & ~(0x1 << 18) ;
    DIR_LED = DIR_LED  | (0x1 << 7) ;
    enable_LED = enable_LED | (0x1 << 7) ;
    int prev_state = 0 ;
    while(1) { 
        int current_state = pressed_button() ;
        if (current_state == 1 && prev_state == 0) { 
            write_LED = write_LED ^ (0x1 << 7) ;
        }
        prev_state = current_state; 
    }
}