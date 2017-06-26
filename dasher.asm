org   0x7c00
bits  16

start:
	; Setup registers and segments
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	
	; Setup stack
	mov sp, 0x0000
	mov bp, 0x7C00

	; Set up videomode (ah is 0x00 due to xor)
	mov al, 0x03; 80x25 colored VGA text videomode
	int 0x10

	; Disable a cursor
	mov ax, 0x103
	mov ch, 0x25
	int 0x10

	call load_level

loop:
	call draw
	call update

	push WORD 2
	push WORD 0 ; pushing 2 words takes lesser bytes than pushing 1 dword
	call sleep

	mov cx, [hero_pos]
	cmp cx, [finish_pos]
	jnz .endif
	call draw
	call end_level

	.endif:
	cmp [buffer], BYTE 0
	jz loop

	call input

	jmp loop

load_level:
	mov [delta_y], BYTE 0
	mov [delta_x], BYTE 0

	mov  bx, 0
	mov  bl, [current_level]
	imul bx, 12
	
	mov ax, [level+bx+8]
	mov [hero_pos], ax

	mov ax, [level+bx+10]
	mov [finish_pos], ax

	call draw
	call input
	call update	

	ret

draw:
	mov ch, 0 ; Row counter
	row_loop:
		cmp ch, 8
		jz row_end
		
		mov cl, 0 ; Column counter
		column_loop:
			cmp cl, 8
			jz column_end

			push cx
			call get_block_info
			push cx
			call move_cursor

			cmp [buffer], BYTE 0
			jnz .wall
			jz  .void

			.wall:
				push WORD '#'
				call draw_char
				jmp endif

			.void:
				push WORD ' '
				call draw_char
				jmp endif

			endif:

			inc cl
			jmp column_loop
		
		column_end:
		inc ch
		jmp row_loop
		

	row_end:

	; Drawing finish
	push WORD [finish_pos]
	call move_cursor
	push WORD '$'
	call draw_char

	; Drawing hero
	push WORD [hero_pos]
	call move_cursor
	push WORD '@'
	call draw_char

	ret

; Moves text cursor to specified coordinates
; input: 1 word - coordinates (y; x)
move_cursor:
	pop bx
	pop dx
	push bx

	mov bx, 0
	mov ah, 0x02
	int 0x10
	
	ret

; Writes to the buffer 0, if tile on specified coordinates is void, and anything else otherwise
; input: 1 word - coordinates (y; x)
get_block_info:
	pop bx
	pop cx
	push bx

	mov  bx, 0
	mov  bl, [current_level]
	imul bx, 12
	add  bl, ch

	mov dl, [level+bx] 

	mov bx, 1<<7
	shr bx, cl
	
	and dl, bl
	mov [buffer], dl
	
	ret

; Outputs a character at current cursor position
; Separate subprograms for all characters aren't given due to an overhead
; input: 1 word - character (high byte is 0x00, and low byte is a ascii code)
draw_char:
	pop bx
	pop ax
	push bx

	mov ah, 0x0e
	int 0x10

	ret

update:
	mov cx, [hero_pos]
	add ch, [delta_y]
	add cl, [delta_x]

	push cx
	call get_block_info

	cmp [buffer], BYTE 0
	jnz .stop
	
	mov [hero_pos], cx
	
	jmp .out
	.stop:
		mov [delta_y], BYTE 0
		mov [delta_x], BYTE 0
	.out:

	ret

; Sleeps for specified time
; input: 2 words - amount of microseconds, 
sleep:
	pop bx
	pop dx
	pop cx
	push bx

	mov ah, 0x86
	int 0x15

	ret
		

input:
	mov ah, 0
	int 0x16
	
	cmp ah, 0x11 ; 'W'
	jz up_pressed
	
	cmp ah, 0x1e ; 'A'
	jz left_pressed

	cmp ah, 0x1f ; 'S'
	jz down_pressed

	cmp ah, 0x20 ; 'D'
	jnz _endif

	right_pressed:
		mov [delta_x], BYTE 1
		mov [delta_y], BYTE 0
		jmp _endif

	up_pressed:
		mov [delta_x], BYTE 0
		mov [delta_y], BYTE -1
		jmp _endif

	left_pressed:
		mov [delta_x], BYTE -1
		mov [delta_y], BYTE 0
		jmp _endif

	down_pressed:
		mov [delta_x], BYTE 0
		mov [delta_y], BYTE 1
		jmp _endif

	_endif:
	ret

end_level:
	add [current_level], BYTE 1
	mov bl, [current_level]

	cmp bl, [level_count]
	jnz .endif

	push WORD 0
	call move_cursor
	jmp win

	.endif:
	call load_level
	ret

win:
	push WORD '$'
	call draw_char

	push WORD 0
	push WORD 16384
	call sleep

	jmp win

; Levels' layouts 8x8 (0 - void, 1 - wall), 2 bytes for start pos, 2 bytes for finish pos
; Can't mark the start/end of level layout with commentary, because NASM throws an error
level db 11111111b,\
         10000001b,\
         10000001b,\
         10000001b,\
         10000001b,\
         10000001b,\
         10000001b,\
         11111111b,\
         1, 1, 6, 6,\
         11111111b,\
         10000001b,\
         11111101b,\
         11100001b,\
         10001001b,\
         10001001b,\
         10001001b,\
         11111111b,\
         1, 1, 1, 4,\
         11111111b,\
         10000011b,\
         11010001b,\
         11000101b,\
         10000001b,\
         10101001b,\
         10001001b,\
         11111111b,\
         1, 1, 2, 2,\
         11111111b,\
         10010001b,\
         10000101b,\
         11011101b,\
         10000101b,\
         10010001b,\
         11010001b,\
         11111111b,\
         2, 6, 1, 5

level_count db 4
current_level db 0

hero_pos dw 0x0101
finish_pos dw 0x0601

; Currrent velocity on x- and y-axes
delta_x db 0
delta_y db 0

buffer db 0 ; Mainly used for saving an block info

; PADDING AND SIGNATURE
times 510-($-$$) db 0
db    0x55, 0xaa
