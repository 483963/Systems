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
	push	bx
	push	cx
	push 	dx

	mov		ax, [di]				; x0
	cmp		ax, 320
	jae		setPixel_ext
	mov		ax, [di + 2]			; y0
	cmp		ax, 200
	jae		setPixel_ext
	
	mov		al, [di + 4]
	mov		ah, 0Ch
	xor		bx, bx
	mov		cx, [di]
	mov		dx, [di + 2]
	int 	10h
	
setPixel_ext:
	pop		dx
	pop 	cx
	pop		bx
	pop		ax
	pop		di
	retn	6

;----------------------------------------------------------------------------------
;ax - x0, cx - y0, dx - x1, bx - y1, bp - color
drawline:
	push	bp
	push	bx
	push	dx
	push	cx
	push	ax
	mov		si, sp
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
	add		sp, 14
	ret		
	
	
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
	
	mov		bp, 11				; color	
	mov		bx, 110				; y1	
	mov		dx, 200				; x1
	mov		cx, 90				; y0
	mov		ax, 160				; x0
	call	drawline

	mov		bp, 1				; color	
	mov		bx, 120				; y1	
	mov		dx, 200				; x1
	mov		cx, 100				; y0
	mov		ax, 160				; x0
	call	drawline
	
	mov		bp, 2				; color	
	mov		bx, 130				; y1	
	mov		dx, 200				; x1
	mov		cx, 110				; y0
	mov		ax, 160				; x0
	call	drawline
	
	mov		bp, 3				; color	
	mov		bx, 140				; y1	
	mov		dx, 200				; x1
	mov		cx, 120				; y0
	mov		ax, 160				; x0
	call	drawline
	
	mov		bp, 4				; color	
	mov		bx, 150				; y1	
	mov		dx, 200				; x1
	mov		cx, 130				; y0
	mov		ax, 160				; x0
	call	drawline
	
	mov		bp, 5				; color	
	mov		bx, 160				; y1	
	mov		dx, 200				; x1
	mov		cx, 140				; y0
	mov		ax, 160				; x0
	call	drawline
	
	mov		bp, 6				; color	
	mov		bx, 170				; y1	
	mov		dx, 200				; x1
	mov		cx, 150				; y0
	mov		ax, 160				; x0
	call	drawline
	
	mov		bp, 7				; color	
	mov		bx, 180				; y1	
	mov		dx, 200				; x1
	mov		cx, 160				; y0
	mov		ax, 160				; x0
	call	drawline
	
	mov		bp, 8				; color	
	mov		bx, 190				; y1	
	mov		dx, 200				; x1
	mov		cx, 170				; y0
	mov		ax, 160				; x0
	call	drawline
	
	mov		bp, 10				; color	
	mov		bx, 200				; y1	
	mov		dx, 200				; x1
	mov		cx, 180				; y0
	mov		ax, 160				; x0
	call	drawline
	
endloop:
	jmp		endloop

second_stage_msg	db 'Second stage loaded', 0

	times 3584-($-$$) db 0	