org   0x7c00
bits  16

start:
	; Setup registers and segments
	xor ax, ax
	mov ds, ax
	mov es, ax
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
	.row_loop:
		cmp ch, 8
		jz short .row_end

		mov cl, 0 ; Column counter
		.column_loop:
			cmp cl, 8
			jz short .column_end

			push cx
			call get_block_info
			push cx
			call move_cursor

			cmp [buffer], BYTE 0
			jnz short .wall
			jz short  .void

			.wall:
				push WORD '#'
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

	; Compute an offset from the start of the levels data
	mov  bx, 0
	mov  bl, [current_level]
	imul bx, 12
	add  bl, ch

	; Get one row
	mov dl, [level+bx]

	mov bx, 1<<7
	shr bx, cl

	and dl, bl
	mov [buffer], dl

	ret

; Outputs a character at current cursor position
; Separate subprograms for all characters aren't given due to an overhead
; input: 1 word - character (high byte is 0x00, and low byte is an ascii code)
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

	cmp bl, [level_count]
	jnz short .endif

	push WORD 0
	call move_cursor
	jmp short win

	.endif:
	call load_level
	ret

win:
	push WORD '$'
	call draw_char

	push WORD 0
	push WORD 16384
	call sleep

	jmp short win

; Levels' layouts 8x8 (0 - void, 1 - wall), 2 bytes for start pos, 2 bytes for finish pos
level:
db 11111111b
db 10000001b
db 10000001b
db 10000001b
db 10000001b
db 10000001b
db 10000001b
db 11111111b
db 1, 1
db 6, 6

db 11111111b
db 10000001b
db 11111101b
db 11100001b
db 10001001b
db 10001001b
db 10001001b
db 11111111b
db 1, 1
db 1, 4

db 11111111b
db 10000011b
db 11011001b
db 11000101b
db 10000001b
db 10101001b
db 10001001b
db 11111111b
db 1, 1
db 2, 2

level_count db 3
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
