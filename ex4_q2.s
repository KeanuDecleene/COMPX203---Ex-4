.global main 
.text

main: #setup interrupts
    movsg $2, $cctrl    #copy the value of cctrl into $2 (getting control register)
    andi  $2, $2, 0xf   #disables all interrupts
    ori   $2, $2, 0x0042  #Enable IRQ2, and IE
    movgs $cctrl, $2    #now copy the new cpu Control register back into cctrl

    sw $0, 0x72003($0)  #acknowledge interrupt
    addi $2, $0, 2400   #setting timer for every 1 second
    sw $2, 0x72001($0)  #putting it inter timer load register
    addi $2, $0, 0x3    #enables the timer and sets it to auto restart
    sw $2, 0x72000($0)  #putting enabler into control register

    movsg $2, $evec     #copy the old handlers address into $2
    sw $2, old_vector($0)   #save it to memory
    la $2, handler      #get the address of our handler
    movgs $evec, $2     #copy the old handlers address into the exception vector register

main_loop: #loop for printing to SSD
    lw $3, seconds($0)  #gets the counter value stores in $3
    remi $3, $3, 10     #getting the digit to write as decimal 
    sw $3, 0x73003($0)  #prints to rightmost SSD
    lw $3, seconds($0)  #gets the second digit number to write as decimal  to SSD
    divi $3, $3, 10     #ensures correct number
    remi $3, $3, 10     #getting the digit to write as decimal 
    sw  $3, 0x73002($0) #prints to next SSD
    lw $3, seconds($0)  #it can count up to a larger digit number to all the SSDs
    divi $3, $3, 100  #by 100 for 3 digit numbers
    remi $3, $3, 10     
    sw  $3, 0x73007($0)
    lw $3, seconds($0)  
    divi $3, $3, 1000 #by 1000 for 4 digit numbers
    remi $3, $3, 10     
    sw  $3, 0x73006($0)
    
j main_loop #loops

handler:
    movsg $13, $estat #gets the value of exception status
    andi $13, $13, 0xffb0 #checks if its NOT IRQ2 interrupt
    beqz $13, handle_IRQ2 #If its our interrupt call our corresponding handler

    lw $13, old_vector($0) #jumps back to our old vector we saved
    jr $13 #its not any of our handlers or intended interrupts

handle_IRQ2:
    sw $0, 0x72003($0) #acknowledges the interrupt for this IRQ2

    lw $13, seconds($0) #gets current counter value
    addi $13, $13, 1 #increments the counter value
    sw $13, seconds($0) #stores new counter value back into counter
    rfe #returns from handlers to where exception occured

#data setup for counter and old handler address
.data
seconds: .word 0
old_vector: .word 0
