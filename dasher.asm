org   0x7c00
bits  16

sizeof_level equ 36 ; size of level in bytes
levels_count equ (levels_end-levels)/sizeof_level

green equ 2
red equ 4
yellow equ 14

start:
	; Setup registers and segments
	xor ax, ax
	mov ds, ax
	mov ss, ax

	; Setup stack
	mov sp, 0x7c00
	mov bp, sp

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
	jnz short .endif
	.on_finish:
		call draw
		call end_level
	.endif:
	cmp [buffer], BYTE 0
	jz short loop

	call input

	jmp short loop

load_level:
	mov [delta_y], BYTE 0
	mov [delta_x], BYTE 0

	mov  bx, 0
	mov  bl, [current_level]
	imul bx, sizeof_level

	mov ax, [levels+bx+(sizeof_level-4)]
	mov [hero_pos], ax

	mov ax, [levels+bx+(sizeof_level-2)]
	mov [finish_pos], ax

	call draw
	call input
	ret

draw:
	mov ch, 0 ; Row counter
	.row_loop:
		cmp ch, 16
		jz short .row_end

		mov cl, 0 ; Column counter
		.column_loop:
			cmp cl, 16
			jz short .column_end

			push cx
			call get_block_info
			push cx
			call move_cursor

			cmp [buffer], BYTE 0
			jz short  .void

			.wall:
				push WORD (green<<8 | '#')
				jmp short .endif
			.void:
				push WORD ' '
			.endif:
			call draw_char

			inc cl
			jmp short .column_loop

		.column_end:
		inc ch
		jmp short .row_loop
	.row_end:

	; Drawing finish
	push WORD [finish_pos]
	call move_cursor
	push WORD (yellow<<8 | '$')
	call draw_char

	; Drawing hero
	push WORD [hero_pos]
	call move_cursor
	push WORD (red<<8 | '@')
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

	push cx

	; Compute an offset from the start of the levels data
	mov bx, 0
	mov bl, [current_level]
	imul bx, sizeof_level ; now BX stores an offset from the start of a level
	shl ch, 1 ; as every row occupies 2 bytes, we should multiply it

	xor ax, ax ; clear AX
	mov al, ch ; "byte to word"

	add bx,ax

	; Get one row, things are getting tricky here
	cmp cl, 8
	jnge short .endif ; if CL<8
	.if_greater_or_equals:
		inc bx
	.endif:
	mov dl, [levels+bx]

	jnge short .endif_2 ; if CL<8
	.if_greater_or_equals_2:
		dec bx
		sub cl, 8 ; CL = CL MOD 8
	.endif_2:

	mov bx, 1<<7
	shr bx, cl

	and dl, bl
	mov [buffer], dl

	pop cx

	ret

; Outputs a character at current cursor position
; Separate subprograms for all characters aren't given due to an overhead
; input: 1 word - character (high byte is color, and low byte is an ascii code)
draw_char:
	pop bx
	pop ax
	push bx

	push cx

	mov bl, ah
	mov ah, 0x09
	mov cx, 1
	mov bh, 0
	int 0x10

	pop cx

	ret

update:
	mov cx, [hero_pos]
	add ch, [delta_y]
	add cl, [delta_x]

	push cx
	call get_block_info

	cmp [buffer], BYTE 0
	jz short .is_void
	.is_block:
		mov [delta_y], BYTE 0
		mov [delta_x], BYTE 0

		jmp .endif
	.is_void:
		mov [hero_pos], cx
	.endif:

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
	.loop:
	; Blocking keyboard input
	mov ah, 0
	int 0x16

	cmp ah, 0x48 ; Up arrow
	jz short .up_pressed

	cmp ah, 0x4b ; Left arrow
	jz short .left_pressed

	cmp ah, 0x50 ; Down arrow
	jz short .down_pressed

	cmp ah, 0x4d ; Right arrow
	jnz short .loop

	.right_pressed:
		mov [delta_x], BYTE 1
		mov [delta_y], BYTE 0
		jmp short .endif

	.up_pressed:
		mov [delta_x], BYTE 0
		mov [delta_y], BYTE -1
		jmp short .endif

	.left_pressed:
		mov [delta_x], BYTE -1
		mov [delta_y], BYTE 0
		jmp short .endif

	.down_pressed:
		mov [delta_x], BYTE 0
		mov [delta_y], BYTE 1
		jmp short .endif

	.endif:
	ret

end_level:
	inc BYTE [current_level]
	mov bl, [current_level]

	cmp bl, levels_count
	jnz short .endif

	push WORD 0
	call move_cursor
	jmp short win

	.endif:
	call load_level
	ret

win:
	xor si, si
	.win_loop:
		mov ah, 0x0e
		mov al, '$'
		int 0x10

		push WORD 0
		push WORD 16384
		call sleep

		jmp short .win_loop

; Levels' layouts 8x8 (0 - void, 1 - wall), 2 bytes for start pos, 2 bytes for finish pos
levels:
db 11111111b, 11111111b
db 10110000b, 00000011b
db 10100000b, 00000001b
db 10100000b, 00000001b
db 10100000b, 00000001b
db 10100000b, 00000001b
db 10100000b, 00000001b
db 10100000b, 00000001b
db 10100000b, 00000001b
db 10100000b, 00000101b
db 10111000b, 00000101b
db 10000000b, 00000101b
db 10100000b, 00000101b
db 10110000b, 00111101b
db 10000000b, 00000001b
db 11111111b, 11111111b
db 1, 1
db 2, 11

db 11111111b, 11111111b
db 10010000b, 00000001b
db 10000001b, 00000101b
db 11011111b, 11111101b
db 11000000b, 01000001b
db 10010111b, 01110001b
db 10010100b, 00010001b
db 10010101b, 01000011b
db 10010101b, 00010001b
db 10010101b, 11010001b
db 10010100b, 00010001b
db 10010111b, 11110001b
db 10010000b, 00000001b
db 10011110b, 10110001b
db 10000010b, 00000001b
db 11111111b, 11111111b
db 8, 8
db 14, 8
levels_end:

current_level db 0

hero_pos dw 0
finish_pos dw 0

; Currrent velocity on x- and y-axes
delta_x db 0
delta_y db 0

buffer db 0 ; Mainly used for saving an block info

; PADDING AND SIGNATURE
times 510-($-$$) db 0
db    0x55, 0xaa
