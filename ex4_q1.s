.global main 
.text

main: #setup interrupts
    movsg $2, $cctrl    #copy the value of cctrl into $2 (getting control register)
    andi  $2, $2, 0xf   #disables all interrupts
    ori   $2, $2, 0xA2  #Enable IRQ1, IRQ3, and IE (interrupt enable)
    movgs $cctrl, $2    #now copy the new cpu Control register back into cctrl

    addi $1, $0, 3      #enable parallel control register
    sw $1, 0x73004($0)

    movsg $2, $evec     #copy the old handlers address into $2
    sw $2, old_vector($0)   #save it to memory
    la $2, handler      #get the address of our handler
    movgs $evec, $2     #copy the old handlers address into the exception vector register

main_loop: #loop for printing to SSD
    lw $3, counter($0)  #gets the counter value stores in $3
    remi $3, $3, 10     #getting the digit to write as decimal 
    sw $3, 0x73003($0)  #prints to rightmost SSD
    lw $3, counter($0)  #gets the second digit number to write as decimal  to SSD
    divi $3, $3, 10     #ensures correct number
    remi $3, $3, 10     #getting the digit to write as decimal 
    sw  $3, 0x73002($0) #prints to next SSD

j main_loop #jumps back up to main loop 

handler:
    movsg $13, $estat #gets the value of exception status
    andi $13, $13, 0xffd0 #checks if its NOT IRQ1 interrupt
    beqz $13, handle_USER_IRQ1 #If its our interrupt call our corresponding handler
    andi $13, $13, 0xff70 #checks if its not IRQ3 interrupt
    beqz $13, handle_PARALLEL_IRQ3 #If its our interrupt call our corresponding handler

    lw $13, old_vector($0) #jumps back to our old vector we saved
    jr $13 #its not any of our handlers or intended interrupts

handle_USER_IRQ1:
    sw $0, 0x7f000($0) #acknowledges the interrupt for this IRQ1
    j addCount #adds to count

handle_PARALLEL_IRQ3:
    sw $0, 0x73005($0) #acknowledges the interrupt for this IRQ3
    lw $13, 0x73001($0) #checks if button is pressed
    bnez $13, addCount  #if buttons are pressed then goes to add count
    rfe #otherwise just returns to where exception occured

addCount:
    lw $13, counter($0) #gets current counter value
    addi $13, $13, 1 #increments the counter value
    sw $13, counter($0) #stores new counter value back into counter
    rfe #returns from handlers to where exception occured

#data setup for counter and old handler address
.data
counter: .word 0

old_vector: .word 0
