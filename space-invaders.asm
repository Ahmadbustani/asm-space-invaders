; constants

; GAME WINDOW PARAMETERS
%define GAME_WIDTH 27
%define GAME_HEIGHT 25

; GAME PARAMETERES
%define NUM_INVADERS 12
%define INVADERS_MOVE_CYCLES 40
%define INVADERS_SHOOT_CYCLES 4
%define BULLETS_MOVE_CYCLE 28

; SPECIAL CONSTANT
%define INVALID_STATE 0x0000

; ICONS
%define ICON_PLAYER 'M'
%define ICON_INVADER 'T'
%define ICON_BULLET '|'
%define ICON_EXPLOSION_BULLET '#'
%define ICON_WALL '#'

; GAME WINNERS
%define PLAYER_WIN 0
%define INVADERS_WIN 1

; PROGRAM STATES
%define PROGRAM_START_STATE 0
%define PROGRAM_GAME_STATE 1
%define PROGRAM_END_STATE 2

; PLAY KEYS
%define START_KEY ' '
%define RETRY_KEY 'r'
%define MOVE_LEFT_KEY 'a'
%define MOVE_RIGHT_KEY 'd'
%define SHOOT_KEY ' '

; MOVE DIRECTIONS
%define MOVE_UP 0
%define MOVE_RIGHT 1
%define MOVE_DOWN 2
%define MOVE_LEFT 3
%define MOVE_RESET 4

; BULLET
%define BULLET_STATUS_END_OF_LIST 0
%define BULLET_STATUS_EXPLOSION '#'
%define BULLET_STATUS_PLAYER 'p'
%define BULLET_STATUS_INVADER 'i'

%define BULLET_STATUS_OFFSET 0
%define BULLET_STATUS_SIZE 1
%define BULLET_POSITION_OFFSET BULLET_STATUS_OFFSET + BULLET_STATUS_SIZE
%define BULLET_POSITION_SIZE 2
%define BULLET_SIZE BULLET_POSITION_OFFSET + BULLET_POSITION_SIZE

; INVADER
%define INVADER_POSITION_OFFSET 0
%define INVADER_POSITION_SIZE 2
%define INVADER_SIZE INVADER_POSITION_OFFSET + INVADER_POSITION_SIZE

; clear the cursor blinking
mov	ah, 0x01
mov	cx, 0x2000
int 	0x10

; calculate game screen position
mov	ah, 0x0F
int	0x10 ; load the number of columns
sub byte ah, 1
sub ah, GAME_WIDTH
sar ah, 1
mov [display_offset], ah


jmp main

; include dependencies
%include "./src/keyboard.asm"
%include "./src/display.asm"
%include "./src/game.asm"

%include "./src/bullets.asm"
%include "./src/invaders.asm"
%include "./src/player.asm"
%include "./src/arena.asm"


; main loop
main:
  mov ah, [program_state]
  cmp ah, PROGRAM_GAME_STATE
  je .game
  cmp ah, PROGRAM_END_STATE
  je .end
.intro:
  call intro
  jmp main
.game:
  call game
  jmp main
.end:
  call end
  jmp main


; intro screen
intro:
  call clear_screen

  mov ax, intro_string_t
  mov bx, intro_string_o
  call print_window
.wait:
  call get_key
  mov al, [key_pressed]
  cmp al, START_KEY
  je .game
  jmp .wait
.game:
  mov byte [program_state], PROGRAM_GAME_STATE
  ret


; game loop
game:
  call init_game
.loop:

  ; check the current program state
  cmp byte [program_state], PROGRAM_GAME_STATE
  jne .done

  ; get key if available
  call check_key

  ; check the game state
  cmp word [player_pos], INVALID_STATE
  je .invaders
  ; check whether the player wins
  cmp byte [num_invaders_alive], 0
  je .player
  ; execute a game step
  jmp .execute
.invaders:
  mov byte [winner], INVADERS_WIN
  jmp .done
.player:
  mov byte [winner], PLAYER_WIN
  jmp .done
.execute:
  ; move
  call move_bullets
  call move_player
  call move_invaders

  ; render
  call clear_screen
  call render_arena
  call render_bullets
  call render_player
  call render_invaders

  ; render controlls
  mov dx, 0x0000
  mov si, left_string
  call print_string
  inc dh
  mov si, right_string
  call print_string
  inc dh
  mov si, shoot_string
  call print_string
.continue:
  mov cx, 0x0000  ; 0.05 seconds (cx:dx)
  mov dx, 0x1388  ; 0x00001388 = 5000
  call sleep
  jmp	.loop
.done:
  mov byte [program_state], PROGRAM_END_STATE
  ret


; end screen
end:
  cmp byte [winner], PLAYER_WIN
  je .player
  mov ax, end_string_l
  jmp .continue
.player:
  mov ax, end_string_w
.continue:
  mov bx, end_string_o
  call print_window
.wait:
  call get_key
  mov al, [key_pressed]
  cmp al, RETRY_KEY
  je .game
  jmp .wait
.game:
  mov byte [program_state], PROGRAM_GAME_STATE
  ret


; window
window_bar db "######################", 0
window_space db "#                    #", 0

; intro
intro_string_t db "#   SPACE INVADERS   #", 0
intro_string_o db "#   SPACE to start   #", 0

; end
end_string_w db "#    PLAYER  wins    #", 0
end_string_l db "#    INVADERS win    #", 0
end_string_o db "# Press R to restart #", 0

; controls
left_string db "A = move left", 0
right_string db "D = move right", 0
shoot_string db "SPACE = shoot", 0


; program state
; 0: start screen
; 1: game screen
; 2: end screen
program_state db 0

segment .bss
  ; display properties
  display_offset resb 1

  ; keyboard
  key_pressed resb 1

  ; game
  ; 0: player wins
  ; 1: invaders win
  winner resb 1

  ; player
  player_pos resw 1
  ; invaders
  invaders resw NUM_INVADERS
  num_invaders_alive resb 1
  invaders_move_direction resb 1
  invaders_move_cycle resb 1
  invaders_shoot_cycle resb 1
  ; bullets:  0x STATUS PY PX
  ; STATUS == 0: end of list
  ; STATUS == #: explosion
  ; STATUS == p: player bullet
  ; STATUS == i: invader bullet
  bullets_move_cycle resb 1
  bullet_list_end resw 1
  bullet_list resb 1
