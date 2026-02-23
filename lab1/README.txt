Task#1 is a gift , after set up you could easily download a ready example then interact with the terminal .
Task#2 is  doable , from the user guide you get that PS has only one LED which is MIO7 and has two buttons MIO50 and MIO51,from the parameters library you learn the base for bank 1 and bank 0(MIO50 and MIO51 controlling registers are setting in the bank1 while the led in bank 0). once you get the base register you look up the offset on google on the TRM file (for me AI done it for me) and it is a simple masking and a simple program.
Task#3 was challenging the least , the logic is easy its very easy but to map through all the registers with not enough knowledge of the CPU architecture is impossible so we used drive but when u use drives the configuration now become the problem ! i don't know how we were supposed to configure them and even using their functions while the lab requires a good knowledge of C embedded it was just impossible but managed to write a code and explain the logic behind it although and demonstrated using volatile and how to build an ISR also flag polling, it didn't work because the of the timer config i assume or i really don't know .
Task#4 this even harder but i managed to complete two of its steps because it didn't require a timer for a button to fire the ISR, so the bouncing issue was not solved.






attached are the codes started the lab with 
the first and the second lab are functional and bullet prove , the third one and the last one does not work and have been modified heavily during the lab (i even used a usleep library and called it inside the while loop and that didn't work so i think its not the timer i think its GPIO interrupt routing through GIC)


DECLERATION of the use of AI : 
AI was used for the drivers config and to fine the offset addresses and spend a great deal of time on it to grasp every new concept introduced by the lecture or the tutorial or the lab. 

 

