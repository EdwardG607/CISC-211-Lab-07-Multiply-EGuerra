/*** asmMult.s   ***/
/* Tell the assembler to allow both 16b and 32b extended Thumb instructions */
.syntax unified

#include <xc.h>

/* Tell the assembler that what follows is in data memory    */
.data
.align
 
/* define and initialize global variables that C can access */
/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Edward Guerra Ramirez"  

.align   /* realign so that next mem allocations are on word boundaries */
 
/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global a_Multiplicand,b_Multiplier,rng_Error,a_Sign,b_Sign,prod_Is_Neg,a_Abs,b_Abs,init_Product,final_Product
.type a_Multiplicand,%gnu_unique_object
.type b_Multiplier,%gnu_unique_object
.type rng_Error,%gnu_unique_object
.type a_Sign,%gnu_unique_object
.type b_Sign,%gnu_unique_object
.type prod_Is_Neg,%gnu_unique_object
.type a_Abs,%gnu_unique_object
.type b_Abs,%gnu_unique_object
.type init_Product,%gnu_unique_object
.type final_Product,%gnu_unique_object

/* NOTE! These are only initialized ONCE, right before the program runs.
 * If you want these to be 0 every time asmMult gets called, you must set
 * them to 0 at the start of your code!
 */
a_Multiplicand:  .word     0  
b_Multiplier:    .word     0  
rng_Error:       .word     0  
a_Sign:          .word     0  
b_Sign:          .word     0 
prod_Is_Neg:     .word     0  
a_Abs:           .word     0  
b_Abs:           .word     0 
init_Product:    .word     0
final_Product:   .word     0

 /* Tell the assembler that what follows is in instruction memory    */
.text
.align

    
/********************************************************************
function name: asmMult
function description:
     output = asmMult ()
     
where:
     output: 
     
     function description: The C call ..........
     
     notes:
        None
          
********************************************************************/    
.global asmMult
.type asmMult,%function
asmMult:   

    /* save the caller's registers, as required by the ARM calling convention */
    push {r4-r11,LR}
 
.if 0
    /* profs test code. */
    mov r0,r0
.endif
    
    /** note to profs: asmMult.s solution is in Canvas at:
     *    Canvas Files->
     *        Lab Files and Coding Examples->
     *            Lab 8 Multiply
     * Use it to test the C test code */
    
    /*** STUDENTS: Place your code BELOW this line!!! **************/
    
 /* Prepares the system for multiplication by clearing any relevant variables, 
    ensuring no residual data from past operations affect the latest result*/
    LDR r4, =a_Multiplicand
    STR r0, [r4]
    LDR r4, =b_Multiplier
    STR r1, [r4]
    LDR r4, =rng_Error
    MOV r5, #0
    STR r5, [r4]
    LDR r4, =a_Sign
    STR r5, [r4]
    LDR r4, =b_Sign
    STR r5, [r4]
    LDR r4, =prod_Is_Neg
    STR r5, [r4]
    LDR r4, =a_Abs
    STR r5, [r4]
    LDR r4, =b_Abs
    STR r5, [r4]
    LDR r4, =init_Product
    STR r5, [r4]
    LDR r4, =final_Product
    STR r5, [r4]
    
    /* Validates that r0 and r1 hold the values within the 16-bit signed integers. 
    Branching to 'range_error' protects against overflow and data corruption by 
    catching out of range values early. */
    LDR r6, =32767
    CMP r0, r6
    BGT range_error
    LDR r6, =-32768
    CMP r0, r6
    BLT range_error
    LDR r6, =32767
    CMP r1, r6
    BGT range_error
    LDR r6, =-32768
    CMP r1, r6
    BLT range_error
    
    /* This facilitate subsequent actions, such as changing the sign of 
    the result after doing unsigned arithmetic, ascertains and records 
    the sign (0 for positive, 1 for negative) of each input. */
    LDR r4, =a_Sign
    MOV r5, #0
    CMP r0, #0
    BGE store_a_sign
    MOV r5, #1
    store_a_sign:
    STR r5, [r4]
    
    LDR r4, =b_Sign
    MOV r5, #0
    CMP r1, #0
    BGE store_b_sign
    MOV r5, #1
    store_b_sign:
    STR r5, [r4]
    
    /* Ensures both input values are converted to their positive equivalents
    by checking their sign and conditionally reversing them. This step
    is essential for any logic that relies on magnitude comparisons or
    distance calculations, as it neutralizes the effect of negative inputs. */
    MOV r2, r0
    MOV r3, r1
    CMP r2, #0
    BGE compute_a_abs
    RSB r2, r2, #0
    compute_a_abs:
    CMP r3, #0
    BGE compute_b_abs
    RSB r3, r3, #0
    compute_b_abs:
    
    LDR r4, =a_Abs
    STR r2, [r4]
    LDR r4, =b_Abs
    STR r3, [r4]
    
    /* Determines if the product will be negative. If either operand is 
    zero then it doesn't leave a sing. Otherwise, it'll use XOR to to check
    if it's either positive or negative and set a 0 or 1 respectively. */
    LDR r4, =prod_Is_Neg
    MOV r6, #0
    CMP r2, #0
    BEQ set_prod_zero
    CMP r3, #0
    BEQ set_prod_zero
    
    EOR r5, r0, r1
    TST r5, #0x80000000
    BNE set_neg_sign
    B store_prod_sign
    
    set_neg_sign:
    MOV r6, #1
    B store_prod_sign
    
    set_prod_zero:
    MOV r6, #0
    
    store_prod_sign:
    STR r6, [r4]
    
    /* Initializes the result to 0 and sets up a 16-iteration loop to process 
    each bit of the multiplier, preparing to shift-and-add multiplication 
    where each bit determines whether to add the multiplicand */
    
    MOV r7, #0    /* Initialize product to 0 */
    MOV r8, #16   /* Loop counter for 16-bit values */
    
mul_loop:
    TST r3, #1      /* Check if LSB of multiplier is set */
    BEQ skip_add
    ADD r7, r7, r2  /* Add multiplicand if bit is 1 */
    skip_add:
    
    LSRS r3, r3, #1  /* Shift multiplier right */
    LSLS r2, r2, #1  /* Shift multiplicand left */
    SUBS r8, r8, #1
    BNE mul_loop
    
    /* Saves teh current product value to memory for later use */
    LDR r4, =init_Product
    STR r7, [r4]
    
    /* Checks if the result should be negative; if so, 
    converts the product to its two's complement */
    LDR r4, =prod_Is_Neg
    LDR r5, [r4]
    CMP r5, #1
    BNE store_final_product
    RSB r7, r7, #0 /* If negative, reverses its sign to ensure the correct value */
    
    store_final_product:
    LDR r4, =final_Product
    STR r7, [r4]
    
    /* Copies the final result to r0 */
    MOV r0, r7
    
    B done

range_error:
    /* Sets the error flag within range error, then clears r0 
    to indicate failure before exiting */
    LDR r4, =rng_Error
    MOV r5, #1
    STR r5, [r4]
    MOV r0, #0
    B done
    
    /*** STUDENTS: Place your code ABOVE this line!!! **************/

done:    
    /* restore the caller's registers, as required by the 
     * ARM calling convention 
     */
    mov r0,r0 /* these are do-nothing lines to deal with IDE mem display bug */
    mov r0,r0 

screen_shot:    pop {r4-r11,LR}

    mov pc, lr	 /* asmMult return to caller */
   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           




