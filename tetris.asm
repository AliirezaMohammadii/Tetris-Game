title Tetris Game Project

.model small 
.stack 64   

.data 

	len dw 15 ; size of each square block's width (width = lenght)
	curr_color db ?

	current_function dw ? ; a number between 1-13 that shows which shape we have.

	; up-left position of current shape
	X dw ?
	Y dw ?

	; cooperarions of current block to draw
	x1 dw ?
	y1 dw ?
	x2 dw ?
	y2 dw ?

	xp dw ?	; to store value of x1 then restore it
	yp dw ?	; to store value of y1 then restore it

	rb dw ?		; #row of below block

	char db ?	; current char to show on the screen
	x_char db 2	; X of current char position	
	y_char db ?	; Y of current char position

	init_delay_times dw 3	; initialized delay_times
	delay_times dw ? ; how many times to repeat delay
	init_delay_inner_counter dw 0FFFFh
	delay_inner_counter dw ?

	board dw 240 dup(0000h) ; there are 240 (15*15) blocks in a 180*300 board

	Xn dw 200 ; X of most down position
	Yn dw 320 ; Y of most right position

	;															   _   _
	; margin bounder = 10 / I used it as a magic number in my code  \o/

	; board array indexes. Each one keeps one of 4-blocks pisitions in board array, for current shape.
	idx1 dw ?
	idx2 dw ?
	idx3 dw ?
	idx4 dw ?

	score dw 0	; player score

	filled_rows dw 0  ; #filled_rows

	stop dw ? ; type : boolean

	random_val dw ?

	can_change dw ? ; type : boolean, to know we can change position of a shape or it cross the margin.

	end_of_game dw 0

	f_key_pressed dw ?

	shape_numbers db 1, 3, 4, 8, 10

	temp dw 3
	
.code 


main proc far
    mov ax, @data
    mov ds, ax   

    call init
	call run

    mov ax, 4c00h ; exit to operating system.
    int 21h    

main endp


run proc

	next:

		cmp f_key_pressed, 1
		jnz no_qiuck_move
		mov f_key_pressed, 0
		call draw_shape

		no_qiuck_move:

		; check end condition
		call check_end_condition
		cmp end_of_game, 1
		jz end_label

		; check filled rows
		call check_filled_rows
		cmp filled_rows, 0
		jz no_filled_rows
		call update_score

		no_filled_rows:

		call next_random_shape

		move_shape:

			call draw_shape
			call delay

			call show_score		; show score (it's in loop because of if a shape came on it, it will be showed again)

			cmp stop, 1
			jz next ; moving shoud be stopped

			call clear_shape

			mov si, X    ;  move down 1 block
			add si, len  ;
			mov X, si 	 ;
			jmp move_shape

		; stop_shape:
		; 	jmp next

		end_label:

	ret

endp run


clear_shape proc

	mov curr_color, 0 ; set color to background color
	call call_curr_funct ; clear current shape; to move and redraw

	ret

endp clear_shape


draw_shape proc

	call set_ap_color	; set appropriate color
	call call_curr_funct ; select related function to draw shape. one of 13 excisting functions

	ret

endp draw_shape


check_end_condition proc

	mov si, 20

	label0:
		cmp board[si], 0 ; 0 : black color
		jnz first_row_is_filled

		dec si
		cmp si, 0
		jg label0

		ret

	first_row_is_filled:
		mov end_of_game, 1

	ret

endp check_end_condition


show_score proc

	; x_char = 2
	mov y_char, 27
	call show_score_str

	inc y_char
	inc y_char
	mov ax, score
	call show_number	; show score

	ret

endp show_score


show_score_str proc

	inc y_char
	mov char, 'S'
	call show_char

	inc y_char
	mov char, 'C'
	call show_char

	inc y_char
	mov char, 'O'
	call show_char

	inc y_char
	mov char, 'R'
	call show_char

	inc y_char
	mov char, 'E'
	call show_char

	inc y_char
	mov char, ':'
	call show_char

	ret

endp show_score_str


update_score proc

	cmp filled_rows, 1
	jg more_than_one_filled_rows
	mov ax, score
	add ax, 10
	mov score, ax
	call show_score	; update_score
	mov filled_rows, 0
	ret

	more_than_one_filled_rows:
		mov ax, 20
		mov bx, filled_rows
		mul bx
		add ax, score
		mov score, ax
		call show_score	; update_score
		mov filled_rows, 0

	ret

endp update_score


check_pressed_key proc

	mov ah, 0
	int 16h

	cmp al, 'd'
	jz right
	cmp al, 'D'
	jz right

	cmp al, 'a'
	jz left
	cmp al, 'A'
	jz left

	cmp al, 's'
	jz down
	cmp al, 'S'
	jz down

	cmp al, 'w'
	jz rotate
	cmp al, 'W'
	jz rotate

	cmp al, 'f'
	jz quick_down
	cmp al, 'F'
	jz quick_down

	right:
		call check_right
		cmp can_change, 0
		jz no_change

		call clear_shape
		mov bx, Y
		add bx, len
		mov Y, bx
		call draw_shape
		ret

	left:
		call check_left
		cmp can_change, 0
		jz no_change

		call clear_shape
		mov bx, Y
		sub bx, len
		mov Y, bx
		call draw_shape
		ret

	down:
		call clear_shape
		mov bx, X
		add bx, len
		mov X, bx
		call draw_shape
		ret

	rotate:
		call clear_shape
		call rotate_shape
		call draw_shape
		ret

	quick_down:
		mov f_key_pressed, 1
		call finish_delay
		ret

	no_change:

	ret

endp check_pressed_key


finish_delay proc

	mov delay_times, 1			; quick movement
	mov delay_inner_counter, 1  ; Zero_delay
	mov di, 1					; finish current delay
	mov cx, 1					; finish current delay

	ret

endp finish_delay


rotate_shape proc

	cmp current_function, 1
	jz rotate1

	cmp current_function, 2
	jz rotate2

	cmp current_function, 3
	jz rotate3

	cmp current_function, 4
	jz rotate4
	
	cmp current_function, 5
	jz rotate5

	cmp current_function, 6
	jz rotate6

	cmp current_function, 7
	jz rotate7

	cmp current_function, 8
	jz rotate8

	cmp current_function, 9
	jz rotate9

	cmp current_function, 10
	jz rotate10

	cmp current_function, 11
	jz rotate11

	cmp current_function, 12
	jz rotate12

	cmp current_function, 13
	jz rotate13


	rotate1:
		mov current_function, 2
		ret

	rotate2:
		mov current_function, 1
		ret

	rotate3:
		mov current_function, 3
		ret

	rotate4:
		mov current_function, 5
		ret

	rotate5:
		mov current_function, 6
		ret

	rotate6:
		mov current_function, 7
		ret

	rotate7:
		mov current_function, 4
		ret

	rotate8:
		mov current_function, 9
		ret

	rotate9:
		mov current_function, 8
		ret

	rotate10:
		mov current_function, 11
		ret

	rotate11:
		mov current_function, 12
		ret

	rotate12:
		mov current_function, 13
		ret

	rotate13:
		mov current_function, 10
		ret

	ret

endp rotate_shape


check_right proc

	mov ax, idx1
	add ax, 40 ; to avoid overflow
	mov bx, 40 ; coef of last column
	mov dx, 0  ; clearing dx
	div bx
	cmp dx, 38
	jz change_forbidden

	mov ax, idx2
	add ax, 40 ; to avoid overflow
	mov bx, 40 ; coef of last column
	mov dx, 0  ; clearing dx
	div bx
	cmp dx, 38
	jz change_forbidden

	mov ax, idx3
	add ax, 40 ; to avoid overflow
	mov bx, 40 ; coef of last column
	mov dx, 0  ; clearing dx
	div bx
	cmp dx, 38
	jz change_forbidden

	mov ax, idx4
	add ax, 40 ; to avoid overflow
	mov bx, 40 ; coef of last column
	mov dx, 0  ; clearing dx
	div bx
	cmp dx, 38
	jz change_forbidden

	mov can_change, 1
	ret


	change_forbidden:
		mov can_change, 0

	ret

endp check_right



check_left proc

	mov ax, idx1
	add ax, 40  ; to avoid overflow
	mov bx, 40 ; coef of last column
	mov dx, 0  ; clearing dx
	div bx
	cmp dx, 0
	jz change_forbidden2

	mov ax, idx2
	add ax, 40  ; to avoid overflow
	mov bx, 40 ; coef of last column
	mov dx, 0  ; clearing dx
	div bx
	cmp dx, 0
	jz change_forbidden2

	mov ax, idx3
	add ax, 40  ; to avoid overflow
	mov bx, 40 ; coef of last column
	mov dx, 0  ; clearing dx
	div bx
	cmp dx, 0
	jz change_forbidden2

	mov ax, idx4
	add ax, 40  ; to avoid overflow
	mov bx, 40 ; coef of last column
	mov dx, 0  ; clearing dx
	div bx
	cmp dx, 0
	jz change_forbidden2

	mov can_change, 1
	ret


	change_forbidden2:
		mov can_change, 0

	ret

endp check_left



check_key_press proc

	mov ah, 01h
	int 16h
	jz no_key_pressed

	; key pressed
	call check_pressed_key

	no_key_pressed:

	ret

endp check_key_press


next_random_shape proc

	call init_vars

	; random value in range 1-13
	mov bx, 5
	call get_random_value
	mov si, random_val
	mov al, shape_numbers[si]
	mov ah, 0
	mov current_function, ax

	; mov current_function, 1

	mov X, 10

	mov bx, 15		; number of 15*15-blocks between 40 and 250
	call get_random_value
	mov ax, random_val
	mov bx, len
	mul bx
	add ax, 40			; random value in range 40-250 | 40 = 10(bounder) + 2*15(for shape7) / 250 = 320 - 10(bounder) - 60(lenght of longest shape(shape1))
	mov Y, ax

	ret

endp next_random_shape


init_vars proc

	mov stop, 0

	mov ax, init_delay_times
	mov delay_times, ax
	mov ax, init_delay_inner_counter
	mov delay_inner_counter, ax

	ret

endp init_vars


init proc

    call clear_screen    
    call set_graphic_mode
	call draw_margin

	ret                    
endp init 


clear_screen proc
    MOV ax, 0600h
    mov bh, 00h
    mov cx, 0000h
    mov dx, 184fh
    int 10h
                 
    ret                    
endp clear_screen 


set_graphic_mode proc
    mov ah, 00h
    mov al, 13h
    int 10h 
    
    ret
endp set_graphic_mode


draw_margin proc
    mov curr_color, 7	; set color. color : light gray
            
	mov x1, 0
	mov y1, 0
	mov x2, 10
	mov si, Yn
	inc si
	mov y2, si
	call draw_rectangle

	mov si, Xn
	sub si, 10
	mov x1, si
	mov y1, 0
	mov si, Xn
	mov x2, si
	mov si, Yn
	mov y2, si
	call draw_rectangle

	mov x1, 0
	mov y1, 0
	mov si, Xn
	mov x2, si
	mov y2, 10
	call draw_rectangle

	mov x1, 0
	mov si, Yn
	sub si, 10
	mov y1, si
	mov si, Xn
	mov x2, si
	mov si, Yn
	mov y2, si
	call draw_rectangle

	ret

endp draw_margin


draw_block proc 
    mov ah, 0ch ; function mode for setting pixel
    mov al, curr_color	; set color 
            
    ; setting x2 and y2  
    mov dx, x1
    add dx, len
    mov x2, dx
    mov dx, y1
    add dx, len
    mov y2, dx
      
    mov dx, x1
	label1:
		mov cx, y1

	label2:
		int 10h
		inc cx
		cmp cx, y2
		jnz label2
		
		inc dx
		cmp dx, x2
		jnz label1

	call draw_block_margin
    
    ret
    
endp draw_block 


draw_block_margin proc

	mov al, 0 ; setting background color
	
	mov dx, x1
	mov cx, y1

	label_1:
		int 10h
		inc cx
		cmp cx, y2
		jnz label_1

	add dx, len
	dec dx
	mov cx, y1

	label_2:
		int 10h
		inc cx
		cmp cx, y2
		jnz label_2

	mov dx, x1
	mov cx, y1

	label_3:
		int 10h
		inc dx
		cmp dx, x2
		jnz label_3

	mov dx, x1
	add cx, len
	dec cx

	label_4:
		int 10h
		inc dx
		cmp dx, x2
		jnz label_4

	ret

endp draw_block_margin


draw_rectangle proc 
    mov ah, 0ch ; function mode for setting pixel
    mov al, curr_color	; set color 
            
    mov dx, x1
	label5:
		mov cx, y1

	label6:
		int 10h
		inc cx
		cmp cx, y2
		jnz label6
		
		inc dx
		cmp dx, x2
		jnz label5
    
    ret
    
endp draw_rectangle 


proc set_ap_color ; set appropriate color


	cmp current_function, 1
	jz c1
	cmp current_function, 2
	jz c1
	cmp current_function, 3
	jz c3
	cmp current_function, 4
	jz c4
	cmp current_function, 5
	jz c5
	cmp current_function, 6
	jz c6
	cmp current_function, 7
	jz c7
	cmp current_function, 8
	jz c8
	cmp current_function, 9
	jz c9
	cmp current_function, 10
	jz c10
	cmp current_function, 11
	jz c11
	cmp current_function, 12
	jz c12
	cmp current_function, 13
	jz c13

	c1:
		mov curr_color, 11 ; light blue
		ret

	c2:
		mov curr_color, 11 ; light blue
		ret

	c3:
		mov curr_color, 14 ; yellow
		ret

	c4:
		mov curr_color, 12 ; light red
		ret

	c5:
		mov curr_color, 12 ; light red
		ret

	c6:
		mov curr_color, 12 ; light red
		ret

	c7:
		mov curr_color, 12 ; light red
		ret

	c8:
		mov curr_color, 10 ; light green
		ret

	c9:
		mov curr_color, 10 ; light green
		ret

	c10:
		mov curr_color, 13 ; purple
		ret

	c11:
		mov curr_color, 13 ; purple
		ret

	c12:
		mov curr_color, 13 ; purple
		ret

	c13:
		mov curr_color, 13 ; purple
		ret


endp set_ap_color


proc call_curr_funct ; call current function; between 13 excisting functions.


	cmp current_function, 1
	jz f1
	cmp current_function, 2
	jz f2
	cmp current_function, 3
	jz f3
	cmp current_function, 4
	jz f4
	cmp current_function, 5
	jz f5
	cmp current_function, 6
	jz f6
	cmp current_function, 7
	jz f7
	cmp current_function, 8
	jz f8
	cmp current_function, 9
	jz f9
	cmp current_function, 10
	jz f10
	cmp current_function, 11
	jz f11
	cmp current_function, 12
	jz f12
	cmp current_function, 13
	jz f13

	f1:
		call shape_1
		ret

	f2:
		call shape_2
		ret

	f3:
		call shape_3
		ret

	f4:
		call shape_4
		ret

	f5:
		call shape_5
		ret

	f6:
		call shape_6
		ret

	f7:
		call shape_7
		ret

	f8:
		call shape_8
		ret

	f9:
		call shape_9
		ret

	f10:
		call shape_10
		ret

	f11:
		call shape_11
		ret

	f12:
		call shape_12
		ret

	f13:
		call shape_13
		ret


endp call_curr_funct


; blue_shape : # # # #
shape_1 proc

	; draw :
	
	mov si, X
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #1
	call get_pos_in_array
	mov idx1, si	; idx : block position in board array

	mov si, y1
	add si, len
	mov y1, si
	call draw_block ; #2
	call get_pos_in_array
	mov idx2, si

	mov si, y1
	add si, len
	mov y1, si
	call draw_block ; #3
	call get_pos_in_array
	mov idx3, si

	mov si, y1
	add si, len
	mov y1, si
	call draw_block ; #4
	call get_pos_in_array
	mov idx4, si


	; check_stop_condition :

	mov si, X
	add si, len
	mov rb, si		; rb : #row of below block

	mov si, idx1
			; same column, below row block position in array
	call check_stop_condition
	cmp stop, 1
	jz stop1

	mov si, idx2
	call check_stop_condition
	cmp stop, 1
	jz stop1

	mov si, idx3
	call check_stop_condition
	cmp stop, 1
	jz stop1

	mov si, idx4
	call check_stop_condition
	cmp stop, 1
	jz stop1

	ret

	; # changing related color values in board array 
	stop1:
		call change_color_values

	ret

endp shape_1


; blue_shape(+90 Degree) : #
;			   			   #
;			   			   #
;			   			   #
shape_2 proc

	mov si, X
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #1
	call get_pos_in_array
	mov idx1, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #2
	call get_pos_in_array
	mov idx2, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #3
	call get_pos_in_array
	mov idx3, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #4
	call get_pos_in_array
	mov idx4, si	; idx : block position in board array
	

	; check_stop_condition :

	mov si, X
	add si, len
	add si, len
	add si, len
	add si, len
	mov rb, si		; rb : #row of below block

	mov si, idx4
			; same column, below row block position in array
	call check_stop_condition
	cmp stop, 1
	jz stop2

	ret

	; # changing related color values in board array 
	stop2:
		call change_color_values
	
	ret

endp shape_2


; yellow_shape : # #
;    			 # #
shape_3 proc

	mov si, X
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #1
	call get_pos_in_array
	mov idx1, si	; idx : block position in board array

	mov si, Y
	add si, len
	mov y1, si
	call draw_block ; #2
	call get_pos_in_array
	mov idx2, si	; idx : block position in board array

	mov si, X
	add si, len
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #3
	call get_pos_in_array
	mov idx3, si	; idx : block position in board array

	mov si, Y
	add si, len
	mov y1, si
	call draw_block ; #4
	call get_pos_in_array
	mov idx4, si	; idx : block position in board array


	; check_stop_condition :
	mov si, X
	add si, len
	add si, len
	mov rb, si		; rb : #row of below block

	mov si, idx3
			; same column, below row block position in array
	call check_stop_condition
	cmp stop, 1
	jz stop3

	mov si, idx4
	call check_stop_condition
	cmp stop, 1
	jz stop3

	ret

	; # changing related color values in board array 
	stop3:
		call change_color_values
	
	ret

endp shape_3


; orange_shape : #
;			     #
;			     # #
shape_4 proc

	mov si, X
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #1
	call get_pos_in_array
	mov idx1, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #2
	call get_pos_in_array
	mov idx2, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #3
	call get_pos_in_array
	mov idx3, si	; idx : block position in board array

	mov si, y1
	add si, len
	mov y1, si
	call draw_block ; #4
	call get_pos_in_array
	mov idx4, si	; idx : block position in board array


	; check_stop_condition :

	mov si, X
	add si, len
	add si, len
	add si, len
	mov rb, si		; rb : #row of below block

	mov si, idx3
	call check_stop_condition
	cmp stop, 1
	jz stop4

	mov si, idx4
	call check_stop_condition
	cmp stop, 1
	jz stop4

	ret

	; # changing related color values in board array 
	stop4:
		call change_color_values
	
	ret

endp shape_4


; orange_shape(+90 Degree) : # # #
;			     			 #
shape_5 proc

	mov si, X
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #1
	call get_pos_in_array
	mov idx1, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #2
	call get_pos_in_array
	mov idx2, si	; idx : block position in board array

	mov si, X
	mov x1, si
	mov si, Y
	add si, len
	mov y1, si
	call draw_block ; #3
	call get_pos_in_array
	mov idx3, si	; idx : block position in board array

	mov si, y1
	add si, len
	mov y1, si
	call draw_block ; #4
	call get_pos_in_array
	mov idx4, si	; idx : block position in board array


	; check_stop_condition :

	mov si, X
	add si, len
	add si, len
	mov rb, si		; rb : #row of below block

	mov si, idx2
	call check_stop_condition
	cmp stop, 1
	jz stop5

	mov si, idx3
	call check_stop_condition
	cmp stop, 1
	jz stop5

	mov si, idx4
	call check_stop_condition
	cmp stop, 1
	jz stop5

	ret

	; # changing related color values in board array 
	stop5:
		call change_color_values
	
	ret

endp shape_5


; orange_shape(+180 Degree) : # #
;			     			    #
;			     			    #
shape_6 proc

	mov si, X
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #1
	call get_pos_in_array
	mov idx1, si	; idx : block position in board array

	mov si, Y
	add si, len
	mov y1, si
	call draw_block ; #2
	call get_pos_in_array
	mov idx2, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #3
	call get_pos_in_array
	mov idx3, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #4
	call get_pos_in_array
	mov idx4, si	; idx : block position in board array


	; check_stop_condition :

	mov si, X
	add si, len
	add si, len
	add si, len
	mov rb, si		; rb : #row of below block

	mov si, idx1
			; same column, below row block position in array
	call check_stop_condition
	cmp stop, 1
	jz stop6

	mov si, idx4
	call check_stop_condition
	cmp stop, 1
	jz stop6

	ret

	; # changing related color values in board array 
	stop6:
		call change_color_values
	
	ret

endp shape_6


; orange_shape(-90 Degree) :     #
;			     			 # # #
shape_7 proc

	mov si, X
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #1
	call get_pos_in_array
	mov idx1, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #2
	call get_pos_in_array
	mov idx2, si	; idx : block position in board array

	mov si, y1
	sub si, len
	mov y1, si
	call draw_block ; #3
	call get_pos_in_array
	mov idx3, si	; idx : block position in board array

	mov si, y1
	sub si, len
	mov y1, si
	call draw_block ; #4
	call get_pos_in_array
	mov idx4, si	; idx : block position in board array


	; check_stop_condition :

	mov si, X
	add si, len
	add si, len
	mov rb, si		; rb : #row of below block

	mov si, idx2
	call check_stop_condition
	cmp stop, 1
	jz stop7

	mov si, idx3
	call check_stop_condition
	cmp stop, 1
	jz stop7

	mov si, idx4
	call check_stop_condition
	cmp stop, 1
	jz stop7

	ret

	; # changing related color values in board array 
	stop7:
		call change_color_values
	
	ret

endp shape_7


; green_shape : #
;			    # #
;			      #
shape_8 proc

	mov si, X
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #1
	call get_pos_in_array
	mov idx1, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #2
	call get_pos_in_array
	mov idx2, si	; idx : block position in board array

	mov si, y1
	add si, len
	mov y1, si
	call draw_block ; #3
	call get_pos_in_array
	mov idx3, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #4
	call get_pos_in_array
	mov idx4, si	; idx : block position in board array


	; check_stop_condition :

	mov si, X
	add si, len
	add si, len
	add si, len
	mov rb, si		; rb : #row of below block

	mov si, idx2
	call check_stop_condition
	cmp stop, 1
	jz stop8

	mov si, idx4
	call check_stop_condition
	cmp stop, 1
	jz stop8

	ret

	; # changing related color values in board array 
	stop8:
		call change_color_values
	
	ret

endp shape_8


; green_shape(+90 Degree) :   # #
;			    		    # #
shape_9 proc

	mov si, X
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #1
	call get_pos_in_array
	mov idx1, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #2
	call get_pos_in_array
	mov idx2, si	; idx : block position in board array

	mov si, y1
	sub si, len
	mov y1, si
	call draw_block ; #3
	call get_pos_in_array
	mov idx3, si	; idx : block position in board array

	mov si, X
	mov x1, si
	mov si, Y
	add si, len
	mov y1, si
	call draw_block ; #4
	call get_pos_in_array
	mov idx4, si	; idx : block position in board array


	; check_stop_condition :

	mov si, X
	add si, len
	add si, len
	mov rb, si		; rb : #row of below block

	mov si, idx2
	call check_stop_condition
	cmp stop, 1
	jz stop9

	mov si, idx3
	call check_stop_condition
	cmp stop, 1
	jz stop9

	mov si, idx4
	call check_stop_condition
	cmp stop, 1
	jz stop9

	ret

	; # changing related color values in board array 
	stop9:
		call change_color_values
	
	ret

endp shape_9


; purple_shape : # # #
;				   #
shape_10 proc

	mov si, X
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #1
	call get_pos_in_array
	mov idx1, si	; idx : block position in board array

	mov si, y1
	add si, len
	mov y1, si
	call draw_block ; #2
	call get_pos_in_array
	mov idx2, si	; idx : block position in board array

	mov si, y1
	add si, len
	mov y1, si
	call draw_block ; #3
	call get_pos_in_array
	mov idx3, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	mov si, y1
	sub si, len
	mov y1, si
	call draw_block ; #4
	call get_pos_in_array
	mov idx4, si	; idx : block position in board array


	; check_stop_condition :

	mov si, X
	add si, len
	add si, len
	mov rb, si		; rb : #row of below block

	mov si, idx1
			; same column, below row block position in array
	call check_stop_condition
	cmp stop, 1
	jz stop10

	mov si, idx3
	call check_stop_condition
	cmp stop, 1
	jz stop10

	mov si, idx4
	call check_stop_condition
	cmp stop, 1
	jz stop10

	ret

	; # changing related color values in board array 
	stop10:
		call change_color_values
	
	ret

endp shape_10


; purple_shape(+90 Degree) :   #
;				   			 # #
;				   			   #
shape_11 proc

	mov si, X
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #1
	call get_pos_in_array
	mov idx1, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #2
	call get_pos_in_array
	mov idx2, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #3
	call get_pos_in_array
	mov idx3, si	; idx : block position in board array

	mov si, x1
	sub si, len
	mov x1, si
	mov si, y1
	sub si, len
	mov y1, si
	call draw_block ; #4
	call get_pos_in_array
	mov idx4, si	; idx : block position in board array


	; check_stop_condition :

	mov si, X
	add si, len
	add si, len
	add si, len
	mov rb, si		; rb : #row of below block

	mov si, idx3
	call check_stop_condition
	cmp stop, 1
	jz stop11

	mov si, idx4
	call check_stop_condition
	cmp stop, 1
	jz stop11

	ret

	; # changing related color values in board array 
	stop11:
		call change_color_values
	
	ret

endp shape_11


; purple_shape(+180 Degree) :   #
;				   			  # # #
shape_12 proc

	mov si, X
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #1
	call get_pos_in_array
	mov idx1, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	mov si, y1
	sub si, len
	mov y1, si
	call draw_block ; #2
	call get_pos_in_array
	mov idx2, si	; idx : block position in board array

	mov si, y1
	add si, len
	mov y1, si
	call draw_block ; #3
	call get_pos_in_array
	mov idx3, si	; idx : block position in board array

	mov si, y1
	add si, len
	mov y1, si
	call draw_block ; #4
	call get_pos_in_array
	mov idx4, si	; idx : block position in board array


	; check_stop_condition :

	mov si, X
	add si, len
	add si, len
	mov rb, si		; rb : #row of below block

	mov si, idx2
	call check_stop_condition
	cmp stop, 1
	jz stop12

	mov si, idx3
	call check_stop_condition
	cmp stop, 1
	jz stop12

	mov si, idx4
	call check_stop_condition
	cmp stop, 1
	jz stop12

	ret

	; # changing related color values in board array 
	stop12:
		call change_color_values
	
	ret

endp shape_12


; purple_shape(-90 Degree) :   #
;				   			   # #
;				   			   #
shape_13 proc

	mov si, X
	mov x1, si
	mov si, Y
	mov y1, si
	call draw_block ; #1
	call get_pos_in_array
	mov idx1, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #2
	call get_pos_in_array
	mov idx2, si	; idx : block position in board array

	mov si, x1
	add si, len
	mov x1, si
	call draw_block ; #3
	call get_pos_in_array
	mov idx3, si	; idx : block position in board array

	mov si, x1
	sub si, len
	mov x1, si
	mov si, y1
	add si, len
	mov y1, si
	call draw_block ; #4
	call get_pos_in_array
	mov idx4, si	; idx : block position in board array


	; check_stop_condition :

	mov si, X
	add si, len
	add si, len
	add si, len
	mov rb, si		; rb : #row of below block

	mov si, idx3
	call check_stop_condition
	cmp stop, 1
	jz stop13

	mov si, idx4
	call check_stop_condition
	cmp stop, 1
	jz stop13

	ret

	; # changing related color values in board array 
	stop13:
		call change_color_values
	
	ret

endp shape_13


delay proc

	mov di, delay_times
	mov cx, delay_inner_counter

	label4:
		label3:
			call check_key_press
			loop label3

    dec di
	cmp di, 0
	jnz label4

	ret
endp delay
                                

proc check_stop_condition

	cmp rb, 180 		; reaching to end of board
	jge stop_moving

	add si, 40			; idx of below block in the board array
	cmp board[si], 0
	jnz stop_moving		 ; if color of below block is not the same as background color, then stop moving. Because it's filled below this shape.
	ret

	stop_moving:
		mov stop, 1

	ret
	


endp check_stop_condition


; input : x1, y1
; output : si register
get_pos_in_array proc

	mov si, x1
	sub si, 10		; because shape starts moving from 10th row

	; counting block position in array : 2 * ( (20*(x-10) + (y-10) ) / len)
	; {
		mov ax, si
		mov bx, 20 ; 20 : (300 / len) number of blocks in each row
		mul bx
		add ax, y1
		sub ax, 10	; because shape starts moving from 10th column

		mov bx, len
		div bx

		mov bx, 2
		mul bx
	; }

	mov si, ax
	ret

endp get_pos_in_array


change_color_values proc

	mov al, curr_color
	mov ah, 0

	mov si, idx1
	mov board[si], ax
	mov si, idx2
	mov board[si], ax
	mov si, idx3
	mov board[si], ax
	mov si, idx4
	mov board[si], ax

	ret

endp change_color_values


get_random_value proc

	mov ah, 2ch
	int 21h

	; bx keeps denominator and is set before
	; dl keeps 1/100 seconds
	mov dh, 0
	mov ax, dx         
	mov dx, 0   ; clearing dx
	div bx		; now dx keep the random value

	mov random_val, dx

	ret

endp get_random_value


check_filled_rows proc

	mov filled_rows, 0
	mov x1, 190 ; 165(X of most down block) + 10(margin) + len
	mov y1, 10	; 0 + 10(margin)
	mov di, 20

	next_row:
		cmp x1, 10
		jz board_checked

		mov ax, x1
		sub ax, len
		mov x1, ax
		
		call get_pos_in_array ; return : si
		mov di, 0

		next_idx:
			cmp board[si], 0  ; 0 : color of back ground
			jz next_row

			add si, 2
			inc di
			cmp di, 20	; 20 : number of blocks in a row
			jz score_label
			jmp next_idx
			

	score_label:
		inc filled_rows
		call shift_rows_down

		mov ax, x1
		add ax, len
		mov x1, ax
		jmp next_row
	
	board_checked:

	ret

endp check_filled_rows


shift_rows_down proc

	mov ax, x1
	mov xp, ax ; store x1
	mov ax, y1
	mov yp, ax ; store y1

	call get_pos_in_array	; return value : si
	add si, 38 			; index of most right block in current row
	mov y1, 295			; Y of left most block
	mov di, 0	; counter

	prev_idx:

		cmp di, 20
		jnz skip
		; setting X and Y in left most block and above row
		mov ax, x1
		sub ax, len
		mov x1, ax
		mov y1, 295	; left most block
		mov di, 0

		skip:

		mov bx, 0	; background color
		cmp si, 40
		jl set_color
		mov bx, board[si-40]	; color of above block

		set_color:
			mov board[si], bx	; set color

		mov curr_color, bl
		call draw_block
		
		cmp si, 0
		jz shift_done

		sub si, 2
		mov ax, y1
		sub ax, len
		mov y1, ax

		inc di
		jmp prev_idx

	shift_done:
		mov ax, xp
		mov x1, ax  ; restore x1
		mov ax, yp
		mov y1, ax  ; restore y1

	ret

endp shift_rows_down


get_x_y_from_idx proc

	; *len
	mov ax, si
	mov bx, len
	mul bx

	; /2
	mov bx, 2
	div bx

	mov bx, 20
	mov dx, 0	; clear dx
	div bx

	add ax, 10
	add dx, 10
	mov x1, ax
	mov y1, dx

	ret

endp get_x_y_from_idx


print_vars proc

	mov ax, si
	call show_number

	inc x_char
	mov ax, x1
	call show_number

	inc x_char
	mov ax, y1
	call show_number

	ret

endp print_vars


show_char proc

	mov dh, x_char	;Column	
	mov dl, y_char	;Row
	mov bh, 0    	;Display page
	mov ah, 02h  	;SetCursorPosition
	int 10h

	mov al, char
	mov bl, 12   	;Color is red
	mov bh, 0    	;Display page
	mov ah, 0Eh  	;Teletype
	int 10h

	ret

endp show_char


; print in decimal format
show_number proc          

	cmp ax, 0
	jnz not_zero
	mov char, '0'
	call show_char
	ret

	not_zero:
      
	; ax : (input) prining number
	mov cx, 0  ; set si reg as counter
	mov dx, 0  ; clear dx reg
		
	next_digit: 
			
		cmp ax,0 
		je print1 ; convertion is done. So print it
			
		; converting number from hex to decimal
		
		mov bx,10         
		div bx                   
	
		push dx                
		inc cx               
			
		sub dx, dx 
		jmp next_digit
		
			
	print1: 
		
		cmp cx,0 
		je print_done
			
		pop dx 
			
		add dx, 30h ; convert to ascii  
		mov char, dl
		call show_char
		inc y_char
	
		dec cx 
		jmp print1
		
			
	print_done:
		
		ret
         
endp show_number

end main