*-----------------------------------------------------------
* Title      :  CSS422A Winter 2019/2020
* Written by :  Johnathan Hewit & Scott Blake
* Date       :  02-07-2020
* Description:  Motorola 68K Disassembler - Final Project
*               Loads an EASy68K source test file, collects
*               a starting address and an ending address
*               from the user, then dissassembles test code
*               data, and reassembles, then prints to the
*               console.
*-----------------------------------------------------------

***********************************************************************
*                               Equates                               *
***********************************************************************
***********************************************************************
*                          OpCode Mask Library                        *
* This section takes creates a library of all OpCode hex conversions  *
*           from binary. This will be used to check later             *
***********************************************************************
OP_ORI_TO_CCR      EQU      $003c
OP_ORI_TO_SR       EQU      $007c
OP_ANDI_TO_CCR     EQU      $023c
OP_ANDI_TO_SR      EQU      $027c
OP_EORI_TO_CCR     EQU      $0a3c
OP_EORI_TO_SR      EQU      $0a7c
OP_ILLEGAL         EQU      $4afc
OP_RESET           EQU      $4e70
OP_NOP             EQU      $4e71
OP_STOP            EQU      $4e72
OP_RTE             EQU      $4e73
OP_RTS             EQU      $4e75
OP_TRAPV           EQU      $4e76
OP_RTR             EQU      $4e77
OP_BTST            EQU      $0800
OP_BCHG            EQU      $0840
OP_BCLR            EQU      $0880
OP_BSET            EQU      $08c0
OP_MOVE_FROM_SR    EQU      $40c0
OP_MOVE_TO_CCR     EQU      $44c0
OP_MOVE_TO_SR      EQU      $46c0
OP_NBCD            EQU      $4800
OP_PEA             EQU      $4840
OP_TAS             EQU      $4ac0
OP_JSR             EQU      $4e80
OP_JMP             EQU      $4ec0
OP_ASR_MEM         EQU      $e0c0
OP_ASL_MEM         EQU      $e1c0
OP_LSR_MEM         EQU      $e2c0
OP_LSL_MEM         EQU      $e3c0
OP_ROXR_MEM        EQU      $e4c0
OP_ROXL_MEM        EQU      $e5c0
OP_ROR_MEM         EQU      $e6c0
OP_ROL_MEM         EQU      $e7c0 
OP_ASR_REG         EQU      $e000
OP_ASL_REG         EQU      $e100
OP_LSR_REG         EQU      $e008
OP_LSL_REG         EQU      $e108
OP_ROXR_REG        EQU      $e010
OP_ROXL_REG        EQU      $e110
OP_ROR_REG         EQU      $e018
OP_ROL_REG         EQU      $e118
OP_MOVEM_D0        EQU      $4880
OP_MOVEM_D1        EQU      $4c80
OP_MOVE_ORI_DATA   EQU      $0000
OP_ANDI            EQU      $0200
OP_SUBI            EQU      $0400
OP_ADDI            EQU      $0600
OP_EORI            EQU      $0a00
OP_CMPI            EQU      $0c00
OP_NEGX            EQU      $4000
OP_CLR             EQU      $4200
OP_NEG             EQU      $4400
OP_NOT             EQU      $4600
OP_TST             EQU      $4a00
OP_LEA             EQU      $41c0 
OP_DIVU            EQU      $80c0
OP_DIVS            EQU      $81c0
OP_MULU            EQU      $c0c0
OP_MULS            EQU      $c1c0
OP_SUBA            EQU      $90c0
OP_CMPA            EQU      $b0c0
OP_ADDA            EQU      $d0c0
OP_MOVEA           EQU      $0040
OP_MOVEQ           EQU      $7000
OP_CMP             EQU      $b000
OP_EOR             EQU      $b100
OP_BRANCH          EQU      $6000
OP_OR              EQU      $8000
OP_SUB             EQU      $9000
OP_AND             EQU      $c000
OP_ADD             EQU      $d000

OP_ADDQ            EQU      $5000

***********************************************************************
*                      Additional Utility Equates                     *
***********************************************************************
LINES_PER_WINDOW   EQU      31              ; Maximum number of lines in output window
NIBBLE1            EQU      $ffc0
NIBBLE2            EQU      $ff80
NIBBLE3            EQU      $ff00
NIBBLE4            EQU      $f1c0
NIBBLE5            EQU      $f118
NIBBLE6            EQU      $f0c0
NIBBLE7            EQU      $f000
LOW_ORDER_NIBBLE   EQU      $000F           ; For use with ANDI in isolating the low order of bits
MARKER             EQU      $00             ; This is used to signify the end of a line in the output buffer
CR                 EQU      $0D             ; Carriage Return
LF                 EQU      $0A             ; Line Feed
TAB                EQU      $09             ; Tab for spacing
CRNL               EQU      $0D0A           ; CR then NL
STACK              EQU      $000A0000       ; Stack pointer starting address
BUFSIZE            EQU      64              ; Size of the decoded buffer
YES_UPPER          EQU      $59             ; Uppercase value for 'yes' input in response to REPEAT_OR_QUIT prompt
YES_LOWER          EQU      $79             ; Lowercase value for 'yes' input in response to REPEAT_OR_QUIT prompt
NO_UPPER           EQU      $4E             ; Uppercase value for 'no' input in response to REPEAT_OR_QUIT prompt
NO_LOWER           EQU      $6E             ; Lowercase value for 'no' input in response to REPEAT_OR_QUIT prompt

***********************************************************************
*                           Program Start                             *
***********************************************************************
    
    ORG     $1000

START:

    LEA     STACK,SP            ; Load stack pointer location ($000A0000)
    JSR     RESET_BUFFER        ; Resets the DECODE_BUFFER

***********************************************************************
*                           User Interface                            *
* Registers:                                                          *
*           D0: Holds the TRAP task.                                  *
*           D1: Holds the length of the ASCII input.                  *
*           D2: Holds the start address in HEX.                       *
*           D3: Holds the end address in HEX.                         *
*           D4: Holds the stack address in HEX.                       *
*           A0: Pointer to the start address in HEX.                  *
*           A1: Holds pointer to output & location to store the ASCII *
*               input.                                                *
*           A5: Holds pointer to start address for test file.         *
*           A6: Holds pointer to end address for test file.           *
***********************************************************************
    ;Welcome
    LEA     GREET_USER,A1       ; Load greeting to A1
    MOVE.B  #14,D0
    TRAP    #15                 ; Display greeting to console
    
GET_START_ADDR:
    ;Prompt
    LEA     START_PROMPT,A1     ; Load prompt for start address
    MOVE.B  #14,D0
    TRAP    #15                 ; Display prompt to console
    ;Get Input
    MOVE.B  #2,D0               ; Prep for input
    LEA     ASCII_START,A1      ; Load storage location for start address
    TRAP    #15
    ;Validation check: input > 0 && input < 9
    CMP.W   #$0009,D1           ; input.length >= 9?
    BGE     INVALID_START_ADDR
    CMP.W   #$0000,D1           ; input.length == 0?
    BEQ     INVALID_START_ADDR
    BSR     ATOH                ; Jump to ASCII -> HEX conversion
    MOVE.L  D2,A5               ; Move converted start address to A5  
    
GET_END_ADDR:
    ;Prompt
    LEA     END_PROMPT,A1       ; Load prompt for end address
    MOVE.B  #14,D0
    TRAP    #15                 ; Display prompt to console
    ;Get Input
    MOVE.B  #2,D0               ; Prep for input
    LEA     ASCII_END,A1        ; Load storage location for end address
    TRAP    #15                 ; Display prompt to console
    ;Validation check: input > 0 && input < 9
    CMP.W   #$0009,D1           ; input.length >= 9?
    BGE     INVALID_END_ADDR
    CMP.W   #$0000,D1           ; input.length == 0?
    BEQ     INVALID_END_ADDR
    BSR     ATOH                ; Jump to ASCII -> HEX conversion
    MOVE.L  D2,A6               ; Move converted end address to A6
    
VALIDATE_ADDR_PAIR:
    ;Validation check: start != end && start < end
    MOVE.L  A5,D2               ; Put start address into D2 to compare
    MOVE.L  A6,D3               ; Put end address into D3 to compare
    CMP.L   D2,D3               ; start == end?
    BEQ     INVALID_SAME_ADDR   ; If so, notify and loop
    CMP.L   D3,D2               ; end > start?
    BGE     INVALID_ADDR_PAIR   ; If so, notify and loop
    MOVE.L  #STACK,D4           ; Put stack address into D4
    CMP.L   D2,D4               ; start == stack?
    BEQ     INVALID_STACK_ADDR  ; If so, notify and loop
    CMPI.L  #$1000,D2           ; start == org?
    BEQ     INVALID_ORG_ADDR    ; If so, notify and loop 
    ;Valid addresses: Begin Op Decoding
    JSR     DECODE              ; Jump to Op_Decode subroutine
    BRA     REPEAT_OR_EXIT      ; Decode complete - Check if user wants to decode again or quit

DECODE_PAUSE:
    ;Pauses output and prompts user to continue
    LEA     CONTINUE_PROMPT,A3  ; Load into A3 to protect output buffer
    JSR     LOAD_DECODED_BUFFER ; Load message
    JSR     PRINT_BUFFER        ; Display message
    MOVE.L  DECODED_BUFFER,A1   ; 
    MOVE.L  #5,D0
    TRAP    #15
    BRA     DECODE_LOOP

REPEAT_OR_EXIT:
    ;Check if user wants to start over and disassemble again
    MOVEM.L D0/D3/A1,-(SP)
REPEAT_OR_EXIT_LOOP:
    LEA     REPEAT_OR_QUIT,A1   ; Load message
    MOVE.B  #14,D0
    TRAP    #15                 ; Display message
    ;Get Input
    MOVE.B  #2,D0
    LEA     ASCII_Y_OR_N,A1     ; Load location to store response
    TRAP    #15                 ; Display message
    ;Validate expected characters
    MOVE.B  ASCII_Y_OR_N,D3     ; Transfer response to D3 for comparison
    CMPI.B  #YES_UPPER,D3       ; response == 'Y'?
    BEQ     CONTINUE_DECODE     ; Restart program
    CMPI.B  #YES_LOWER,D3       ; response == 'y'?
    BEQ     CONTINUE_DECODE     ; Restart program
    CMPI.B  #NO_UPPER,D3        ; response == 'N'?
    BEQ     EXIT_PROGRAM        ; Exit program
    CMPI.B  #NO_LOWER,D3        ; response == 'n'?
    BEQ     EXIT_PROGRAM        ; Exit program
    ;Bad data received, notify and loop again
    LEA     INVALID_ANSWER,A1   ; Load message
    MOVE.B  #14,D0
    TRAP    #15                 ; Display message
    BRA     REPEAT_OR_EXIT_LOOP ; Loop to get correct input
CONTINUE_DECODE:
    MOVEM.L (SP)+,D0/D3/A1      ; Pop registers to continue
    BRA     START               ; Start program from beginning

EXIT_PROGRAM:
    ;Thanks and farewell
    LEA     EXIT_MESSAGE,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVEM.L (SP)+,D0/D3/A1      ; Pop registers back out of stack
    JMP     EXIT
    
********************************************************************* 
*                  UI Input Error Console Output                    *
*********************************************************************
INVALID_END_ADDR:
    ;Notify
    MOVE.B  #1,D1
    JSR     ERROR_HANDLER           ; Display message
    
INVALID_START_ADDR:
    ;Notify
    MOVE.B  #2,D1
    JSR     ERROR_HANDLER           ; Display message
    
INVALID_INPUT:
    ;Notify
    MOVE.B  #3,D1
    JSR     ERROR_HANDLER           ; Display message
    MOVEM.L (SP)+,D0/D3             ; Pop stack (calling routine is ATOH)

INVALID_SAME_ADDR:
    ;Notify
    MOVE.B  #4,D1
    JSR     ERROR_HANDLER           ; Display message

INVALID_ADDR_PAIR:
    ;Notify
    MOVE.B  #5,D1
    JSR     ERROR_HANDLER           ; Display message

INVALID_STACK_ADDR:
    ;Notify
    MOVE.B  #6,D1
    JSR     ERROR_HANDLER           ; Display message

INVALID_ORG_ADDR:
    ;Notify
    MOVE.B  #7,D1
    JSR     ERROR_HANDLER           ; Display message

*************************************************************
*         UI Utility - ASCII to HEX Conversion              *
*           SOURCE: https://www.asciitable.com/             *
* Registers:                                                *
*           D0: Used to hold the next ASCII Character.      *
*           D1: Used to hold counter variable for loop.     *
*           D2: Used to hold the final HEX value of ASCII.  *
*           D3: Used to compare address to determine if odd.*
*************************************************************
ATOH:
            ;Convert from ASCII to HEX
            MOVEM.L D0/D3,-(SP)             ; Load the stack with data registers
            CLR.L   D2
            ;Validate Bits Are Within HEX Range
CONVERT:    
            MOVE.B  (A1)+,D0                ; Grab first byte and increment pointer
            CMPI.B  #$39,D0                 ; Check upper bounds of HEX range for 0-9
            BLE     CHECK_LOW_BOUNDS_NO     ; If value <= 39, it's likely a number
            CMPI.B  #$46,D0                 ; Check upper bounds of HEX range for A-F
            BLE     CHECK_UP_BOUNDS_CHAR    ; If value <= 46, it's likely a letter
            BRA     INVALID_INPUT           ; Otherwise, it's not a valid input
            
CHECK_LOW_BOUNDS_NO:
            CMPI.B  #$30,D0                 ; Check lower bounds of HEX range for 0-9
            BLT     INVALID_INPUT           ; If value < 30, it's out of range for 0-9
            SUBI.B  #$30,D0                 ; Convert number to HEX
            ADD.B   D0,D2                   ; Store HEX value
            SUBI.W  #$0001,D1               ; Decrement counter, i--
            CMPI.W  #$0000,D1               ; Check to see if loop is done
            BEQ     CONVERT_DONE            ; If so, check if odd number and store if not
            ROL.L   #4,D2                   ; Otherwise, grab the next byte
            BRA     CONVERT                 ; Continue loop
            
CHECK_UP_BOUNDS_CHAR:
            CMPI.B  #$41,D0                 ; Check lower bounds of HEX range for A-F
            BLT     INVALID_INPUT           ; If value < 41, it's out of range for A-F
            SUBI.B  #$37,D0                 ; Convert character to HEX
            ADD.B   D0,D2                   ; Store HEX value
            SUBI.B  #$0001,D1               ; Decrement counter, i--
            CMPI.W  #$0000,D1               ; Check to see if loop is done
            BEQ     CONVERT_DONE            ; If so, check if odd number and store if not
            ROL.L   #4,D2                   ; Otherwise, grab the next byte
            BRA     CONVERT                 ; Continue loop
            
CONVERT_DONE:
            ;Check if address is an odd number
            MOVE.B  D2,D3                   ; Copy value into register for comparison 
            AND.B   #$01,D3
            CMP.B   #$01,D3                 ; Check if value is odd
            BEQ     INVALID_INPUT           ; If so, invalid input
            ;Return to routine that called
            MOVEM.L (SP)+,D0/D3             ; Pop registers in the stack to restore values
            RTS

*************************************************************
*               UI Utility - Error Handler                  *
*Registers:                                                 *
*           D0: Used to hold the TRAP command.              *
*           D1: Still holds the value for which entry in the*
*               table we need to jump to.                   *
*           A0: Used to hold the address of the table we    *
*               will be indexing.                           *
*           A1: Still used to hold the error message to     *
*               output to console.
*************************************************************
ERROR_HANDLER
        MULU        #6,D1              ; Compute displacement
        LEA         ERROR_TABLE,A0
        JSR         0(A0,D1)        
        
ERROR_TABLE
        JMP         ERROR_0
        JMP         ERROR_1 
        JMP         ERROR_2 
        JMP         ERROR_3 
        JMP         ERROR_4
        JMP         ERROR_5
        JMP         ERROR_6
        JMP         ERROR_7  

ERROR_0
        LEA         UNSUPPORTED_OP,A1   ; Load message
        MOVE.B      #14,D0
        TRAP        #15                 ; Display message
        BRA         START               ; Start program from beginning
ERROR_1
        LEA         INVALID_END,A1      ; Load message
        MOVE.B      #14,D0
        TRAP        #15                 ; Display message
        BRA         GET_END_ADDR        ; Loop back through user input prompts 
      
ERROR_2
        LEA         INVALID_START,A1    ; Load message
        MOVE.B      #14,D0
        TRAP        #15                 ; Display message
        BRA         GET_START_ADDR      ; Loop back through user input prompts 
       
ERROR_3
        LEA         INVALID_ADDR,A1     ; Load message
        MOVE.B      #14,D0
        TRAP        #15                 ; Display message
        BRA         GET_START_ADDR      ; Loop back through user input prompts
 
ERROR_4
        LEA         INVALID_SAME,A1     ; Load message
        MOVE.B      #14,D0
        TRAP        #15                 ; Display message
        BRA         GET_START_ADDR      ; Loop back through user input prompts
       
ERROR_5
        LEA         INVALID_PAIR,A1     ; Load message
        MOVE.B      #14,D0
        TRAP        #15                 ; Display message
        BRA         GET_START_ADDR      ; Loop back through user input prompts
 
ERROR_6
        LEA         INVALID_STACK,A1    ; Load message
        MOVE.B      14,D0
        TRAP        #15                 ; Display message
        BRA         GET_START_ADDR      ; Loop back through user input prompts

ERROR_7
        LEA         INVALID_ORG,A1      ; Load message
        MOVE.B      #14,D0
        TRAP        #15                 ; Display message
        BRA         GET_START_ADDR      ; Loop back through user input prompts


*************************************************************
*                UI Utility - Print Buffer                  *
************************************************************* 
* Add MARKER to (A1)+,then print contents of (A1) when A1 = #DECODED_BUFFER
PRINT_BUFFER:
    MOVE.B      #MARKER,(A1)+
    MOVE.L      #DECODED_BUFFER,A1
    
    MOVEM.L     D0/D1,-(SP)        * Save registers
    MOVE.B      #14,D0
    TRAP        #15
    MOVEM.L     (SP)+,D0/D1         * Restore registers
    JSR         RESET_BUFFER
    RTS   
RESET_BUFFER:
    MOVE.L  #DECODED_BUFFER,A1
    RTS

*************************************************************
*             UI Utility - Load Decoded Buffer              *
*Registers:                                                 *
*           D4: This register holds the contents at the     *
*               buffer's current address and is used to     *
*               transfer it to A1 (the actual print buffer).*
*           A1: Still the primary address pointer for the   *
*               print buffer.                               *
*           A3: Still the secondary address pointer for the *
*               print buffer.                               *
*Description: This subroutine loads the primary print buffer*
*             (A1) with its contents. It stops when it finds*
*             the MARKER indicating that its reached the end*
*             of the print buffer.                          *
************************************************************* 
LOAD_DECODED_BUFFER:
    MOVEM.L     D0-D7/A0/A2/A4-A6,-(SP)        * Save registers
LOAD_DECODED_BUFFER_LOOP:
    MOVE.B      (A3)+,D4
    CMPI.B      #MARKER,D4
    BEQ         LOAD_DECODED_BUFFER_DONE
    MOVE.B      D4,(A1)+
    BRA         LOAD_DECODED_BUFFER_LOOP
LOAD_DECODED_BUFFER_DONE:
    MOVEM.L (SP)+,D0-D7/A0/A2/A4-A6        * Restore registers
    RTS

*************************************************************
*               UI Utility - Output Symbols                 *
* Registers:                                                *
*           A1: Still holds the pointer for the             *
*               DECODE_BUFFER.                              *
*Description: This section adds symbols to the output buffer*
*             directly and prints them immediately.         *
************************************************************* 
OUTPUT_SLASH:
    MOVE.B      #'/',(A1)+
    JSR         PRINT_BUFFER
    RTS

OUTPUT_HEX_SYMBOL:
    MOVE.B      #'$',(A1)+
    JSR         PRINT_BUFFER
    RTS

OUTPUT_IMMEDIATE_SYMBOL:
    MOVE.B      #'#',(A1)+
    JSR         PRINT_BUFFER
    RTS

OUTPUT_OPEN_PAREN:
    MOVE.B      #'(',(A1)+
    JSR         PRINT_BUFFER
    RTS

OUTPUT_CLOSE_PAREN:
    MOVE.B      #')',(A1)+
    JSR         PRINT_BUFFER
    RTS

OUTPUT_COMMA:
    MOVE.B      #',',(A1)+
    JSR         PRINT_BUFFER
    RTS 

OUTPUT_PLUS:
    MOVE.B      #'+',(A1)+
    JSR         PRINT_BUFFER
    RTS

OUTPUT_MINUS:
    MOVE.B      #'-',(A1)+
    JSR         PRINT_BUFFER
    RTS  

OUTPUT_NEW_LINE:
    MOVE.W      #CRNL,(A1)+    
    JSR         PRINT_BUFFER
    RTS 

OUTPUT_TAB:
    MOVE.B      #TAB,(A1)+
    JSR         PRINT_BUFFER
    RTS

OUTPUT_SIZE_BYTE:
    MOVE.W      #'.B',(A1)+
    JSR         PRINT_BUFFER
    RTS

OUTPUT_SIZE_WORD:
    MOVE.W      #'.W',(A1)+
    JSR         PRINT_BUFFER
    RTS

OUTPUT_SIZE_LONG:
    MOVE.W      #'.L',(A1)+
    JSR         PRINT_BUFFER
    RTS

OUTPUT_CCR:
    MOVE.W      #'CC',(A1)+
    MOVE.B      #'R',(A1)+
    JSR         PRINT_BUFFER
    RTS

OUTPUT_SR:
    MOVE.W      #'SR',(A1)+
    JSR         PRINT_BUFFER
    RTS

*************************************************************
*       UI Utility - HEX Address to ASCII Conversion        *
* Registers:                                                *
*           D3: Used to manipulate values of register to    *
*               determine ASCII values.                     *
*           D4: Used to store value from D3 to get ASCII    *
*               value from the ASCII array.                 *
*           D5: Still holds address value coming in from    *
*               function that calls this subroutine.        *
*           D7: Used to hold counter value for the loop.    *
*           A1: Still holds the pointer for the             *
*               DECODE_BUFFER.                              *
*           A3: Used to hold the ASCII array.               *
************************************************************* 
ADDR_TO_ASCII_CHECK:
    ;Check the effective address size to determine proper ASCII size
    CMP.B   #0,EA_SIZE                      ; Check for byte
    BEQ     ADDR_TO_ASCII_BYTE
    CMP.B   #1,EA_SIZE                      ; Check for word
    BEQ     ADDR_TO_ASCII_WORD   
    CMP.B   #2,EA_SIZE                      ; Check for long
    BEQ     ADDR_TO_ASCII_LONG
    RTS                                     ; Otherwise, it's an invalid address and return

ADDR_TO_ASCII_BYTE:
    ;Determine byte address
    MOVEM.L D0-D4/D6/D7/A3,-(SP)            ; Stash registers so we don't overwrite
    MOVE.L  D5,D3                           ; Move address to D3 to manipulate
    ROR.L   #8,D3                           ; Move the printing area left
    MOVE.L  #2,D7                           ; Set the counter to 2 for number of bytes
    BRA     ADDR_TO_ASCII

ADDR_TO_ASCII_WORD:
    ;Determine word address
    MOVEM.L D0-D4/D6/D7/A3,-(SP)            ; Stash registers so we don't overwrite
    MOVE.L  D5,D3                           ; Move address to D3 to manipulate
    ROR.L   #8,D3                           ; Move the printing area left
    ROR.L   #8,D3                           ; Move the printing area left
    MOVE.L  #4,D7                           ; Set the counter to 4 for number of bytes
    BRA     ADDR_TO_ASCII

ADDR_TO_ASCII_LONG:
    ;Determine long address
    MOVEM.L D0-D4/D6/D7/A3,-(SP)            ; Stash registers so we don't overwrite
    MOVE.L  D5,D3                           ; Move address to D3 to manipulate
    MOVE.L  #8,D7                           ; Set the counter to 8 for number of bytes
    BRA     ADDR_TO_ASCII                   ; Begin loop to convert

ADDR_TO_ASCII:
    ;Prepare to loop
    JSR     RESET_BUFFER                    ; Reset/empty the buffer
    LEA     STRING_ASCII_ARRAY,A3           ; Load the ASCII array of characters into A3
    BRA     ADDR_TO_ASCII_LOOP              ; Begin the loop
ADDR_TO_ASCII_LOOP:
    ;Grab each nibble and translate to an ASCII char
    ROL.L   #4,D3                           ; Rotate over each byte, starting with the MSB 
    MOVE.B  D3,D4                           ; Transfer contents to D4
    ANDI.W  #LOW_ORDER_NIBBLE,D4            ; Grab the last nibble
    MOVE.B  (A3,D4.W),(A1)+                 ; Use the contents of the nibble as an index in the ASCII array, and load the element into the buffer
    SUBI.B  #1,D7                           ; Decrement: counter--;
    CMPI.B  #0,D7                           ; Check if the loop is finished
    BGT     ADDR_TO_ASCII_LOOP              ; If not, continue looping
    MOVEM.L (SP)+,D0-D4/D6/D7/A3            ; Otherwise, pop stack and return
    RTS

*************************************************************
*                      Op Code Decoder                      *
*************************************************************+
*************************************************************
*                  Op Code Decoder - Loop                   *
*Registers:                                                 *
*           A4: Holds the counter for the number of lines in*
*               in the current window.                      *
*           A5: Still holds the starting/current address.   *
*           A6: Still holds the ending address.             *
*************************************************************
DECODE:
    ;Initialize decode loop
    MOVE.L  #LINES_PER_WINDOW,A4    ; Set counter for lines per window to A4
DECODE_LOOP:
    ;Loop through decoding current instruction
    JSR     RESET_BUFFER            ; Reset the output buffer
    MOVE.L  A5,D5                   ; Move the current starting address to D5
    ;Convert Hex address to ASCII and output
    JSR     ADDR_TO_ASCII_LONG      ; Determine current address in ASCII
    JSR     PRINT_BUFFER            ; Output the current address to console
    JSR     OUTPUT_TAB              ; Insert a Tab between address of instruction & Op Code
    ;Extract and decode instructions and calculate addresses
    JSR     EXTRACT_WORD            ; Extract the next word from the address
    JSR     EXTRACT_INSTRUCTION     ; Extract instructions
    JSR     FIND_OP_CODE            ; Determine Op Code and calculate EA
    ;Finished decoding, create new line check if done
    JSR     OUTPUT_NEW_LINE         ; Output the line break
    CMPA.L  A6,A5                   ; end address < current address?
    BGT     DECODE_LOOP_DONE            ; If so, break loop and ask user if they want to continue
    SUBA.W  #1,A4                   ; Decrement the lines per window counter: i--;
    CMP.W   #0,A4                   ; counter > 0?
    BGT     DECODE_LOOP             ; If so, continue looping to fill the window
    ;Pause loop and have user confirm decoding
    MOVE.L  #LINES_PER_WINDOW,A4    ; If not, reset the counter and have user confirm continue
    BRA     DECODE_PAUSE

DECODE_LOOP_DONE:
    RTS

*************************************************************
*             Utility - Extract Word or Long                *
*Registers:                                                 *
*           D3: Used to hold and manipulate the address     *
*               contents of A5.                             *
*           A5: Still used to hold the current address.     *
*Description: This utility subroutine extracts the next     *
*               word or long value out of the instruction   *
*               and stores it into D3.                      *
************************************************************* 
EXTRACT_WORD:
    CLR.L   D3              ; Clear D3
    MOVE.B  (A5)+,D3        ; Copy current content in A5 (instruction) to D3, then move the pointer forward
    ROR.W   #8,D3           ; Rotate address by a byte
    MOVE.B  (A5)+,D3        ; Copy the next byte into D3
    RTS

EXTRACT_LONG:
    CLR.L   D3              ; Clear D3
    MOVE.B  (A5)+,D3        ; Copy current content in A5 into D3, then move the pointer forward
    ROR.W   #8,D3           ; Rotate address by a byte and repeat
    MOVE.B  (A5)+,D3
    SWAP    D3              ; Exchange the 16-bit words of D3
    MOVE.B  (A5)+,D3        
    ROR.W   #8,D3
    MOVE.B  (A5)+,D3
    RTS

*************************************************************
*     Op Code Decoder - Extract Instructions Using Masks    *
*Registers:                                                 *
*           D3: Still holds the word contents of instruction*
*           D4: Used to hold word contents of instruction   *
*               and manipulate for comparison.              *
*Description: This subroutine examines the contents of the  *
*             instruction and extracts it piecewise into    *
*             its appropriate area in memory for every      *
*             possible instruction.                         *
*************************************************************
EXTRACT_INSTRUCTION:
    ;Extract entire instruction
    MOVE.W  D3,OP_INSTR
    ;Extract first 4 bytes
    MOVE.L  D3,D4
    ANDI.W  #$F000,D4
    ROL.W   #4,D4
    MOVE.B  D4,FIRST_FOUR_BYTES
    ;Extract size for MOVE operations
    ANDI.W  #$0003,D4
    MOVE.B  D4,OP_MOVE_SIZE
    ;Extract mode
    MOVE.L  D3,D4
    ANDI.W  #$01C0,D4
    ROR.W   #6,D4
    MOVE.B  D4,OP_MOVE_MODE
    ;Extract register
    MOVE.L  D3,D4
    ANDI.W  #$0E00,D4
    ROL.W   #7,D4
    MOVE.B  D4,REG_ROTATE
    ;Extract size for ORI, etc...
    MOVE.L  D3,D4
    ANDI.W  #$00C0,D4
    ROR.W   #6,D4
    MOVE.B  D4,OP_ORI_SIZE
    ;Extract size for MOVEM
    ANDI.B  #1,D4
    MOVE.B  D4,OP_MOVEM_SIZE
    ;Extract EA mode
    MOVE.L  D3,D4
    ANDI.W  #$0038,D4
    ROR.W   #3,D4
    MOVE.B  D4,EA_MODE_LAST_SIX
    ;Extract for condition codes
    MOVE.L  D3,D4
    ANDI.W  #$0F00,D4
    ROL.W   #8,D4
    MOVE.B  D4,OP_COND_CODE
    ;Extract Size/Direction
    MOVE.L  D3,D4
    ANDI.W  #$0100,D4
    ROL.W   #8,D4
    MOVE.B  D4,OP_SIZE_DIR
    ;Extract Displacement/Data
    MOVE.L  D3,D4
    ANDI.W  #$00FF,D4
    MOVE.B  D4,OP_DISPLACE_DATA
    ;Extract register and mode
    ANDI.W  #$003F,D4
    MOVE.B  D4,EA_MODE_REG
    ;Extract register
    ANDI.W  #$0007,D4
    MOVE.B  D4,EA_REG_LAST_SIX
    ;Extract direction for MOVEM
    MOVE.L  D3,D4
    ANDI.W  #$0400,D4
    ROL.W   #6,D4
    MOVE.B  D4,OP_MOVEM_DIR

    RTS

*************************************************************
*        Op Code Decoder - Find Op Code Using Masks         *
*Registers:                                                 *
*           D1: Holds the flag for the ERROR_HANDLER table. *
*           D3: Still holds the word contents of instruction*
*           D4: Used to hold word contents of instruction   *
*               and manipulate for comparison.              *
*           A3: Used to receive the string for the Op Code  *
*               being sent to the PRINT_BUFFER for output.  *
*Description: This subroutine tries to determine the Op     *
*               Code using masks by isolating bits, then    *
*               sending it off to the corresponding Op Code *
*               subroutine. We check every possible Op Code *
*               and if it is not supported or not required  *
*               as part of the submission, it is sent to the*
*               OP_UNSUPPORTED subroutine.                  *
*************************************************************
FIND_OP_CODE:
    ;ORI to CCR? (0 0 0 0 0 0 0 0 0 0 1 1 1 1 0 0)
    MOVE.W  D3,D4
    CMPI.L	#OP_ORI_TO_CCR,D4
    BNE     CHECK_OP_SET_1
    JMP     IS_ORI_TO_CCR

CHECK_OP_SET_1:
    ;ORI to CCR - RTR? (0 0 0 0 0 0 0 0 0 1 1 1 1 1 0 0 - 0 1 0 0 1 1 1 0 0 1 1 1 0 1 1 1)
    MOVE.L  D3,D4
    CMPI.L	#OP_ORI_TO_SR,D4
    BEQ     IS_ORI_TO_SR
    CMPI.L	#OP_ANDI_TO_CCR,D4
    BEQ     IS_ANDI_TO_CCR
    CMPI.L  #OP_ANDI_TO_SR,D4
    BEQ     IS_ANDI_TO_SR
    CMPI.L	#OP_EORI_TO_CCR,D4
    BEQ     IS_EORI_TO_CCR
    CMPI.L	#OP_EORI_TO_SR,D4
    BEQ     IS_EORI_TO_SR
    CMPI.L  #OP_ILLEGAL,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L  #OP_RESET,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L	#OP_NOP,D4
    BEQ     IS_NOP
    CMPI.L	#OP_STOP,D4
    BEQ     IS_STOP
    CMPI.L	#OP_RTE,D4
    BEQ     IS_RTE
    CMPI.L	#OP_RTS,D4
    BEQ     IS_RTS
    CMPI    #OP_RTR,D4
    BNE     CHECK_OP_SET_2
    JMP     OP_UNSUPPORTED

CHECK_OP_SET_2:
    ;BTST - ROL[memory rotate]? (0 0 0 0 X X X 1 0 0 X X X X X X - 1 1 1 0 0 1 1 X 1 1 X X X X X X)
    MOVE.W  D3,D4
    ANDI.L  #NIBBLE1,D4
    CMPI.L  #OP_BTST,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L  #OP_BCHG,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L  #OP_BCLR,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L	#OP_BSET,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L	#OP_MOVE_FROM_SR,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L	#OP_MOVE_TO_CCR,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L	#OP_NBCD,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L	#OP_PEA,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L	#OP_TAS,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L	#OP_JSR,D4
    BEQ     IS_JSR
    CMPI.L	#OP_JMP,D4
	BEQ		IS_JMP
    CMPI.L	#OP_ASR_MEM,D4
    BEQ     IS_ASR_MEM
    CMPI.L	#OP_ASL_MEM,D4
	BEQ		IS_ASL_MEM
    CMPI.L	#OP_LSR_MEM,D4
    BEQ     IS_LSR_MEM
    CMPI.L	#OP_LSL_MEM,D4
    BEQ     IS_LSL_MEM
    CMPI.L	#OP_ROXR_MEM,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L	#OP_ROXL_MEM,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L	#OP_ROR_MEM,D4
	BEQ	    IS_ROR_MEM
    CMPI.L	#OP_ROL_MEM,D4
    BNE     CHECK_MOVEM
    JMP     IS_ROL_MEM

CHECK_MOVEM:
    ;MOVEM? (0 1 0 0 1 X 0 0 1 X X X X X X X)
    MOVE.L  D3,D4
    ANDI.L	#NIBBLE2,D4
    CMPI.L	#OP_MOVEM_D0,D4
    BEQ     IS_MOVEM_D0
    CMPI.L	#OP_MOVEM_D1,D4
    BNE     CHECK_OP_SET_3
	JMP		IS_MOVEM_D1

CHECK_OP_SET_3:
    ;ORI - TST? (0 0 0 0 0 0 0 0 X X X X X X X X - 0 1 0 0 1 0 1 0 X X X X X X X X)
    MOVE.L  D3,D4
    ANDI.L	#NIBBLE3,D4
    CMPI.L	#OP_MOVE_ORI_DATA,D4
    BEQ     IS_ORI_0000
    CMPI.L	#OP_ANDI,D4
    BEQ     IS_ANDI
    CMPI.L	#OP_SUBI,D4
    BEQ     IS_SUBI
    CMPI.L	#OP_ADDI,D4
    BEQ     IS_ADDI
    CMPI.L	#OP_EORI,D4
    BEQ     IS_EORI
    CMPI.L	#OP_CMPI,D4
    BEQ     IS_CMPI
    CMPI.L	#OP_NEGX,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L	#OP_CLR,D4
    BEQ     IS_CLR
    CMPI.L	#OP_NEG,D4
    BEQ     OP_UNSUPPORTED
    CMPI.L	#OP_NOT,D4
    BEQ     IS_NOT
    CMPI.L	#OP_TST,D4
    BNE     CHECK_OP_SET_4
    JMP     OP_UNSUPPORTED

CHECK_OP_SET_4:
    ;LEA - MULS? (0 1 0 0 X X X 1 1 1 X X X X X X - 0 1 0 0 1 1 0 0 0 0 X X X X X X)
    MOVE.L  D3,D4
    ANDI.L	#NIBBLE4,D4
    CMPI.L	#OP_LEA,D4
    BEQ     IS_LEA
    CMPI.L	#OP_DIVU,D4
    BEQ     IS_DIVU_W
    CMPI.L	#OP_DIVS,D4
    BEQ     IS_DIVS_W
    CMPI.L	#OP_MULU,D4
    BEQ     IS_MULU_W
    CMPI.L	#OP_MULS,D4
    BNE     CHECK_OP_SET_5
	JMP		IS_MULS_W

CHECK_OP_SET_5:
    ;ASR[Register] - ROL[Register]? (1 1 1 0 X X X X X X X 0 0 X X X - 1 1 1 0 X X X X X X X 1 1 X X X)
    MOVE.L  D3,D4
	ANDI.L	#NIBBLE5,D4
    CMPI.L  #OP_ADDQ,D4
    BEQ     IS_ADDQ
	CMPI.L	#OP_ASR_REG,D4
	BEQ		IS_ASR_REG
	CMPI.L	#OP_LSR_REG,D4
	BEQ		IS_LSR_REG
	CMPI.L	#OP_ROXR_REG,D4
	BEQ		OP_UNSUPPORTED
	CMPI.L	#OP_ROR_REG,D4
	BEQ		IS_ROR_REG
	CMPI.L	#OP_ASL_REG,D4
	BEQ		IS_ASL_REG
	CMPI.L	#OP_LSL_REG,D4
	BEQ		IS_LSL_REG
	CMPI.L	#OP_ROXL_REG,D4
	BEQ		OP_UNSUPPORTED
	CMPI.L	#OP_ROL_REG,D4
    BNE     CHECK_OP_SET_6
	JMP		IS_ROL_REG

CHECK_OP_SET_6:
    ;SUBA - ADDA? (1 0 0 1 X X X X X X X X X X X X - 1 1 0 1 X X X X X X X X X X X X)
	MOVE.L	D3,D4
	ANDI.L	#NIBBLE6,D4
	CMPI.L	#OP_SUBA,D4
	BEQ		IS_SUBA
	CMPI.L	#OP_CMPA,D4
	BEQ		IS_CMPA
	CMPI.L	#OP_ADDA,D4
    BNE     CHECK_OP_SET_7
	JMP		IS_ADDA

CHECK_OP_SET_7:
    ;BRA - ADD? (0 1 1 0 0 0 0 0 X X X X X X X X - 1 1 0 1 X X X X X X X X X X X X)
	MOVE.L	D3,D4
	ANDI.L	#NIBBLE7,D4
	CMPI.L	#OP_BRANCH,D4
	BEQ		IS_BRA
	CMPI.L	#OP_OR,D4
	BEQ		IS_OR
	CMPI.L	#OP_SUB,D4
	BEQ		IS_SUB
	CMPI.L	#OP_AND,D4
	BEQ		IS_AND
	CMPI.L	#OP_ADD,D4
    BNE		CHECK_OP_SET_8
	JMP		IS_ADD

CHECK_OP_SET_8:
    ;MOVEA? (0 0 X X X X X 0 0 1 X X X X X X)
	MOVE.L	D3,D4
	ANDI.L	#$c1c0,D4
	CMPI.L	#OP_MOVEA,D4
	BNE		NOT_MOVEA
	JMP		IS_MOVEA

NOT_MOVEA:
    ;MOVEQ? (0 1 1 1 X X X 0 X X X X X X X X)
	MOVE.L	D3,D4
	ANDI.L	#$f100,D4
	CMPI.L	#OP_MOVEQ,D4
	BNE		NOT_MOVEQ
	JMP		IS_MOVEQ

NOT_MOVEQ:
    ;CMP? (1 0 1 1 X X X X X X X X X X X X)
	MOVE.L	D3,D4
	ANDI.L	#$f100,D4
	CMPI.L	#OP_CMP,D4
	BNE		NOT_CMP
	JMP		IS_CMP

NOT_CMP:
    ;EOR? (1 0 1 1 X X X X X X X X X X X X)
	MOVE.L	D3,D4
	ANDI.L	#$f100,D4
	CMPI.L	#OP_EOR,D4
	BNE		NOT_ADD
	JMP		IS_EOR

NOT_ADD:
    ;MOVE? (0 0 X X X X X X X X X X X X X X)
	MOVE.L	D3,D4
	ANDI.L	#$c000,D4
	CMPI.L	#OP_MOVE_ORI_DATA,D4
	BNE		NOT_MOVE_0000
	JMP		IS_MOVE_0000

NOT_MOVE_0000:
    ;DATA?
	MOVE.L	D3,D4
	ANDI.L	#$0000,D4
	CMPI.L	#OP_MOVE_ORI_DATA,D4
	BNE		NOT_DATA
	JMP		IS_DATA

NOT_DATA:
    ;Otherwise, it's unsupported
	JMP	    OP_UNSUPPORTED

*************************************************************
*             Op Code Decoder - Print Op Code               *
*Registers:                                                 *
*           D4: Used to hold the value from the             *
*               EXTRACT_INSTRUCTION subroutine, and as the  *
*               index to locate the correct chars from      *
*               BCC_CHAR_ARRAY.
*           A3: Used to receive the string for the Op Code  *
*               being sent to the PRINT_BUFFER for output,  *
*               or hold the BCC_CHAR_ARRAY.                 *
*Description: This section takes the confirmed Op Code,     *
*             prints it and sends to the correct routine    *
*             for calculating the EA's and size where needed*
************************************************************* 
IS_ORI_TO_CCR:
	LEA		OP_STRING_ORI,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ORI_CCR_PATTERN

IS_ORI_TO_SR:
	LEA		OP_STRING_ORI,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ORI_SR_PATTERN

IS_ANDI_TO_SR:
	LEA		OP_STRING_ANDI,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ORI_SR_PATTERN

IS_ANDI_TO_CCR:
	LEA		OP_STRING_ANDI,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ORI_CCR_PATTERN

IS_EORI_TO_CCR:
	LEA		OP_STRING_EORI,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ORI_CCR_PATTERN

IS_EORI_TO_SR:
	LEA		OP_STRING_EORI,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ORI_SR_PATTERN

IS_NOP:
	LEA		OP_STRING_NOP,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	RTS

IS_STOP:
	LEA		OP_STRING_STOP,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_STOP_PATTERN

IS_RTE:
	LEA		OP_STRING_RTE,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	RTS

IS_RTS:
	LEA		OP_STRING_RTS,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	RTS

IS_JSR:
	LEA		OP_STRING_JSR,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_JSR_PATTERN

IS_JMP:
	LEA		OP_STRING_JMP,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_JSR_PATTERN

IS_ASR_MEM:
	LEA		OP_STRING_ASR,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_JSR_PATTERN

IS_ASL_MEM:
	LEA		OP_STRING_ASL,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_JSR_PATTERN

IS_LSR_MEM:
	LEA		OP_STRING_LSR,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_JSR_PATTERN

IS_LSL_MEM:
	LEA		OP_STRING_LSL,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_JSR_PATTERN

IS_ROR_MEM:
	LEA		OP_STRING_ROR,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_JSR_PATTERN

IS_ROL_MEM:
	LEA		OP_STRING_ROL,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_JSR_PATTERN

IS_MOVEM_D0:
	LEA		OP_STRING_MOVEM,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_MOVEM_PATTERN

IS_MOVEM_D1:
	LEA		OP_STRING_MOVEM,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_MOVEM_PATTERN

IS_ORI_0000:
	LEA		OP_STRING_ORI,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ORI_PATTERN

IS_ANDI:
	LEA		OP_STRING_ANDI,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ORI_PATTERN

IS_SUBI:
	LEA		OP_STRING_SUBI,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ORI_PATTERN

IS_ADDI:
	LEA		OP_STRING_ADDI,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ORI_PATTERN

IS_EORI:
	LEA		OP_STRING_EORI,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ORI_PATTERN

IS_CMPI:
	LEA		OP_STRING_CMPI,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ORI_PATTERN

IS_CLR:
	LEA		OP_STRING_CLR,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_CLR_PATTERN

IS_NOT:
	LEA		OP_STRING_NOT,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_CLR_PATTERN

IS_LEA:
	LEA		OP_STRING_LEA,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_LEA_PATTERN

IS_DIVU_W:
	LEA		OP_STRING_DIVU,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_DIVS_PATTERN

IS_DIVS_W:
	LEA		OP_STRING_DIVS,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_DIVS_PATTERN

IS_MULU_W:
	LEA		OP_STRING_MULU,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_DIVS_PATTERN

IS_MULS_W:
	LEA		OP_STRING_MULS,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_DIVS_PATTERN

IS_ADDQ:
    LEA     OP_STRING_ADDQ,A3
    JSR     LOAD_DECODED_BUFFER
    JSR     PRINT_BUFFER
    JMP     EA_CLR_PATTERN

IS_ASR_REG:
	LEA		OP_STRING_ASR,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ROTATION_PATTERN_TYPE

IS_LSR_REG:
	LEA		OP_STRING_LSR,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ROTATION_PATTERN_TYPE

IS_ROR_REG:
	LEA		OP_STRING_ROR,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ROTATION_PATTERN_TYPE

IS_ASL_REG:
	LEA		OP_STRING_ASL,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ROTATION_PATTERN_TYPE

IS_LSL_REG:
	LEA		OP_STRING_LSL,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ROTATION_PATTERN_TYPE

IS_ROL_REG:
	LEA		OP_STRING_ROL,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_ROTATION_PATTERN_TYPE

IS_SUBA:
	LEA		OP_STRING_SUBA,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_CMPA_PATTERN

IS_CMPA:
	LEA		OP_STRING_CMPA,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_CMPA_PATTERN

IS_ADDA:
	LEA		OP_STRING_ADDA,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_CMPA_PATTERN

IS_BRA:
	LEA		OP_STRING_B,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	LEA	    STRING_BCC_ARRAY,A3
	CLR.L	D4
	MOVE.B	OP_COND_CODE,D4             ; Copy the condition code to D4 for manipulation
	LSL.W	#1,D4 	                    ; Shift/Multiply by 2 because it's 2 bytes per array index 
	JSR		RESET_BUFFER                ; Clear the buffer before going into subroutine
	MOVE.W	(A3,D4.W),(A1)+	            ; Move the chars from the BCC array into A1 for printing
	JMP		EA_CALC_DISPLACE_TABLE

IS_OR:
	LEA		OP_STRING_OR,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_AND_PATTERN

IS_SUB:
	LEA		OP_STRING_SUB,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_AND_PATTERN

IS_AND:
	LEA		OP_STRING_AND,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_AND_PATTERN

IS_ADD:
	LEA		OP_STRING_ADD,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_AND_PATTERN

IS_MOVEA:
	LEA		OP_STRING_MOVEA,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_MOVE_PATTERN

IS_MOVEQ:
	LEA		OP_STRING_MOVEQ,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_MOVEQ_PATTERN

IS_CMP:
	LEA		OP_STRING_CMP,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_CMP_PATTERN

IS_EOR:
	LEA		OP_STRING_EOR,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_CMP_PATTERN

IS_MOVE_0000:
	LEA		OP_STRING_MOVE,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_MOVE_PATTERN

IS_DATA:
	LEA		OP_STRING_INVALID,A3
	JSR		LOAD_DECODED_BUFFER
	JSR		PRINT_BUFFER
	JMP		EA_DATA_PATTERN

OP_UNSUPPORTED:
    MOVE.L  #0,D1
    JSR     ERROR_HANDLER

*************************************************************
*                Effective Address Calculator               *
*************************************************************
*************************************************************
*          EA Calculator - Using Instruction Pattern        *
*Registers:                                                 *
*           D3: Still used to hold the contents extracted   *
*               from EXTRACT_WORD or EXTRACT_LONG routines. *
*           D5: Still used to convert the address from D3   *
*               to ASCII.                                   *
*Description: This section either outputs the address of the*
*             known operation, or uses a pattern that some  *
*             Ops have in common. Also determines the size  *
*             and mode of specific Op Codes for output.     *
*             It pulls data from the memory where we        *
*             extracted the instructions initially.         *
*************************************************************
EA_DATA_PATTERN:
    ;For DATA output
    JSR     OUTPUT_TAB
    JSR     OUTPUT_HEX_SYMBOL
    MOVE.W  D3,D5
    JSR     ADDR_TO_ASCII_WORD
    JSR     PRINT_BUFFER
    RTS

EA_STOP_PATTERN:
    ;For STOP output
    JSR     OUTPUT_TAB
    JSR     OUTPUT_IMMEDIATE_SYMBOL
    JSR     OUTPUT_HEX_SYMBOL
    JSR     EXTRACT_WORD
    MOVE.W  D3,D5
    JSR     ADDR_TO_ASCII_WORD
    JSR     PRINT_BUFFER
    RTS

EA_LEA_PATTERN:
    ;For LEA output
    JSR     OUTPUT_TAB
    JSR     EA_LOAD_LAST_SIX
    JSR     EA_MODE_TABLE
    JSR     OUTPUT_COMMA
    MOVE.B  REG_ROTATE,EA_REG
    JSR     EA_LOAD_AN
    RTS

EA_CMP_PATTERN:
    ;For CMP & EOR
    MOVE.B  OP_ORI_SIZE,EA_SIZE
    JSR     EA_OUTPUT_SIZE_TABLE
    JSR     EA_LOAD_LAST_SIX
    JSR     EA_MODE_TABLE
    JSR     OUTPUT_COMMA
    MOVE.B  REG_ROTATE,EA_REG
    JSR     EA_LOAD_DN
    RTS

EA_CMPA_PATTERN:
    ;For CMPA, SUBA, ADDA
    MOVE.B  OP_SIZE_DIR,D4
    ADDI.B  #1,D4
    MOVE.B  D4,EA_SIZE
    JSR     EA_OUTPUT_SIZE_TABLE
    JSR     EA_LOAD_LAST_SIX
    JSR     EA_MODE_TABLE
    JSR     OUTPUT_COMMA
    MOVE.B  REG_ROTATE,EA_REG
    JSR     EA_LOAD_AN
    RTS

EA_CLR_PATTERN:
    ;For CLR, NOT, ADDQ
    JSR     EA_LOAD_LAST_SIX
    MOVE.B  OP_ORI_SIZE,EA_SIZE
    JSR     EA_OUTPUT_SIZE_TABLE
    JSR     EA_MODE_TABLE
    RTS

EA_DIVS_PATTERN:
    ;For DIVS, DIVU, MULS, MULU
    MOVE.B  #1,EA_SIZE                 ; EA Size = Word
    JSR     EA_OUTPUT_SIZE_TABLE
    JSR     EA_LOAD_LAST_SIX
    JSR     EA_MODE_TABLE
    JSR     OUTPUT_COMMA
    MOVE.B  REG_ROTATE,EA_REG
    JSR     EA_LOAD_DN
    RTS

EA_ORI_SR_PATTERN:
    ;For ORI to SR, ANDI to SR, EORI to SR
    MOVE.B  #1,EA_SIZE                 ; EA Size = Word
    JSR     EA_OUTPUT_SIZE_TABLE
    JSR     EA_MODE_111_REG_100
    JSR     OUTPUT_COMMA
    JSR     OUTPUT_SR
    RTS

EA_ORI_CCR_PATTERN:
    ;For ORI to CCR, ANDI to CCR, EORI to CCR
    MOVE.B  #0,EA_SIZE                 ; EA Size = Byte
    JSR     EA_OUTPUT_SIZE_TABLE
    JSR     EA_MODE_111_REG_100        ; EA Mode Type = Immediate
    JSR     OUTPUT_COMMA
    JSR     OUTPUT_CCR
    RTS

EA_ORI_PATTERN:
    ;For ORI, ANDI, SUBI, ADDI, EORI, CMPI
    MOVE.B  OP_ORI_SIZE,EA_SIZE
    JSR     EA_OUTPUT_SIZE_TABLE
    JSR     EA_MODE_111_REG_100
    JSR     OUTPUT_COMMA
    JSR     EA_LOAD_LAST_SIX
    JSR     EA_MODE_TABLE
    RTS

EA_MOVE_PATTERN:
    ;For MOVEA and MOVE
    MOVE.B  OP_MOVE_SIZE,EA_SIZE
    JSR     EA_MOVE_SIZE_TYPE
    JSR     EA_OUTPUT_SIZE_TABLE
    JSR     EA_LOAD_LAST_SIX
    JSR     EA_MODE_TABLE
    JSR     OUTPUT_COMMA
    CLR.L   D3
    MOVE.W  OP_INSTR,D3
    MOVE.B  REG_ROTATE,EA_REG
    MOVE.B  OP_MOVE_MODE,EA_MODE
    JSR     EA_MODE_TABLE
    RTS

EA_MOVEQ_PATTERN:
    ;For MOVEQ
    MOVE.B  #2,EA_SIZE                  ; EA Size = Long
    JSR     EA_OUTPUT_SIZE_TABLE
    JSR     OUTPUT_IMMEDIATE_SYMBOL
    JSR     OUTPUT_HEX_SYMBOL
    MOVE.B  OP_DISPLACE_DATA,D5
    JSR     ADDR_TO_ASCII_BYTE
    JSR     PRINT_BUFFER
    JSR     OUTPUT_COMMA
    MOVE.B  REG_ROTATE,EA_REG
    JSR     EA_LOAD_DN
    RTS

EA_JSR_PATTERN:
    ;For JSR, JMP, ASL[mem], ASR[mem], LSL[mem], LSR[mem], ROR[mem], ROL[mem]
    JSR     OUTPUT_TAB
    JSR     EA_LOAD_LAST_SIX  
    MOVE.B  #3,EA_SIZE            
    JSR     EA_MODE_TABLE
    RTS

EA_AND_PATTERN:
    ;For OR, AND, SUB, ADD
    MOVE.B  OP_ORI_SIZE,EA_SIZE
    JSR     EA_OUTPUT_SIZE_TABLE
    MOVE.B  OP_SIZE_DIR,D4
    CMP.B   #1,D4
    BEQ     EA_AND_EA_PATTERN

EA_AND_DN_PATTERN:  
    ;Pattern for operations that move an EA to a DN
    JSR     EA_LOAD_LAST_SIX
    JSR     EA_MODE_TABLE
    JSR     OUTPUT_COMMA
    MOVE.B  REG_ROTATE,EA_REG
    JSR     EA_LOAD_DN
    RTS

EA_AND_EA_PATTERN:   
    ;Pattern for operations that move a DN to an EA
    MOVE.B  REG_ROTATE,EA_REG
    JSR     EA_LOAD_DN
    JSR     OUTPUT_COMMA
    JSR     EA_LOAD_LAST_SIX
    JSR     EA_MODE_TABLE
    RTS

EA_MOVE_SIZE_TYPE:
    ;Helper function to determine MOVE size
    MOVE.B  EA_SIZE,D4
    CMP.B   #1,D4
    BEQ     EA_MOVE_SIZE_BYTE
    CMP.B   #3,D4
    BEQ     EA_MOVE_SIZE_WORD
    CMP.B   #2,D4
    BEQ     EA_MOVE_SIZE_LONG

EA_MOVE_SIZE_BYTE: 
    MOVE.B  #0,EA_SIZE 
    RTS
EA_MOVE_SIZE_WORD: 
    MOVE.B  #1,EA_SIZE
    RTS
EA_MOVE_SIZE_LONG: 
    MOVE.B  #2,EA_SIZE
    RTS

EA_LOAD_LAST_SIX:
    ;Utility funciton to isolate last 6 bits of mode and register loaded from D4
    MOVE.B  EA_MODE_LAST_SIX,EA_MODE            ; Loads Mode and Last 6 bits to EA_MODE
    MOVE.B  EA_REG_LAST_SIX,EA_REG              ; Loads Register and last 6 bits to EA_REG
    RTS

*************************************************************
*              EA Calculator - MOVEM Pattern                *
*Registers:                                                 *
*           D3: Still used to hold the contents extracted   *
*               from EXTRACT_WORD or EXTRACT_LONG routines. *
*           D4: Used to store number of data registers      *
*           D5: Still used to convert the address from D3   *
*               to ASCII.                                   *
*           D6: Used to hold number of overflow/carry flag  *
*               sets                                        *
*           D7: Used as loop counter                        *
*           A4: USed to store array of registers            *
*Description:                                               *
*           This section handles the addressing and output  *
*           of MOVEM operations. It determines the address  *
*           type (Dn/An), total size, and pattern. It calls *
*           ADDR_TO_ASCII_REVERSE to print the registers    *
*************************************************************

EA_MOVEM_PATTERN:
    ;For MOVEM
    MOVEM.L D4/A4/D7/D3/D5/D6,-(SP)             ; Save registers into stack
    MOVE.B  OP_MOVEM_SIZE,D4                    ; Evaluate size
    ADDI.B  #1,D4
    MOVE.B  D4,EA_SIZE                          ; Push into EA_SIZE memory
    JSR     EA_OUTPUT_SIZE_TABLE                ; Print the size
    JSR     EA_LOAD_LAST_SIX                    ; Get the mode and reg of the EA
    JSR     EXTRACT_WORD                        ; Extract it
    LEA     STRING_REGISTER_ARRAY,A4            ; Load reg string array
    CMPI.B  #1,OP_MOVEM_DIR                     ; Determine if it's D1 or D0
    BEQ     EA_MOVEM_D1_PATTERN
    BRA     EA_MOVEM_D0_PATTERN

EA_MOVEM_D0_PATTERN:
    ;For MOVEM to D0 or stack pop -(SP)
    JSR     EA_MOVEM_COUNT_REGS                 ; Count number of registers to print
    MOVE.L  D3,D5
    JSR     ADDR_TO_ASCII_REVERSE               ; Reverse the register and rotate bits right
    ROR.L   #8,D5
    ROR.L   #8,D5
    MOVE.L  D5,D3
    JSR     EA_MOVEM_REGS_PATTERN               ; Print the registers
    JSR     OUTPUT_COMMA                        ; Separate operand with comma
    JSR     EA_MODE_TABLE                       ; Determine EA mode
    MOVEM.L (SP)+,D4/A4/D7/D3/D5/D6             ; Pop registers from stack
    RTS

EA_MOVEM_D1_PATTERN:
    ;For MOVEM to D1 or stack push (SP)+
    JSR     EA_MODE_TABLE                       ; Check EA Mode Type
    JSR     OUTPUT_COMMA
    JSR     EA_MOVEM_COUNT_REGS                 ; Counts number of Registers
    JSR     EA_MOVEM_REGS_PATTERN               ; Jump to loop to load registers
    MOVEM.L (SP)+,D4/A4/D7/D3/D5/D6             ; Pop registers from stack
    RTS

EA_MOVEM_REGS_PATTERN:
    MOVE.W  #15,D7                              ; Loop counter set to 16 bits
    MOVE.W  D3,D4                               ; Loads mask from D3 to D4 
EA_MOVEM_REGS_LOOP_PATTERN:
    ;Start of Loop
    BTST    #0,D4                               ; Check if LSB = 0
    BEQ     EA_MOVEM_REGS_LOOP_GO_PATTERN       ; If so move to check if its the end
    MOVE.W  D7,D5                               ; Temporarily store counter in D5
    LSL.W   #1,D5                               ; Calculate Array Index
    MOVE.W  (A4,D5.W),(A1)+                     ; Retrieve array index, move to stack
    JSR     PRINT_BUFFER
    CMPI.W  #1,D6                               ; Check if number of carry flags = 1
    DBEQ    D6,EA_MOVEM_REGS_ADD_SLASH_PATTERN  ; If end jump to print slash
    BRA     EA_MOVEM_REGS_LOOP_GO_PATTERN       ; if not branch to continue
EA_MOVEM_REGS_ADD_SLASH_PATTERN:
    JSR     OUTPUT_SLASH                        ; Print '/' in between register types 
EA_MOVEM_REGS_LOOP_GO_PATTERN:
    ;End of loop
    ROR.W   #1,D4                               ; Rotate through data register 
    CMPI.W  #0,D7                               ; Check if counter is 0
    DBEQ    D7,EA_MOVEM_REGS_LOOP_PATTERN       ; If not equal to 0, decrease and continue
    RTS
   
EA_MOVEM_COUNT_REGS:  
    MOVE.W  D3,D4                               ; Loads mask from D3 to D4 
    MOVE.W  #15,D7                              ; Loop counter set to 16 bits
    MOVE.W  #0,D6                               ; Counts number of carry/overflow flags
EA_MOVEM_COUNT_REGS_LOOP:
    BTST    #0,D4                               ; Check if LSB = 0
    BEQ     EA_MOVEM_COUNT_REGS_LOOP_GO         ; If so move to check if its the end
    ADDI.W  #1,D6                               ; If not increment D6
EA_MOVEM_COUNT_REGS_LOOP_GO:
    ROR.W   #1,D4                               ; Rotate through data register 
    CMPI.W  #0,D7                               ; Check if counter is 0
    DBEQ    D7,EA_MOVEM_COUNT_REGS_LOOP         ; If not equal to 0, decrease and continue
    RTS

*************************************************************
*      EA Calculator - ROR/ROL/ASL/ASR/LSL/LSR Patterns     *
*Registers:                                                 *
*          D3: Still used to hold the contents extracted    *
*               from EXTRACT_WORD or EXTRACT_LONG routines. *
*          D4: Used to store instructions to be manipulated *
*               by rotation                                 *
*          D5: Still used to convert the address from D3    *
*               to ASCII.                                   *
*Description:  This section handles the rotation patterns   *
*              of Rotates or Shifts by predetermined        *
*              parsed code in D4                            *
*************************************************************

EA_ROTATION_PATTERN_TYPE:
    ;For first half of Rotation/Shift
    MOVE.B  OP_ORI_SIZE,EA_SIZE                 ; Isolate last two bits for size
    JSR     EA_OUTPUT_SIZE_TABLE                ; Determine size 
    MOVE.L  D3,D4
    LSR.W   #5,D4              
    ANDI.W  #1,D4                               ; Isolate Mode bit
    CMPI.W  #0,D4                               ; if Mode = 0
    BEQ     MEM_ROTATION_PATTERN                ; Branch to Memory shfit instructions
    ;Register Shift
    MOVE.B  REG_ROTATE,EA_REG                   ; Load number of rotations to EA
    JSR     EA_LOAD_DN                          ; Move to Data register print function
    BRA     ROTATION_END 
MEM_ROTATION_PATTERN: 
    ;Memory/Immediate Data shift                               
    JSR     OUTPUT_IMMEDIATE_SYMBOL
    MOVE.B  REG_ROTATE,D5                       ; Load number of rotations to Data Register
    JSR     ADDR_TO_ASCII_BYTE                  ; Jump to determine byte address
	JSR		PRINT_BUFFER
    BRA     ROTATION_END
ROTATION_END: 
    ;For second half of Rotation/Shift                                 
    JSR     OUTPUT_COMMA           
    MOVE.B  EA_REG_LAST_SIX,EA_REG              ; Jump to get last 6 bits of information
    JSR     EA_LOAD_DN                          ; Move to Data register print function
    RTS

*************************************************************
*         EA Caclulator Utillity - Data/Address Arrays      *
*Registers:                                                 *
*         D4: Holds Effective Address Register              *
*         A3: Holds array for Data or Address Registers     *
*Description:                                               *
*         This function moves thorugh the specified array   *
*         type isolating the required index then loading it *
*         to A1                                             *
************************************************************* 

EA_LOAD_DN:
    MOVEM.L     D0-D7/A0/A2-A6,-(SP)            ; Save registers
    CLR         D4                              ; Clear D4
    MOVE.B      EA_REG,D4                       ; Load Effective Address Register to D4
    LSL.W       #1,D4                           ; Rotate to desired array index
    LEA         STRING_DREGISTER_ARRAY,A3       ; Load Data Register Array to A3 
    MOVE.W      (A3,D4.W),(A1)+                 ; Retrieve item from array index, increment stack
    JSR         PRINT_BUFFER   
    MOVEM.L     (SP)+,D0-D7/A0/A2-A6            ; Restore registers
    RTS    

EA_LOAD_AN:
    MOVEM.L     D0-D7/A0/A2-A6,-(SP)            ; Save registers
    CLR         D4                              ; Clear D4
    MOVE.B      EA_REG,D4                       ; Load Effective Address Register to D4
    LSL.W       #1,D4                           ; Rotate to desired array index
    LEA         STRING_AREGISTER_ARRAY,A3       ; Load Data Register Array to A3
    MOVE.W      (A3,D4.W),(A1)+                 ; Retrieve item from array index, increment stack
    JSR         PRINT_BUFFER  
    MOVEM.L     (SP)+,D0-D7/A0/A2-A6            ; Restore registers
    RTS    


*************************************************************
*           EA Calculator - Find Mode/Size/Type             *
*Registers:                                                 *
*           D3: Still used to hold the contents extracted   *
*               from EXTRACT_WORD or EXTRACT_LONG routines. *
*           D5: Still used to convert the address from D3   *
*               to ASCII.                                   *
*Description: This section determines the mode or size and  *
*             type of the effective address in the Op Code, *
*             then outputs it to the window.                *
*************************************************************
EA_MODE_TABLE:
    CMPI.B  #0,EA_MODE
    BEQ     EA_MODE_000
    CMPI.B  #1,EA_MODE
    BEQ     EA_MODE_001
    CMPI.B  #2,EA_MODE
    BEQ     EA_MODE_010
    CMPI.B  #3,EA_MODE
    BEQ     EA_MODE_011
    CMPI.B  #4,EA_MODE
    BEQ     EA_MODE_100
    CMPI.B  #5,EA_MODE
    BEQ     EA_MODE_111
    CMPI.B  #6,EA_MODE
    BEQ     EA_MODE_111
    CMPI.B  #7,EA_MODE
    BEQ     EA_MODE_111

EA_MODE_000:
    ;For data registers
    JSR     EA_LOAD_DN    
    RTS

EA_MODE_001:
    ;For address registers
    JSR     EA_LOAD_AN
    RTS

EA_MODE_010:
    ;For Direct Addressing (A)
    JSR     OUTPUT_OPEN_PAREN
    JSR     EA_LOAD_AN
    JSR     OUTPUT_CLOSE_PAREN
    RTS

EA_MODE_011:
    ;For Direct Addressing and pushing the pointer forward (An)+
    JSR     OUTPUT_OPEN_PAREN
    JSR     EA_LOAD_AN
    JSR     OUTPUT_CLOSE_PAREN
    JSR     OUTPUT_PLUS
    RTS

EA_MODE_100:
    ;For Direct Addressing and pulling the pointer backward -(An)
    JSR     OUTPUT_MINUS
    JSR     OUTPUT_OPEN_PAREN
    JSR     EA_LOAD_AN
    JSR     OUTPUT_CLOSE_PAREN
    RTS

EA_MODE_111:
    ;Determines which register we're going to
    CMP.B   #%000,EA_REG
    BEQ     EA_MODE_111_REG_000  
    CMP.B   #%001,EA_REG
    BEQ     EA_MODE_111_REG_001 
    CMP.B   #%010,EA_REG
    BEQ     EA_MODE_111_REG_100  
    CMP.B   #%011,EA_REG
    BEQ     EA_MODE_111_REG_100
    CMP.B   #%100,EA_REG
    BEQ     EA_MODE_111_REG_100

EA_MODE_111_REG_000:
    ;For Word-sized EAs
    JSR     OUTPUT_HEX_SYMBOL
    JSR     EXTRACT_WORD
    MOVE.L  D3,D5
    JSR     ADDR_TO_ASCII_WORD
	JSR		PRINT_BUFFER
    RTS

EA_MODE_111_REG_001:
    ;For Long-sized EAs
    JSR     OUTPUT_HEX_SYMBOL
    JSR     EXTRACT_LONG
    MOVE.L  D3,D5
    JSR     ADDR_TO_ASCII_LONG
	JSR		PRINT_BUFFER
    RTS

EA_MODE_111_REG_100:
    ;For immediate data
    JSR     OUTPUT_IMMEDIATE_SYMBOL
    JSR     OUTPUT_HEX_SYMBOL
    JSR     EA_MOVE_AHEAD_TABLE
    MOVE.L  D3,D5
    JSR     ADDR_TO_ASCII_CHECK
	JSR		PRINT_BUFFER
    RTS

*************************************************************
*               EA Calculator - Output Size                 *
*Registers:                                                 *
*           N/A                                             *
*Description: This section determines the size of the EA,   *
*             and calls the corresponding size output       *
*             subroutine, and tabs over for the next operand*
*************************************************************
EA_OUTPUT_SIZE_TABLE:
    CMP.B   #0,EA_SIZE                  ; size == byte?
    BEQ     EA_OUTPUT_SIZE_BYTE    
    CMP.B   #1,EA_SIZE                  ; size == word?
    BEQ     EA_OUTPUT_SIZE_WORD   
    CMP.B   #2,EA_SIZE                  ; size == long?
    BEQ     EA_OUTPUT_SIZE_LONG
    BRA     EA_OUTPUT_SIZE_SKIP         ; Unknown size, skip

EA_OUTPUT_SIZE_BYTE:
    ;.B
    JSR     OUTPUT_SIZE_BYTE
    JSR     OUTPUT_TAB
    RTS

EA_OUTPUT_SIZE_WORD:
    ;.W
    JSR     OUTPUT_SIZE_WORD
    JSR     OUTPUT_TAB
    RTS

EA_OUTPUT_SIZE_LONG:
    ;.L
    JSR     OUTPUT_SIZE_LONG
    JSR     OUTPUT_TAB
    RTS

EA_OUTPUT_SIZE_SKIP:
    ;Unable to determine size, skip ahead
    JSR     OUTPUT_TAB
    RTS

*************************************************************
*               EA Calculator - Move Ahead                  *
*Registers:                                                 *
*           N/A                                             *
*Description: This section determines the size of the EA,   *
*             uses the EXTRACT_WORD or EXTRACT_LONG utility *
*             to extract the address for printing.          *
*************************************************************
EA_MOVE_AHEAD_TABLE:
    CMP.B   #0,EA_SIZE                  ; size == byte?
    BEQ     EA_MOVE_AHEAD_BYTE    
    CMP.B   #1,EA_SIZE                  ; size == word?
    BEQ     EA_MOVE_AHEAD_WORD   
    CMP.B   #2,EA_SIZE                  ; size == long?
    BEQ     EA_MOVE_AHEAD_LONG
    BRA     EA_MOVE_AHEAD_SKIP          ; Unknown size, skip

EA_MOVE_AHEAD_BYTE:
    ;$XX
    JSR     EXTRACT_WORD
    RTS

EA_MOVE_AHEAD_WORD:
    ;$XXXX
    JSR     EXTRACT_WORD
    RTS
    
EA_MOVE_AHEAD_LONG:
    ;$XXXXXXXX
    JSR     EXTRACT_LONG    
    RTS

EA_MOVE_AHEAD_SKIP:
    RTS
 
*************************************************************
*           EA Calculator - Calculate Displacement          *
*Registers:                                                 *
*           D3: Still holds the contents of the EXTRACT_WORD*
*               or EXTRACT_LONG subroutine.                 *
*           D5: Used to combine data from current address   *
*               and print the address data in ADDR_TO_ASCII.*
*           A5: Still holds the current address pointer.    *
*Description: This section determines the size of the       *
*             displacement of the BRA op code -- either 8-  *
*             bit, 16-bit, or 32-bit. It then displays the  *
*             address.                                      *
*************************************************************
EA_CALC_DISPLACE_TABLE:
    MOVE.L  A5,D6                       ; Copy current address into D6 for manipulation
    JSR     OUTPUT_TAB                  ; Tab over from Op Code
    JSR     OUTPUT_HEX_SYMBOL
    CMP.B   #0,OP_DISPLACE_DATA         ; address == 16-bit displacement?
    BEQ     EA_CALC_DISPLACE_16BIT
    CMP.B   #$FF,OP_DISPLACE_DATA       ; address == 32-bit displacement?
    BEQ     EA_CALC_DISPLACE_32BIT
    MOVE.B  OP_DISPLACE_DATA,D5         ; Otherwise, it's an 8-bit displacement
    ADD.L   D6,D5
    JSR     ADDR_TO_ASCII_BYTE
	JSR		PRINT_BUFFER
    RTS

EA_CALC_DISPLACE_16BIT:
    JSR     EXTRACT_WORD
    MOVE.W  D3,D5
    ADD.L   D6,D5
    JSR     ADDR_TO_ASCII_WORD
	JSR		PRINT_BUFFER
    RTS

EA_CALC_DISPLACE_32BIT: 
    JSR     EXTRACT_LONG
    MOVE.L  D3,D5
    ADD.L   D6,D5
    JSR     ADDR_TO_ASCII_LONG
	JSR		PRINT_BUFFER
    RTS

*************************************************************
*   EA Calculator Utility - Reverse Addresses for MOVEM     *
* Registers:                                                *
*            D0: Acts as counter                            *
*            D1: Holds Data Registers to be printed         *
*            D5: Still holds address value coming in from   *
*               function that calls this subroutine.        *
*Description:                                               *
*            D5 holds the data registers loaded in from     *
*            ADDR_TO_ASCII_CHECK, this function starts at   *
*            end of D5 and pops registers out in reverse    *
*            order                                          *
************************************************************* 

ADDR_TO_ASCII_REVERSE:
    MOVEM.L D0/D1,-(SP)                         ; D0 used for counter, D1 stores registers from D5 as they Pop
    CLR.L   D0                                  ; Make sure D0 is empty
    MOVE.B  #31,D0                              ; Load 32 bits of memory to count back from
ADDR_TO_ASCII_REVERSE_LOOP:
    BTST    #0,D5                               ; Check if D5 carry flag set to 0
    BEQ     ADDR_TO_ASCII_REVERSE_0             ; If so move to final step
    BRA     ADDR_TO_ASCII_REVERSE_1             ; If not, move to next step
ADDR_TO_ASCII_REVERSE_0:
    BCLR    D0,D1                               ; Clear carry/overflow flags
    BRA     ADDR_TO_ASCII_REVERSE_CONTINUE      ; Branch to loop portion
ADDR_TO_ASCII_REVERSE_1:                    
    BSET    D0,D1                               ; Set carry/overflow flag
    BRA     ADDR_TO_ASCII_REVERSE_CONTINUE      ; Branch to loop portion
ADDR_TO_ASCII_REVERSE_CONTINUE:
    ROR.L   #1,D5                               ; Rotate to next data register in D5
    CMPI.B  #0,D0                               ; Check if counter is equal to 0
    DBEQ    D0,ADDR_TO_ASCII_REVERSE_loop       ; If not, decrease and branch to loop start
ADDR_TO_ASCII_REVERSE_EXIT:
    MOVE.L  D1,D5                               ; Move Contents of D1 into D5
    MOVEM.L (SP)+,D0/D1
    RTS

*************************************************************
*                       Constants                           *
*************************************************************
*************************************************************
*                Constants - Error Output                   *
*************************************************************
UNSUPPORTED_OP      DC.B    'OpCode not supported, start assembly from next line',CR,LF,0            ; Inform user of unsupported op code
INVALID_START       DC.B    'That was an invalid starting address. Please try again.',CR,LF,0        ; Inform user of bad data
INVALID_END         DC.B    'That was an invalid ending address. Please try again.',CR,LF,0          ; Inform user of bad data
INVALID_ADDR        DC.B    'You input an invalid address. Please try again.',CR,LF,0                ; Inform user of bad data
INVALID_SAME        DC.B    'The addresses are the same. Please try again.',CR,LF,0                  ; Inform user of bad data
INVALID_PAIR        DC.B    'The end address is before the start address. Please try again.',CR,LF,0 ; Inform user of bad data
INVALID_STACK       DC.B    'The start address is the same as the stack. Please try again.',CR,LF,0  ; Inform user of bad data
INVALID_ORG         DC.B    'The start address is the same as the origin. Please try again.',CR,LF,0 ; Inform user of bad data

*************************************************************
*                 Constants - User Output                   *
*************************************************************
GREET_USER          DC.B    'Hello and welcome to Disassembler 3000.',CR,LF,0                        ; Greet user
START_PROMPT        DC.B    'Please enter a starting address: ',0                                    ; Prompt user for starting address
END_PROMPT          DC.B    'Please enter an ending address: ',0                                     ; Prompt user for ending address
CONTINUE_PROMPT     DC.B    'Press the enter key to continue disassembly...',0                       ; Prompt user to continue
REPEAT_OR_QUIT      DC.B    'Would you like to continue? Enter Y for yes or N for no: ',0            ; Prompt user to start over or quit
EXIT_MESSAGE        DC.B    'Thanks for using Disassembler 3000!',CR,LF,0                            ; Farewell to user
INVALID_ANSWER      DC.B    'Invalid input. Please enter either Y to continue or N to quit.',CR,LF,0 ; Inform user of bad data

*************************************************************
*                Constants - Symbol Strings                 *
************************************************************* 
SYMBOL_STRING_SLASH         DC.B    '/',0
SYMBOL_STRING_HEX           DC.B    '$',0
SYMBOL_STRING_IMMEDIATE     DC.B    '#',0
SYMBOL_STRING_OPEN_PAREN    DC.B    '(',0
SYMBOL_STRING_CLOSE_PAREN   DC.B    ')',0
SYMBOL_STRING_COMMA         DC.B    ',',0
SYMBOL_STRING_PLUS          DC.B    '+',0
SYMBOL_STRING_MINUS         DC.B    '-',0
SYMBOL_STRING_SIZE_UNKNOWN  DC.B    '.?',0
SYMBOL_STRING_SIZE_BYTE     DC.B    '.B',0
SYMBOL_STRING_SIZE_WORD     DC.B    '.W',0
SYMBOL_STRING_SIZE_LONG     DC.B    '.L',0

*************************************************************
*                Constants - Utility Arrays                 *
* This section contains arrays for printing ASCII chars,    *
* sizes, registers, and the Bcc extensions for conditions.  *
*************************************************************
STRING_ASCII_ARRAY      DC.B    '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F' 
STRING_DREGISTER_ARRAY  DC.W    'D0','D1','D2','D3','D4','D5','D6','D7'
STRING_AREGISTER_ARRAY  DC.W    'A0','A1','A2','A3','A4','A5','A6','A7'
STRING_REGISTER_ARRAY   DC.B    'A7','A6','A5','A4','A3','A2','A1','A0','D7','D6','D5','D4','D3','D2','D1','D0'
STRING_BCC_ARRAY        DC.W    'RA','SR','HI','LS','CC','CS','NE','EQ','VC','VS','PL','MI','GE','LT','GT','LE'

*************************************************************
*                  Constants - Op Strings                   *
* This section contains strings for each supported Op Code  *
* that will be fed into DECODED_BUFFER for display.         *
*************************************************************
OP_STRING_ADD       DC.B    'ADD',0
OP_STRING_ADDA      DC.B    'ADDA',0
OP_STRING_ADDI      DC.B    'ADDI',0
OP_STRING_ADDQ      DC.B    'ADDQ',0
OP_STRING_ADDX      DC.B    'ADDX',0
OP_STRING_AND       DC.B    'AND',0
OP_STRING_ANDI      DC.B    'ANDI',0
OP_STRING_ASL       DC.B    'ASL',0
OP_STRING_ASR       DC.B    'ASR',0
OP_STRING_B         DC.B    'B',0
OP_STRING_BCHG      DC.B    'BCHG',0
OP_STRING_BCLR      DC.B    'BCLR',0
OP_STRING_BSET      DC.B    'BSET',0
OP_STRING_BTST      DC.B    'BTST',0
OP_STRING_CHK       DC.B    'CHK',0
OP_STRING_CLR       DC.B    'CLR',0
OP_STRING_CMP       DC.B    'CMP',0
OP_STRING_CMPA      DC.B    'CMPA',0
OP_STRING_CMPI      DC.B    'CMPI',0
OP_STRING_CMPM      DC.B    'CMPM',0
OP_STRING_DB	    DC.B	'DB',0
OP_STRING_DIVS	    DC.B	'DIVS',0
OP_STRING_DIVU	    DC.B	'DIVU',0
OP_STRING_EOR	    DC.B	'EOR',0
OP_STRING_EORI	    DC.B	'EORI',0
OP_STRING_EXG	    DC.B	'EXG',0
OP_STRING_EXT	    DC.B	'EXT',0
OP_STRING_ILLEGAL	DC.B	'ILLEGAL',0
OP_STRING_INVALID	DC.B	'DATA',0
OP_STRING_JMP       DC.B    'JMP',0
OP_STRING_JSR       DC.B    'JSR',0
OP_STRING_LEA	    DC.B	'LEA',0
OP_STRING_LINK	    DC.B	'LINK',0
OP_STRING_LSL	    DC.B	'LSL',0
OP_STRING_LSR	    DC.B	'LSR',0
OP_STRING_MOVE	    DC.B	'MOVE',0
OP_STRING_MOVEA     DC.B    'MOVEA',0
OP_STRING_MOVEM     DC.B    'MOVEM',0
OP_STRING_MOVEP     DC.B    'MOVEP',0
OP_STRING_MOVEQ     DC.B    'MOVEQ',0
OP_STRING_MULS      DC.B    'MULS',0
OP_STRING_MULU      DC.B    'MULU',0
OP_STRING_NBCD      DC.B    'NBCD',0
OP_STRING_NEG       DC.B    'NEG',0
OP_STRING_NEGX      DC.B    'NEGX',0
OP_STRING_NOP       DC.B    'NOP',0
OP_STRING_NOT       DC.B    'NOT',0
OP_STRING_OR	    DC.B	'OR',0
OP_STRING_ORI       DC.B    'ORI',0
OP_STRING_PEA       DC.B    'PEA',0
OP_STRING_RESET     DC.B    'RESET',0
OP_STRING_ROL       DC.B    'ROL',0
OP_STRING_ROR	    DC.B	'ROR',0
OP_STRING_ROXL      DC.B    'ROXL',0
OP_STRING_ROXR      DC.B    'ROXR',0
OP_STRING_RTE       DC.B    'RTE',0
OP_STRING_RTR       DC.B    'RTR',0
OP_STRING_RTS	    DC.B	'RTS',0
OP_STRING_S         DC.B    'S',0
OP_STRING_SBCD      DC.B    'SBCD',0
OP_STRING_STOP      DC.B    'STOP',0
OP_STRING_SUB	    DC.B	'SUB',0
OP_STRING_SUBA	    DC.B	'SUBA',0
OP_STRING_SUBI	    DC.B	'SUBI',0
OP_STRING_SUBQ	    DC.B	'SUBQ',0
OP_STRING_TRAP	    DC.B	'TRAP',0

*************************************************************
*                         Storage                           *
*************************************************************
OP_INSTR            DS.B    2           ; The entire instruction
FIRST_FOUR_BYTES    DS.B    1           ; The first 4 bytes
EA_SIZE             DS.B    1           ; EA Size
EA_MODE             DS.B    1           ; EA Mode
EA_REG              DS.B    1           ; Data/Address Register
EA_MODE_REG         DS.B    1           ; Mode and Register (EA)
REG_ROTATE          DS.B    1           ; Register rotate
OP_COND_CODE        DS.B    1           ; Condition code
OP_SIZE_DIR         DS.B    1           ; Size/Direction
OP_DISPLACE_DATA    DS.B    1           ; Displacement/data
OP_ORI_SIZE         DS.B    1           ; Size for ORI
OP_MOVE_SIZE        DS.B    1           ; Size for MOVE
OP_MOVEM_DIR        DS.B    1           ; Direction bit for MOVEM
OP_MOVEM_SIZE       DS.B    1           ; Size for MOVEM
EA_MODE_LAST_SIX    DS.B    1           ; Mode of EA in last 6 bits
OP_MOVE_MODE        DS.B    1           ; Mode for MOVE
EA_REG_LAST_SIX     DS.B    1           ; Reg of EA in last 6 bits
ASCII_START         DS.B    8           ; Appends ASCII start address to the end of program in memory
ASCII_END           DS.B    8           ; Appends ASCII end address to the end of program in memory
ASCII_Y_OR_N        DS.B    2           ; Storage for response for restarting or quitting
DECODED_BUFFER      DS.B    BUFSIZE     ; Storage for decoded instructions (64 bytes)

*************************************************************
*                      End Program                          *
*************************************************************
EXIT:
    SIMHALT HALT SIMULATOR
    END     START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
