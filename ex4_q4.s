.global main 
.text

main: #setup interrupts
    sw $ra, terminate($0)
    
    movsg $2, $cctrl    #copy the value of cctrl into $2 (getting control register)
    andi  $2, $2, 0xf   #disables all interrupts
    ori   $2, $2, 0xC2  #Enable IRQ2, IRQ3 and IE
    movgs $cctrl, $2    #now copy the new cpu Control register back into cctrl

    addi $2, $0, 3    #enabling parallel control register
    sw $2, 0x73004($0)

    sw $0, 0x72003($0)  #acknowledge interrupt
    addi $2, $0, 24   #setting timer for every 100 times per second
    sw $2, 0x72001($0)  #putting it into timer load register
    addi $2, $0, 0x2      #enables the timer and sets it to auto restart
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
    andi $13, $13, 0xffb0 #checks if it is IRQ2 interrupt
    beqz $13, handle_IRQ2 #If its our interrupt call our corresponding handler

    movsg $13, $estat #gets the value of exception status
    andi $13, $13, 0xff70 #checks if it is IRQ3 interrup
    beqz $13, handle_IRQ3 #If its our interrupt call our corresponding handler

    lw $13, old_vector($0) #jumps back to our old vector we saved
    jr $13 #its not any of our handlers or intended interrupts

handle_IRQ2:
    sw $0, 0x72003($0) #acknowledges the interrupt for this IRQ2

    lw $13, seconds($0) #gets current counter value
    addi $13, $13, 1 #increments the counter value
    sw $13, seconds($0) #stores new counter value back into counter
    rfe #returns from handlers to where exception occured

handle_IRQ3:
    subui $sp, $sp, 3 #setting up stack storing registers
    sw $1, 1($sp)
    sw $2, 2($sp)
    sw $3, 3($sp)

    sw $0, 0x73005($0) #acknowledges the interrupt for this IRQ3

    lw $13, 0x73001($0) #gets button press
    andi $1, $13, 1 #checking if button 0 pressed
    bnez $1, button_Start
    andi $2, $13, 2 #checking if button 1 is pressed
    bnez $2, button_Reset
    andi $3, $13, 4 #checking if button 2 is pressed
    bnez $3, button_Terminate
    #deals with stack 
    j return_rfe

button_Start: #button 0
    lw $13, 0x72000($0) #Sees if timer is running
    seqi $13, $13, 0x2
    beqz $13, pause

    resume:
    lw $13, 0x72000($0)
    addi $13, $0, 0x3 #resumes timer 
    sw $13, 0x72000($0) 
    j return_rfe #return

    pause:
    lw $13, 0x72000($0)
    addi $13, $0, 0x2 #pauses timer 
    sw $13, 0x72000($0) 
    j return_rfe #return

button_Reset: #button 1
    lw $13, 0x72000($0)
    seqi $13, $13, 0x2
    beqz $13, record_Times #goes to print to serial port if timer is running

    sw $0, seconds($0) #resets the SSDs
    j return_rfe


record_Times: #print to Serial 2 formatted String
    lw $13, carriage($0)
    jal string_Ready

    lw $13, newline($0)
    jal string_Ready

    lw $13, seconds($0)
    divi $13, $13, 1000 #divide number by 1000
    jal number_Ready

    lw $13, seconds($0)
    divi $13, $13, 100 #divide by 100
    jal number_Ready

    lw $13, period($0)
    jal string_Ready

    lw $13, seconds($0)
    divi $13, $13, 10
    jal number_Ready
    
    lw $13, seconds($0)
    jal number_Ready
    
    j return_rfe #return from interrupt and restore stack

    number_Ready:
        lw $1, 0x71003($0) #if serial port ready to transmit
        andi $1, $1, 0x2
        beqz $1, number_Ready
        remi $13, $13, 10 #get correct number
        addi $13, $13, '0' #convert to ascii
        sw $13, 0x71000($0)
        jr $ra

    string_Ready:
        lw $1, 0x71003($0) # if serial port ready to transmit
        andi $1, $1, 0x2
        beqz $1, string_Ready
        sw $13, 0x71000($0)
        jr $ra
        

button_Terminate: #button 2
    lw $ra, terminate($0)
    jr $ra

return_rfe:
    lw $3, 3($sp) #adds back stack and returns rfe
    lw $2, 2($sp)
    lw $1, 1($sp)
    addui $sp, $sp, 3
    rfe

#data setup
.data
seconds: .word 0
old_vector: .word 0
carriage: .word '\r'
newline: .word '\n'
period: .word '.'
terminate: .word 0