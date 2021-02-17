; Second stage of the boot loader

BITS 16

ORG 9000h
	jmp 	Second_Stage

%include "functions_16.asm"

;	Start of the second stage of the boot loader
;----------------------------------------------------------------------------------
; input:  ax
; output: ax
make_abs:
	test	ax, 0x8000
	jz		make_abs_ext
	not		ax
	inc		ax
make_abs_ext:
	ret
	
;----------------------------------------------------------------------------------
;stack arg0 - x0, arg1 - y0, arg2 - colour
setPixel:
	push	di
	mov		di, sp
	lea		di, [di + 4]			; get pointer to args
	push	ax
	push 	dx
	mov		ax, [di]				; x0
	cmp		ax, 320
	jae		setPixel_ext
	mov		ax, [di + 2]			; y0
	cmp		ax, 200
	jae		setPixel_ext
	mov		dx, 320					
	mul		dx						; get row address 
	add		ax, [di]				; add  x0 offset
	mov		dx, [di + 4]			; color
	xchg	dx, ax
	mov		di, dx
	stosb
setPixel_ext:
	pop		dx
	pop 	ax
	pop		di
	retn	6

;----------------------------------------------------------------------------------
;stack arg0 - x0, arg1 - y0, arg2 - x1, arg3 - y1, arg4 - color
drawline:
	push	si
	mov		si, sp
	lea		si, [si + 4]			; get pointer to args
	push	ax
	push	dx
	push	bx
	push 	cx
	push	di
	
	;dx := abs(x1 - x0)
	mov		ax, [si + 4]			; x1
	sub		ax, [si]				; x0
	call	make_abs
	mov		dx, ax
	
	;dy := abs(y1 - y0)
	mov		ax, [si + 6]			; y1
	sub		ax, [si + 2]			; y0
	call	make_abs
	mov		bx, ax
	neg		bx
	
	mov		cx, 1
	mov		ax, [si]				; x0
	cmp		ax, [si + 4]			; x1
	jbe		drawline_x1
	mov		cx, -1
drawline_x1:
	push	cx						; sx stack 0
	mov		cx, 1
	mov		ax, [si + 2]			; y0
	cmp		ax, [si + 6]			; y1
	jbe		drawline_y1
	mov		cx, -1
drawline_y1:
	push	cx						; sy stack 2
	mov		cx, dx
	add		cx, bx 					; err := dx +(- dy) 
	mov		di, sp
	
drawline_loop:	
	mov		ax,	[si + 8]			; color
	push	ax
	mov		ax,	[si + 2]			; y0
	push	ax
	mov		ax, [si]				; x0
	push	ax
	call	setPixel
	
	; if x0 = x1 and y0 = y1 
	mov		ax, [si]				; x0
	cmp		ax, [si + 4]			; x1
	jnz		drawline_c
	mov		ax, [si + 2]			; y0
	cmp		ax, [si + 6]			; y1
	jz		drawline_ext
drawline_c:	
	; e2 := 2 * err
	mov		ax, cx
	shl		ax, 1
	; if e2 > -dy then    
	cmp		ax, bx
	jle		drawline_c1
	; err := err - dy  
	add		cx, bx
	; x0 := x0 + sx   
	mov		ax, [di]
	add		[si], ax
	jmp		drawline_loop
	; end if 
	
drawline_c1:
	;if e2 < dx then 
	cmp		ax, dx
	jge		drawline_loop
	; err := err + dx  
	add		cx, dx
	; y0 := y0 + sy  
	mov		ax, [di + 2]
	add		[si + 2], ax			; y0
	jmp		drawline_loop
	; end if  

drawline_ext:
	pop		ax
	pop		ax
	pop		di
	pop		cx
	pop		bx
	pop		dx
	pop		ax
	pop		si
	retn	10		
	
	
	;function drawline(x0, y0, x1, y1, colour)    
	;dx := abs(x1 - x0)    ;dx
	;dy := abs(y1 - y0)    ;bx 
	;if x0 < x1 then sx := 1 else sx := -1 ;stack 2
	;if y0 < y1 then sy := 1 else sy := -1 ;stack 0
	;err := dx - dy        ;cx
	;loop      
	;	setPixel(x0, y0, colour)      
	;	if x0 = x1 and y0 = y1 
	;		exit loop      
	;	
	;	e2 := 2 * err      
	;	if e2 > -dy then         
	;		err := err - dy        
	;		x0 := x0 + sx      
	;	end if      
	;	if e2 < dx then         
	;		err := err + dx        
	;		y0 := y0 + sy       
	;	end if    
	;end loop 
		
;----------------------------------------------------------------------------------
;stack arg0 - x0, arg1 - y0, arg2 - width, arg3 - height, arg4 - color
draw_rectangle:
	push	si
	mov		si, sp
	lea		si, [si + 4]			; get pointer to args
	push	ax
	push	cx
	
	mov		ax, [si]
	add		[si + 4], ax
	
	mov		cx, [si + 6]
	
draw_rectangle_nxt:
	
	mov		ax, [si + 8]	; color	
	push	ax				
	mov		ax, [si + 2]	; y1
	push	ax
	mov		ax, [si + 4]	; x1
	push	ax
	mov		ax, [si + 2]	; y0
	push	ax		
	mov		ax, [si]		; x0
	push	ax
	call	drawline	
	
	mov		ax, [si + 2]	; y0++, y1++
	inc		ax
	mov 	[si + 2], ax		
	dec 	cx
	jnz		draw_rectangle_nxt
	
	pop		cx
	pop		ax
	pop		si
	retn	10
	
;----------------------------------------------------------------------------------
;stack arg0 - xc, arg1 - yc, arg2 - x, arg3 - y, arg4 - color
drawCircle_part:
	push	si
	mov		si, sp
	lea		si, [si + 4]			; get pointer to args
	push	ax
	
	; setpixel(xc + x, yc + y, color); 
	mov		ax, [si + 8]	; color
	push	ax				
	mov		ax, [si + 2]	; yc
	add		ax, [si + 6]	; y
	push	ax				
	mov		ax, [si]		; xc
	add		ax, [si + 4]	; x
	push	ax				
	call 	setPixel
	
	; setpixel(xc - x, yc + y, color);
	mov		ax, [si + 8]	; color
	push	ax				
	mov		ax, [si + 2]	; yc
	add		ax, [si + 6]	; y
	push	ax				
	mov		ax, [si]		; xc
	sub		ax, [si + 4]	; x
	push	ax				
	call 	setPixel
	; setpixel(xc + x, yc - y, color); 
	mov		ax, [si + 8]	; color
	push	ax				
	mov		ax, [si + 2]	; yc
	sub		ax, [si + 6]	; y
	push	ax				
	mov		ax, [si]		; xc
	add		ax, [si + 4]	; x
	push	ax				
	call 	setPixel
	; setpixel(xc - x, yc - y, color); 
	mov		ax, [si + 8]	; color
	push	ax				
	mov		ax, [si + 2]	; yc
	sub		ax, [si + 6]	; y
	push	ax				
	mov		ax, [si]		; xc
	sub		ax, [si + 4]	; x
	push	ax				
	call 	setPixel
	; setpixel(xc + y, yc + x, color); 
	mov		ax, [si + 8]	; color
	push	ax				
	mov		ax, [si + 2]	; yc
	add		ax, [si + 4]	; x
	push	ax				
	mov		ax, [si]		; xc
	add		ax, [si + 6]	; y
	push	ax				
	call 	setPixel
	; setpixel(xc - y, yc + x, color);
	mov		ax, [si + 8]	; color
	push	ax				
	mov		ax, [si + 2]	; yc
	add		ax, [si + 4]	; x
	push	ax				
	mov		ax, [si]		; xc
	sub		ax, [si + 6]	; y
	push	ax				
	call 	setPixel
	; setpixel(xc + y, yc - x, color);
	mov		ax, [si + 8]	; color
	push	ax				
	mov		ax, [si + 2]	; yc
	sub		ax, [si + 4]	; x
	push	ax				
	mov		ax, [si]		; xc
	add		ax, [si + 6]	; y
	push	ax				
	call 	setPixel
	; setpixel(xc - y, yc - x, color); 
	mov		ax, [si + 8]	; color
	push	ax				
	mov		ax, [si + 2]	; yc
	sub		ax, [si + 4]	; x
	push	ax				
	mov		ax, [si]		; xc
	sub		ax, [si + 6]	; y
	push	ax				
	call 	setPixel

	pop		ax
	pop		si
	retn 	10


;----------------------------------------------------------------------------------	
;stack arg0 - xc, arg1 - yc, arg2 - r, arg3 - color
drawCircle:
	push	si
	mov		si, sp
	lea		si, [si + 4]			; get pointer to args
	push	ax
	push	dx						; x
	push	bx						; y
	push	cx						; d
	 
	xor		dx, dx					; x = 0
	mov		bx, [si + 4]			; y = r; 
	
	mov		ax, bx
	shl		ax, 1
	mov		cx, 3
	sub 	cx, ax					; d = 3 - 2 * r; 
	
	; drawCircle_part(xc, yc, x, y, color); 
	mov		ax, [si + 6]			; color
	push	ax
	push	bx						; y
	push	dx						; x
	mov		ax, [si + 2]			; yc
	push	ax
	mov		ax, [si]				; xc
	push	ax
	call	drawCircle_part
	
drawCircle_while:
	cmp		bx, dx
	jl		drawCircle_ext
	
	inc		dx						; x++
	cmp		cx, 0
	jl		drawCircle_c
	dec		bx						; y--
	mov		ax, dx
	sub		ax, bx					; (x - y)
	shl		ax, 2					; 4 * (x - y)
	add		cx, ax					; d + 4 * (x - y
	add		cx, 10					; d = d + 4 * (x - y) + 10
	jmp		drawCircle_c1
drawCircle_c:
	mov		ax, dx
	shl		ax, 2					; 4 * x
	add		cx, ax					; d + 4 * x
	add		cx, 6					; d = d + 4 * x + 6
drawCircle_c1:

	; drawCircle_part(xc, yc, x, y, color); 
	mov		ax, [si + 6]			; color
	push	ax
	push	bx						; y
	push	dx						; x
	mov		ax, [si + 2]			; yc
	push	ax
	mov		ax, [si]				; xc
	push	ax
	call	drawCircle_part
	
	jmp		drawCircle_while
drawCircle_ext:		
	pop		cx
	pop		bx
	pop		dx
	pop		ax
	pop		si
	retn 	8

;----------------------------------------------------------------------------------	
	
Second_Stage:
    mov 	si, second_stage_msg	; Output our greeting message
    call 	Console_WriteLine_16

	; Put your test code here

	; This never-ending loop ends the code.  It replaces the hlt instruction
	; used in earlier examples since that causes some odd behaviour in 
	; graphical programs.
	
	; enable vga mode 13h, 320x200x8 bit
	push	13h
	pop		ax
	int		10h
	
	;assign es:di as video memory 0x0A0000
	mov		ax, 0A000h
	mov		es, ax

	push	2				; color	
	push	45				; y1
	push	200				; x1
	push	4				; y0
	push	70				; x0
	call	drawline
	
	push	11				; color	
	push	45				; y1
	push	30				; x1
	push	4				; y0
	push	4				; x0
	call 	draw_rectangle
	
	;stack arg0 - xc, arg1 - yc, arg2 - r, arg3 - color
	push	12				; color	
	push	15				; color	
	push	35				; y0
	push	70				; x0	
	call	drawCircle
	
endloop:
	jmp		endloop

second_stage_msg	db 'Second stage loaded', 0

	times 3584-($-$$) db 0	