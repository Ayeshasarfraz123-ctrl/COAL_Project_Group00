; ============================================================
; MARIO.ASM - Super Mario Engine (x86, NASM, DOSBox)
; Platform game: tiles, sprites, enemies, interrupts, states
; ============================================================
[org 0x0100]

; ------------------------------------------------------------
; CONSTANTS (EQU): no bytes are produced, they are only names
; ------------------------------------------------------------
SCREEN_W        equ 320
SCREEN_H        equ 200
MAP_PIXEL_H     equ 192         ; map is 12 rows x 16 pixels
CAMERA_FOLLOW   equ 160         ; camera follows Mario past this screen x
CAMERA_MAX      equ 640         ; last camera position
LEVEL_RIGHT_X   equ 944         ; right end of the level for Mario
START_LIVES     equ 3
MAX_LIVES       equ 99
LEVEL_TIME      equ 300
INVULN_FRAMES   equ 60

SC_ESC          equ 0x01
SC_ENTER        equ 0x1c
SC_P            equ 0x19
SC_SPACE        equ 0x39
SC_LSHIFT       equ 0x2a
SC_RSHIFT       equ 0x36
SC_LEFT         equ 0x4b
SC_RIGHT        equ 0x4d
SC_UP           equ 0x48
SC_DOWN         equ 0x50
SC_T            equ 0x14
SC_C            equ 0x2e
SC_F            equ 0x21

WALK_ACCEL      equ 0x0020
FRICTION        equ 0x0010
WALK_MAX        equ 0x0180
RUN_MAX         equ 0x0280
MAX_FALL        equ 0x0400
JUMP_SPEED      equ 0xFA80
JUMP_CUTOFF     equ 0xFE00
                jmp start
; ------------------------------------------------------------
; DATA
; ------------------------------------------------------------
; --- hero data ---
; --- score and clock data ---
score_lo:       dw 0
score_hi:       dw 0
coins:          dw 0
lives:          dw 3
game_time:      dw 300

; --- tile colours, one byte per tile code (0 to 12) ---
tilecolour:     db 9,6,4,14,14,8,2,2,2,2,7,9,9

; --- ORIGINAL MAP: 60 columns x 12 rows, never changed ---
; each line below = 10 columns, each row = 6 lines
originalmap:
; row 0 (HUD)
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
; row 1
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
; row 2
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,12,0,0
; row 3
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,12,0,0
; row 4
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,12,0,0
; row 5
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,12,0,0
; row 6
                db 0,0,0,0,0,0,0,0,4,0
                db 3,0,0,2,3,2,3,2,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 2,4,2,2,2,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,10,0,0,0,12,0,0
; row 7
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,11,11,11,11,0,0,0,0,0
                db 0,0,0,0,0,6,7,0,0,0
                db 0,11,11,11,0,0,0,0,0,0
                db 0,0,10,10,0,0,0,12,0,0
; row 8
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,6,7
                db 0,0,0,0,0,8,9,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,10,10,10,0,0,0,12,0,0
; row 9 (Mario stands here)
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 0,0,0,0,0,11,11,11,8,9
                db 0,0,0,0,0,8,9,0,0,0
                db 0,0,0,0,0,0,0,0,0,0
                db 10,10,10,10,0,0,0,10,0,0
; row 10 (ground)
                db 1,1,1,1,1,1,1,1,1,1
                db 1,1,1,1,1,1,1,1,1,1
                db 1,1,0,0,1,1,1,1,1,1
                db 1,1,1,1,1,1,1,1,1,1
                db 1,0,0,0,1,1,1,1,1,1
                db 1,1,1,1,1,1,1,1,1,1
; row 11 (ground)
                db 1,1,1,1,1,1,1,1,1,1
                db 1,1,1,1,1,1,1,1,1,1
                db 1,1,0,0,1,1,1,1,1,1
                db 1,1,1,1,1,1,1,1,1,1
                db 1,0,0,0,1,1,1,1,1,1
                db 1,1,1,1,1,1,1,1,1,1

; --- WORKING MAP: copy of the original, changed during play ---
workmap:        times 720 db 0

; --- where drawing goes (frame buffer segment, set in start) ---
drawseg:        dw 0xa000

; --- frame buffer segment (set in start) ---
bufseg:         dw 0

; --- keyboard: 128-byte key-state table (1 = held) ---
keystate:       times 128 db 0

; --- saved old keyboard vector (offset, segment) ---
oldkb_off:      dw 0
oldkb_seg:      dw 0

; --- 1 if the last keyboard byte was the E0 prefix ---
kb_e0:          db 0

; --- timer: tick counter, old vector, clock ---
tickcount:      dw 0
bios_accum:     dw 0            ; preserves the normal BIOS clock rate
oldtm_off:      dw 0
oldtm_seg:      dw 0
tickpersec:     dw 0

; --- hero (Mario) data ---
; position = whole pixels (word) + fraction (0 to 255)
; speed = 8.8 fixed point, signed (high byte = pixels, low byte = fraction)
hero_x:         dw 32
hero_xf:        dw 0
hero_y:         dw 160          ; y of the FEET
hero_yf:        dw 0
hero_vx:        dw 0
hero_vy:        dw 0
on_ground:      dw 1
facing:         dw 0            ; 0 = right, 1 = left
space_prev:     dw 0            ; 1 if Space was held in the last frame

; --- camera: world x of the left edge of the screen ---
camera_x:       dw 0

; --- hero hitbox height (16 = small Mario, 32 = Super Mario later) ---
hero_h:         dw 16

; --- combat data ---
hero_prevy:     dw 0
invuln:         dw 0            ; invulnerability frames left
stomp_chain:    dw 0            ; stomps since last landing
chaintab:       dw 100,200,400,500,800,1000,2000,4000,5000,8000

; enemy record = 8 words (16 bytes):
; +0 type (0 none, 1 goomba, 2 koopa)
; +2 state (0 waiting, 1 walking, 2 flat goomba, 3 still shell, 4 sliding shell)
; +4 x, +6 y (top), +8 direction (1 or -1), +10 timer, +12 x fraction, +14 vy
enemies_orig:   dw 1,0,224,144,-1,0,0,0
                dw 1,0,304,144,-1,0,0,0
                dw 1,0,416,144,-1,0,0,0
                dw 2,0,512,144,-1,0,0,0
                dw 1,0,540,144,-1,0,0,0
                dw 2,0,736,144,-1,0,0,0
enemies:        times 96 db 0

; --- mushroom (one at a time) ---
mush_on:        dw 0
mush_x:         dw 0
mush_y:         dw 0
mush_dir:       dw 1            ; 1 = right, -1 = left
mush_vy:        dw 0

; --- coin popping out of a block ---
pop_on:         dw 0
pop_x:          dw 0
pop_y:          dw 0
pop_t:          dw 0

; --- 8x8 digit pictures, 0 to 9 ---
digitfont:      db 0x3C,0x66,0x6E,0x76,0x66,0x66,0x3C,0x00
                db 0x18,0x38,0x18,0x18,0x18,0x18,0x7E,0x00
                db 0x3C,0x66,0x06,0x0C,0x18,0x30,0x7E,0x00
                db 0x3C,0x66,0x06,0x1C,0x06,0x66,0x3C,0x00
                db 0x0C,0x1C,0x3C,0x6C,0x7E,0x0C,0x0C,0x00
                db 0x7E,0x60,0x7C,0x06,0x06,0x66,0x3C,0x00
                db 0x3C,0x60,0x7C,0x66,0x66,0x66,0x3C,0x00
                db 0x7E,0x06,0x0C,0x18,0x30,0x30,0x30,0x00
                db 0x3C,0x66,0x66,0x3C,0x66,0x66,0x3C,0x00
                db 0x3C,0x66,0x66,0x3E,0x06,0x0C,0x38,0x00
                db 0x18,0x3C,0x66,0x66,0x7E,0x66,0x66,0x00   ; A (10)
                db 0x7C,0x66,0x66,0x7C,0x66,0x66,0x7C,0x00   ; B
                db 0x3C,0x66,0x60,0x60,0x60,0x66,0x3C,0x00   ; C
                db 0x78,0x6C,0x66,0x66,0x66,0x6C,0x78,0x00   ; D
                db 0x7E,0x60,0x60,0x7C,0x60,0x60,0x7E,0x00   ; E
                db 0x7E,0x60,0x60,0x7C,0x60,0x60,0x60,0x00   ; F
                db 0x3C,0x66,0x60,0x6E,0x66,0x66,0x3E,0x00   ; G
                db 0x66,0x66,0x66,0x7E,0x66,0x66,0x66,0x00   ; H
                db 0x3C,0x18,0x18,0x18,0x18,0x18,0x3C,0x00   ; I
                db 0x60,0x60,0x60,0x60,0x60,0x60,0x7E,0x00   ; L
                db 0x63,0x77,0x7F,0x6B,0x63,0x63,0x63,0x00   ; M
                db 0x66,0x76,0x7E,0x7E,0x6E,0x66,0x66,0x00   ; N
                db 0x3C,0x66,0x66,0x66,0x66,0x66,0x3C,0x00   ; O
                db 0x7C,0x66,0x66,0x7C,0x60,0x60,0x60,0x00   ; P
                db 0x7C,0x66,0x66,0x7C,0x6C,0x66,0x66,0x00   ; R
                db 0x3C,0x66,0x60,0x3C,0x06,0x66,0x3C,0x00   ; S
                db 0x7E,0x18,0x18,0x18,0x18,0x18,0x18,0x00   ; T
                db 0x66,0x66,0x66,0x66,0x66,0x66,0x3C,0x00   ; U
                db 0x66,0x66,0x66,0x66,0x66,0x3C,0x18,0x00   ; V
                db 0x63,0x63,0x63,0x6B,0x7F,0x77,0x63,0x00   ; W (29)
                db 0x00,0x00,0x66,0x3C,0x18,0x3C,0x66,0x00   ; x (30)
                db 0x00,0x00,0x00,0x7E,0x00,0x00,0x00,0x00   ; - (31)
                db 0x60,0x30,0x18,0x0C,0x18,0x30,0x60,0x00   ; > (32)
                db 0x18,0x18,0x18,0x18,0x18,0x00,0x18,0x00   ; ! (33)
                db 0x00,0x66,0xFF,0xFF,0xFF,0x7E,0x3C,0x18   ; heart (34)
                db 0x66,0x66,0x3C,0x18,0x3C,0x66,0x66,0x00   ; X (35)
; --- SPRITE: small Mario standing, 16x16 ---
spr_mario_stand:
                db 0,0,0,0,4,4,4,4,4,0,0,0,0,0,0,0
                db 0,0,0,4,4,4,4,4,4,4,4,0,0,0,0,0
                db 0,0,0,6,6,6,12,12,6,12,0,0,0,0,0,0
                db 0,0,6,12,6,12,12,12,6,12,12,12,0,0,0,0
                db 0,0,6,12,6,6,12,12,12,6,12,12,12,0,0,0
                db 0,0,0,6,12,12,12,12,6,6,6,6,0,0,0,0
                db 0,0,0,0,12,12,12,12,12,12,12,0,0,0,0,0
                db 0,0,0,4,4,1,4,4,4,0,0,0,0,0,0,0
                db 0,0,4,4,4,1,4,4,1,4,4,4,0,0,0,0
                db 0,4,4,4,4,1,1,1,1,4,4,4,4,0,0,0
                db 0,12,12,4,1,14,1,1,14,1,4,12,12,0,0,0
                db 0,12,12,12,1,1,1,1,1,1,12,12,12,0,0,0
                db 0,12,12,1,1,1,1,1,1,1,1,12,12,0,0,0
                db 0,0,0,1,1,1,0,0,1,1,1,0,0,0,0,0
                db 0,0,6,6,6,0,0,0,0,6,6,6,0,0,0,0
                db 0,6,6,6,6,0,0,0,0,6,6,6,6,0,0,0

; --- SPRITE: Goomba walking, 16x16 ---
spr_goomba:
                db 0,0,0,0,0,0,6,6,6,6,0,0,0,0,0,0
                db 0,0,0,0,6,6,6,6,6,6,6,6,0,0,0,0
                db 0,0,0,6,6,6,6,6,6,6,6,6,6,0,0,0
                db 0,0,6,6,6,6,6,6,6,6,6,6,6,6,0,0
                db 0,6,6,6,15,15,6,6,6,6,15,15,6,6,6,0
                db 0,6,6,15,15,15,6,6,6,6,15,15,15,6,6,0
                db 0,6,6,15,8,15,6,6,6,6,15,8,15,6,6,0
                db 0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0
                db 0,0,6,6,6,6,6,6,6,6,6,6,6,6,0,0
                db 0,0,0,0,6,6,14,14,14,14,6,6,0,0,0,0
                db 0,0,0,0,0,14,14,14,14,14,14,0,0,0,0,0
                db 0,0,0,0,14,14,14,14,14,14,14,14,0,0,0,0
                db 0,0,0,0,0,14,14,14,14,14,14,0,0,0,0,0
                db 0,0,0,8,8,8,8,0,0,8,8,8,8,0,0,0
                db 0,0,8,8,8,8,8,0,0,8,8,8,8,8,0,0
                db 0,0,8,8,8,8,0,0,0,0,8,8,8,8,0,0

; --- SPRITE: small Mario running, 16x16 ---
spr_mario_run:
                db 0,0,0,0,4,4,4,4,4,0,0,0,0,0,0,0
                db 0,0,0,4,4,4,4,4,4,4,4,0,0,0,0,0
                db 0,0,0,6,6,6,12,12,6,12,0,0,0,0,0,0
                db 0,0,6,12,6,12,12,12,6,12,12,12,0,0,0,0
                db 0,0,6,12,6,6,12,12,12,6,12,12,12,0,0,0
                db 0,0,0,6,12,12,12,12,6,6,6,6,0,0,0,0
                db 0,0,0,0,12,12,12,12,12,12,12,0,0,0,0,0
                db 0,0,0,4,4,4,1,4,4,4,0,0,0,0,0,0
                db 0,0,4,4,4,4,1,1,4,4,4,0,0,0,0,0
                db 0,12,12,4,4,1,1,1,1,1,4,0,0,0,0,0
                db 0,12,12,12,1,1,1,1,1,1,1,0,0,0,0,0
                db 0,0,12,12,1,1,1,1,1,1,1,0,0,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0
                db 0,0,6,6,1,1,1,0,1,1,6,6,0,0,0,0
                db 0,6,6,6,0,0,0,0,0,0,6,6,6,0,0,0
                db 0,6,6,0,0,0,0,0,0,0,0,0,6,6,0,0

; --- SPRITE: small Mario jumping, 16x16 ---
spr_mario_jump:
                db 0,0,0,0,4,4,4,4,4,0,0,0,0,12,12,0
                db 0,0,0,4,4,4,4,4,4,4,4,0,0,12,12,12
                db 0,0,0,6,6,6,12,12,6,12,0,0,0,12,12,0
                db 0,0,6,12,6,12,12,12,6,12,12,12,0,0,0,0
                db 0,0,6,12,6,6,12,12,12,6,12,12,12,0,0,0
                db 0,0,0,6,12,12,12,12,6,6,6,6,0,0,0,0
                db 0,0,0,0,12,12,12,12,12,12,12,0,0,0,0,0
                db 0,0,4,4,4,4,1,4,4,4,4,4,0,0,0,0
                db 0,4,4,4,4,4,1,1,4,4,4,4,4,0,0,0
                db 0,12,12,4,4,1,1,1,1,1,1,4,4,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0
                db 0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0
                db 0,1,1,1,1,0,0,0,0,1,1,1,1,0,0,0
                db 0,0,1,1,1,0,0,0,0,0,0,1,1,1,0,0
                db 0,6,6,6,6,0,0,0,0,0,0,6,6,6,6,0
                db 0,6,6,6,6,0,0,0,0,0,0,6,6,6,6,0

; --- SPRITE: Super Mario top half (16x16), used for all poses ---
spr_super_top:
                db 0,0,0,0,0,4,4,4,4,4,0,0,0,0,0,0
                db 0,0,0,0,4,4,4,4,4,4,4,4,0,0,0,0
                db 0,0,0,0,6,6,6,12,12,6,12,0,0,0,0,0
                db 0,0,0,6,12,6,12,12,12,6,12,12,12,0,0,0
                db 0,0,0,6,12,6,6,12,12,12,6,12,12,12,0,0
                db 0,0,0,0,6,12,12,12,12,6,6,6,6,0,0,0
                db 0,0,0,0,0,12,12,12,12,12,12,12,0,0,0,0
                db 0,0,0,0,4,4,4,1,4,4,4,0,0,0,0,0
                db 0,0,0,4,4,4,4,1,4,4,1,4,4,4,0,0
                db 0,4,4,4,4,4,4,1,1,1,1,4,4,4,4,0
                db 0,12,12,4,4,1,14,1,1,14,1,4,4,12,12,0
                db 0,12,12,12,1,1,1,1,1,1,1,1,12,12,12,0
                db 0,12,12,12,1,1,1,1,1,1,1,1,12,12,12,0
                db 0,12,12,1,1,1,1,1,1,1,1,1,1,12,12,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0

; --- SPRITE: Super Mario bottom half, standing ---
spr_super_stand_bot:
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0
                db 0,0,6,6,6,6,6,0,0,6,6,6,6,6,0,0
                db 0,6,6,6,6,6,6,0,0,6,6,6,6,6,6,0
                db 0,6,6,6,6,6,6,0,0,6,6,6,6,6,6,0

; --- SPRITE: Super Mario bottom half, running ---
spr_super_run_bot:
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,1,1,1,1,1,0,0,0,1,1,1,1,0,0
                db 0,0,1,1,1,1,1,0,0,0,1,1,1,1,0,0
                db 0,0,1,1,1,1,1,0,0,0,1,1,1,1,0,0
                db 0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0
                db 0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0
                db 0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0
                db 0,1,1,1,1,0,0,0,0,0,0,1,1,1,1,0
                db 0,6,6,6,6,6,0,0,0,0,0,0,6,6,6,6
                db 6,6,6,6,6,6,0,0,0,0,0,0,6,6,6,0
                db 6,6,6,6,6,6,0,0,0,0,0,0,6,6,6,0

; --- SPRITE: Super Mario bottom half, jumping ---
spr_super_jump_bot:
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0
                db 0,1,1,1,1,1,0,0,0,0,1,1,1,1,1,0
                db 0,1,1,1,1,1,0,0,0,0,1,1,1,1,1,0
                db 0,1,1,1,1,1,0,0,0,0,1,1,1,1,1,0
                db 1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,1
                db 1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,1
                db 1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,1
                db 1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,1
                db 6,6,6,6,6,0,0,0,0,0,0,0,6,6,6,6
                db 6,6,6,6,6,6,0,0,0,0,0,0,0,6,6,6
                db 6,6,6,6,6,6,0,0,0,0,0,0,0,6,6,6

; --- SPRITE: Goomba flattened, 16x16 ---
spr_goomba_flat:
                times 160 db 0
                db 0,0,0,6,6,6,6,6,6,6,6,6,6,0,0,0
                db 0,0,6,6,6,6,6,6,6,6,6,6,6,6,0,0
                db 0,6,6,15,15,6,6,6,6,6,15,15,6,6,6,0
                db 0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0
                db 0,0,8,8,8,8,14,14,14,14,8,8,8,8,0,0
                db 0,0,8,8,8,8,8,8,8,8,8,8,8,8,0,0

; --- SPRITE: Koopa Troopa, 16x16 ---
spr_koopa:
                db 0,0,0,0,0,0,0,0,0,0,14,14,14,0,0,0
                db 0,0,0,0,0,0,0,0,0,14,14,14,14,14,0,0
                db 0,0,0,0,0,0,0,0,0,14,15,8,14,14,0,0
                db 0,0,0,0,0,0,0,0,0,14,14,14,14,14,0,0
                db 0,0,0,0,0,0,0,0,14,14,14,14,0,0,0,0
                db 0,0,0,2,2,2,2,2,2,14,14,0,0,0,0,0
                db 0,0,2,2,15,15,2,2,15,15,2,14,0,0,0,0
                db 0,0,2,2,15,15,2,2,15,15,2,2,0,0,0,0
                db 0,0,2,2,2,2,2,2,2,2,2,2,0,0,0,0
                db 0,0,0,2,2,2,2,2,2,2,2,0,0,0,0,0
                db 0,0,0,14,14,14,14,14,14,14,14,0,0,0,0,0
                db 0,0,0,0,14,14,14,14,14,14,0,0,0,0,0,0
                db 0,0,0,14,14,14,0,0,14,14,14,0,0,0,0,0
                db 0,0,0,14,14,14,0,0,14,14,14,0,0,0,0,0
                db 0,6,6,6,6,6,0,0,0,6,6,6,6,6,0,0
                db 0,6,6,6,6,6,0,0,0,6,6,6,6,6,0,0

; --- SPRITE: Koopa shell, 16x16 ---
spr_shell:
                times 128 db 0
                db 0,0,0,0,0,2,2,2,2,2,2,0,0,0,0,0
                db 0,0,0,0,2,2,15,2,2,15,2,2,0,0,0,0
                db 0,0,0,2,2,2,15,2,2,15,2,2,2,0,0,0
                db 0,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0
                db 0,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0
                db 0,0,14,14,2,2,2,2,2,2,2,2,14,14,0,0
                db 0,0,0,14,14,14,14,14,14,14,14,14,14,0,0,0
                db 0,0,0,0,14,14,14,14,14,14,14,14,0,0,0,0

; --- SPRITE: mushroom power-up, 16x16 ---
spr_mushroom:
                db 0,0,0,0,0,4,4,4,4,4,4,0,0,0,0,0
                db 0,0,0,4,4,4,15,15,4,4,4,4,0,0,0,0
                db 0,0,4,4,15,15,15,15,4,4,4,15,15,4,0,0
                db 0,4,4,4,15,15,15,15,4,4,4,4,15,4,4,0
                db 0,4,4,4,4,15,15,4,4,4,4,4,4,4,4,0
                db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
                db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
                db 0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0
                db 0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0
                db 0,0,0,0,15,15,15,15,15,15,15,15,0,0,0,0
                db 0,0,0,0,15,0,0,15,15,0,0,15,0,0,0,0
                db 0,0,0,0,15,0,0,15,15,0,0,15,0,0,0,0
                db 0,0,0,0,15,15,15,15,15,15,15,15,0,0,0,0
                db 0,0,0,0,15,15,15,15,15,15,15,15,0,0,0,0
                db 0,0,0,0,15,15,15,15,15,15,15,15,0,0,0,0
                db 0,0,0,0,15,15,15,15,15,15,15,15,0,0,0,0

; --- SPRITE: coin, 16x16 ---
spr_coin:
                times 16 db 0
                db 0,0,0,0,0,0,14,14,14,14,0,0,0,0,0,0
                db 0,0,0,0,0,14,14,14,14,14,14,0,0,0,0,0
                times 10 db 0,0,0,0,14,14,14,6,6,14,14,14,0,0,0,0
                db 0,0,0,0,0,14,14,14,14,14,14,0,0,0,0,0
                db 0,0,0,0,0,0,14,14,14,14,0,0,0,0,0,0
                times 16 db 0

; ------------------------------------------------------------
; PROCEDURE: putpixel
; Purpose : draws one pixel in VGA mode 13h
; Inputs  : [bp+8] = x, [bp+6] = y, [bp+4] = colour
; Outputs : none
; Changes : no register is changed
; Formula : offset = y*320 + x = (y*256) + (y*64) + x
; ------------------------------------------------------------
putpixel:       push bp
                mov bp, sp
                push es
                push ax
                push bx
                push cx
                push di

                mov ax, [drawseg]
                mov es, ax

                mov ax, [bp+6]          ; ax = y
                mov bx, ax              ; bx = y
                mov cl, 8
                shl ax, cl              ; ax = y*256
                mov cl, 6
                shl bx, cl              ; bx = y*64
                add ax, bx              ; ax = y*320
                add ax, [bp+8]          ; ax = y*320 + x
                mov di, ax

                mov al, [bp+4]          ; colour
                mov [es:di], al

                pop di
                pop cx
                pop bx
                pop ax
                pop es
                pop bp
                ret 6

; ------------------------------------------------------------
; PROCEDURE: fillrect
; Purpose : fills a rectangle with one colour
; Inputs  : [bp+12] = x, [bp+10] = y, [bp+8] = width,
;           [bp+6] = height, [bp+4] = colour
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
fillrect:       push bp
                mov bp, sp
                push es
                push ax
                push bx
                push cx
                push dx
                push di

                mov ax, [drawseg]
                mov es, ax
                cld

                ; ---- clip left (x < 0) ----
                mov ax, [bp+12]
                cmp ax, 0
                jge fr_leftok
                add [bp+8], ax          ; width = width + x
                mov word [bp+12], 0
fr_leftok:
                ; ---- clip right (x + width > 320) ----
                mov ax, [bp+12]
                add ax, [bp+8]
                cmp ax, SCREEN_W
                jle fr_rightok
                mov ax, SCREEN_W
                sub ax, [bp+12]
                mov [bp+8], ax
fr_rightok:     cmp word [bp+8], 0
                jle fr_end              ; nothing left to draw

                mov ax, [bp+10]         ; ax = y
                mov bx, ax
                mov cl, 8
                shl ax, cl              ; y*256
                mov cl, 6
                shl bx, cl              ; y*64
                add ax, bx              ; y*320
                add ax, [bp+12]         ; + x
                mov di, ax              ; di = first pixel

                mov dx, [bp+6]          ; dx = rows left
                mov al, [bp+4]          ; al = colour

nextrow:        mov cx, [bp+8]          ; cx = width
                push di
                rep stosb               ; draw one row
                pop di
                add di, SCREEN_W             ; go to next row
                dec dx
                jnz nextrow

fr_end:         pop di
                pop dx
                pop cx
                pop bx
                pop ax
                pop es
                pop bp
                ret 10
; ------------------------------------------------------------
; PROCEDURE: resetmap
; Purpose : copies the original map into the working map
; Inputs  : none
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
resetmap:       push es
                push cx
                push si
                push di

                push ds
                pop es                  ; es = ds
                cld
                mov si, originalmap
                mov di, workmap
                mov cx, 720
                rep movsb

                pop di
                pop si
                pop cx
                pop es
                ret

; ------------------------------------------------------------
; PROCEDURE: gettile
; Purpose : gives the tile code at a pixel position
; Inputs  : [bp+6] = px, [bp+4] = py
; Outputs : ax = tile code (0 if outside the map height)
; Changes : only ax
; ------------------------------------------------------------
gettile:        push bp
                mov bp, sp
                push bx
                push si

                mov ax, 0               ; default answer = sky
                mov bx, [bp+4]          ; bx = py
                cmp bx, MAP_PIXEL_H
                jae gettile_end         ; outside the map height
                mov si, [bp+6]          ; si = pixel x
                cmp si, 960             ; map is 60 columns x 16 pixels
                jae gettile_end         ; outside the map width is empty sky

                shr bx, 1
                shr bx, 1
                shr bx, 1
                shr bx, 1               ; bx = row
                mov al, 60
                mul bl                  ; ax = row * 60
                shr si, 1
                shr si, 1
                shr si, 1
                shr si, 1               ; si = column
                add si, ax              ; si = row*60 + column
                mov al, [workmap+si]
                mov ah, 0

gettile_end:    pop si
                pop bx
                pop bp
                ret 4

; ------------------------------------------------------------
; PROCEDURE: drawtile
; Purpose : draws one 16x16 tile
; Inputs  : [bp+8] = x, [bp+6] = y, [bp+4] = tile code
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawtile:       push bp
                mov bp, sp
                push ax
                push bx

                mov bx, [bp+4]          ; bx = tile code
                cmp bx, 0
                je tile_sky
                cmp bx, 11
                je tile_coin
                cmp bx, 12
                je tile_pole

                ; solid tile: black border, then coloured inside
                push word [bp+8]
                push word [bp+6]
                mov ax, 16
                push ax
                push ax
                mov ax, 0
                push ax
                call fillrect

                mov ax, [bp+8]
                add ax, 1
                push ax
                mov ax, [bp+6]
                add ax, 1
                push ax
                mov ax, 14
                push ax
                push ax
                mov al, [tilecolour+bx]
                mov ah, 0
                push ax
                call fillrect
                jmp tile_done

tile_sky:       push word [bp+8]
                push word [bp+6]
                mov ax, 16
                push ax
                push ax
                mov ax, 9
                push ax
                call fillrect
                jmp tile_done

tile_coin:      push word [bp+8]        ; sky behind the coin
                push word [bp+6]
                mov ax, 16
                push ax
                push ax
                mov ax, 9
                push ax
                call fillrect

                mov ax, [bp+8]          ; yellow coin
                add ax, 5
                push ax
                mov ax, [bp+6]
                add ax, 3
                push ax
                mov ax, 6
                push ax
                mov ax, 10
                push ax
                mov ax, 14
                push ax
                call fillrect
                jmp tile_done

tile_pole:      push word [bp+8]        ; sky behind the pole
                push word [bp+6]
                mov ax, 16
                push ax
                push ax
                mov ax, 9
                push ax
                call fillrect

                mov ax, [bp+8]          ; white pole
                add ax, 7
                push ax
                push word [bp+6]
                mov ax, 2
                push ax
                mov ax, 16
                push ax
                mov ax, 15
                push ax
                call fillrect

tile_done:      pop bx
                pop ax
                pop bp
                ret 6

; ------------------------------------------------------------
; PROCEDURE: drawmap
; Purpose : draws 20 columns of the working map, rows 1 to 11
; Inputs  : [bp+4] = first column to draw (0 to 40)
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawmap:        push bp
                mov bp, sp
                push ax
                push bx
                push cx
                push dx
                push si

                mov dx, 1               ; dx = row (1 to 11)
nextmaprow:     mov cx, 0               ; cx = screen column (0 to 19)

nextmapcol:     mov al, dl
                mov bl, 60
                mul bl                  ; ax = row * 60
                add ax, [bp+4]          ; + first column
                add ax, cx              ; + screen column
                mov si, ax
                mov al, [workmap+si]    ; al = tile code
                mov ah, 0

                mov bx, cx
                shl bx, 1
                shl bx, 1
                shl bx, 1
                shl bx, 1               ; bx = x = column * 16
                push bx
                mov bx, dx
                shl bx, 1
                shl bx, 1
                shl bx, 1
                shl bx, 1               ; bx = y = row * 16
                push bx
                push ax                 ; tile code
                call drawtile

                inc cx
                cmp cx, 20
                jne nextmapcol

                inc dx
                cmp dx, 12
                jne nextmaprow

                pop si
                pop dx
                pop cx
                pop bx
                pop ax
                pop bp
                ret 2
; ------------------------------------------------------------
; PROCEDURE: drawsprite
; Purpose : draws a 16x16 sprite, colour 0 is transparent
;           pixels outside the screen are skipped (clipping)
; Inputs  : [bp+10] = x, [bp+8] = y (can be negative),
;           [bp+6] = address of sprite, [bp+4] = flags
;           (flags bit 0 = 1 means mirrored, facing left)
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawsprite:     push bp
                mov bp, sp
                push es
                push ax
                push bx
                push cx
                push dx
                push si
                push di

                mov ax, [drawseg]
                mov es, ax
                mov si, [bp+6]          ; si = sprite data
                mov dx, 0               ; dx = sprite row (0 to 15)

sprow:          mov ax, [bp+8]
                add ax, dx              ; ax = screen y of this row
                cmp ax, 0
                jl nextsprow            ; above the screen
                cmp ax, SCREEN_H
                jge nextsprow           ; below the screen

                mov bx, ax
                mov cl, 8
                shl ax, cl              ; y*256
                mov cl, 6
                shl bx, cl              ; y*64
                add ax, bx
                mov di, ax              ; di = y*320

                mov cx, 0               ; cx = sprite column (0 to 15)

spcol:          mov bx, [bp+10]
                add bx, cx              ; bx = screen x of this pixel
                cmp bx, 0
                jl nextspcol            ; left of the screen
                cmp bx, SCREEN_W
                jge nextspcol           ; right of the screen

                push bx                 ; save screen x
                mov bx, cx              ; bx = source column
                test word [bp+4], 1
                jz nomirror
                mov bx, 15
                sub bx, cx              ; mirrored: 15 - column
nomirror:       mov ax, dx
                shl ax, 1
                shl ax, 1
                shl ax, 1
                shl ax, 1               ; ax = row * 16
                add ax, bx
                mov bx, ax
                mov al, [si+bx]         ; al = colour
                pop bx                  ; bx = screen x

                cmp al, 0
                je nextspcol            ; transparent

                push di
                add di, bx
                mov [es:di], al
                pop di

nextspcol:      inc cx
                cmp cx, 16
                jne spcol

nextsprow:      inc dx
                cmp dx, 16
                jne sprow

                pop di
                pop si
                pop dx
                pop cx
                pop bx
                pop ax
                pop es
                pop bp
                ret 8
; ------------------------------------------------------------
; PROCEDURE: drawsuper
; Purpose : draws Super Mario (16x32) = top half + bottom half
; Inputs  : [bp+10] = x, [bp+8] = y (top of sprite),
;           [bp+6] = address of the bottom half, [bp+4] = flags
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawsuper:      push bp
                mov bp, sp
                push ax

                push word [bp+10]       ; top half
                push word [bp+8]
                mov ax, spr_super_top
                push ax
                push word [bp+4]
                call drawsprite

                push word [bp+10]       ; bottom half, 16 pixels lower
                mov ax, [bp+8]
                add ax, 16
                push ax
                push word [bp+6]
                push word [bp+4]
                call drawsprite

                pop ax
                pop bp
                ret 8
; ------------------------------------------------------------
; PROCEDURE: clearbuf
; Purpose : clears the whole frame buffer to black (block fill)
; Inputs  : none
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
clearbuf:       push es
                push ax
                push cx
                push di

                mov ax, [drawseg]
                mov es, ax
                cld
                mov di, 0
                mov ax, 0
                mov cx, 32000           ; 32000 words = 64000 bytes
                rep stosw

                pop di
                pop cx
                pop ax
                pop es
                ret

; ------------------------------------------------------------
; PROCEDURE: copybuf
; Purpose : copies the frame buffer to video memory (block move)
; Inputs  : none
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
copybuf:        push ds
                push es
                push ax
                push cx
                push si
                push di

                mov ax, 0xa000
                mov es, ax              ; destination = screen
                mov ax, [bufseg]
                mov ds, ax              ; source = frame buffer
                cld
                mov si, 0
                mov di, 0
                mov cx, 32000
                rep movsw

                pop di
                pop si
                pop cx
                pop ax
                pop es
                pop ds
                ret

; ------------------------------------------------------------
; INTERRUPT HANDLER: kbisr
; Purpose : our own keyboard interrupt (INT 09h)
;           reads the scan code from port 60h and
;           updates the key-state table
; Inputs  : none (called by the hardware)
; Outputs : keystate table changed
; Changes : no register is changed
; ------------------------------------------------------------
kbisr:          push ax
                push bx
                push ds

                push cs
                pop ds                  ; ds = our segment

                in al, 0x60             ; read the scan code
                cmp al, 0xe0
                jne kb_notprefix
                mov byte [kb_e0], 1     ; remember the E0 prefix
                jmp kb_done

kb_notprefix:   cmp byte [kb_e0], 1
                jne kb_normal
                mov byte [kb_e0], 0     ; this byte follows an E0
                mov bl, al
                and bl, 0x7f
                cmp bl, 0x2a
                je kb_done              ; fake shift code, ignore
                cmp bl, 0x36
                je kb_done              ; fake shift code, ignore

kb_normal:      mov bl, al
                and bl, 0x7f            ; bl = key number (bit 7 removed)
                mov bh, 0
                test al, 0x80           ; bit 7 set = key release
                jnz kb_release
                cmp byte [keystate+bx], 0
                jne kb_held
                mov byte [keyhit+bx], 1         ; a new key press
kb_held:        mov byte [keystate+bx], 1
                jmp kb_done
kb_release:     mov byte [keystate+bx], 0

kb_done:        mov al, 0x20
                out 0x20, al            ; end of interrupt

                pop ds
                pop bx
                pop ax
                iret

; ------------------------------------------------------------
; PROCEDURE: installkb
; Purpose : saves the old keyboard vector and installs kbisr
; Inputs  : none
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
installkb:      push ax
                push bx
                push dx
                push es
                mov ah, 0x35            ; get vector
                mov al, 0x09
                int 0x21                ; es:bx = old vector
                mov [oldkb_off], bx
                mov [oldkb_seg], es

                push ds
                mov dx, kbisr
                mov ax, cs
                mov ds, ax
                mov ah, 0x25            ; set vector
                mov al, 0x09
                int 0x21
                pop ds

                pop es
                pop dx
                pop bx
                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: restorekb
; Purpose : puts the old keyboard vector back
; Inputs  : none
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
restorekb:      push ax
                push dx
                push ds

                mov dx, [oldkb_off]
                mov ax, [oldkb_seg]
                mov ds, ax
                mov ah, 0x25
                mov al, 0x09
                int 0x21

                pop ds
                pop dx
                pop ax
                ret

; ------------------------------------------------------------
; INTERRUPT HANDLER: tmisr
; Purpose : our timer interrupt (INT 08h), counts ticks
;           then jumps to the old handler (chaining)
; Inputs  : none (called by the hardware)
; Outputs : tickcount is increased
; Changes : no register is changed
; ------------------------------------------------------------
tmisr:          push ax
                push ds
                push cs
                pop ds
                inc word [tickcount]    ; game frame counter: 30 ticks/second
                add word [bios_accum], 39773 ; 1193182 / 30 PIT divisor
                pop ds
                jc tm_chain             ; chain BIOS about 18.2 times/second
                mov al, 0x20            ; acknowledge this IRQ to the PIC
                out 0x20, al
                pop ax
                iret

tm_chain:       pop ax
                jmp far [cs:oldtm_off]  ; old BIOS handler sends EOI and IRETs

; ------------------------------------------------------------
; PROCEDURE: installtimer
; Purpose : saves the old timer vector and installs tmisr
; Inputs  : none
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
installtimer:   push ax
                push bx
                push dx
                push es

                mov ah, 0x35
                mov al, 0x08
                int 0x21                ; es:bx = old vector
                mov [oldtm_off], bx
                mov [oldtm_seg], es
                mov word [bios_accum], 0

                push ds
                mov dx, tmisr
                mov ax, cs
                mov ds, ax
                mov ah, 0x25
                mov al, 0x08
                int 0x21
                pop ds

                pop es
                pop dx
                pop bx
                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: restoretimer
; Purpose : puts the old timer vector back
; Inputs  : none
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
restoretimer:   push ax
                push dx
                push ds

                mov dx, [oldtm_off]
                mov ax, [oldtm_seg]
                mov ds, ax
                mov ah, 0x25
                mov al, 0x08
                int 0x21

                pop ds
                pop dx
                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: setrate30
; Purpose : sets the timer chip to 30 ticks per second
; Inputs  : none
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
setrate30:      push ax
                mov al, 0x36
                out 0x43, al
                mov ax, 39773           ; 1193182 / 30
                out 0x40, al
                mov al, ah
                out 0x40, al
                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: restorerate
; Purpose : puts the timer chip back to 18.2 ticks per second
; Inputs  : none
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
restorerate:    push ax
                mov al, 0x36
                out 0x43, al
                mov al, 0
                out 0x40, al
                out 0x40, al
                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: addfixed
; Purpose : adds an 8.8 speed to a position (whole + fraction)
; Inputs  : [bp+8] = address of whole part (word)
;           [bp+6] = address of fraction (word, 0 to 255)
;           [bp+4] = speed (signed 8.8)
; Outputs : position changed
; Changes : no register is changed
; ------------------------------------------------------------
addfixed:       push bp
                mov bp, sp
                push ax
                push bx
                push cx
                push si

                mov si, [bp+6]          ; address of fraction
                mov ax, [si]
                add ax, [bp+4]          ; fraction + speed
                mov bx, ax
                mov cl, 8
                sar bx, cl              ; change in whole pixels (signed)
                and ax, 0x00ff
                mov [si], ax            ; new fraction
                mov si, [bp+8]          ; address of whole part
                add [si], bx

                pop si
                pop cx
                pop bx
                pop ax
                pop bp
                ret 6

; ------------------------------------------------------------
; PROCEDURE: issolid
; Purpose : tells if the tile at a pixel position is solid
;           (codes 1 to 10 are solid, 0, 11 and 12 are not)
; Inputs  : [bp+6] = px, [bp+4] = py
; Outputs : ax = 1 if solid, 0 if not
; Changes : only ax
; ------------------------------------------------------------
issolid:        push bp
                mov bp, sp

                push word [bp+6]
                push word [bp+4]
                call gettile            ; ax = tile code
                cmp ax, 0
                je is_no
                cmp ax, 11
                je is_no
                cmp ax, 12
                je is_no
                mov ax, 1
                jmp is_end
is_no:          mov ax, 0
is_end:         pop bp
                ret 4

; ------------------------------------------------------------
; PROCEDURE: collidex
; Purpose : walls. If Mario moved into a solid tile sideways,
;           put him next to the wall and stop him
; Inputs  : hero variables
; Outputs : hero_x, hero_xf, hero_vx may change
; Changes : no register is changed
; ------------------------------------------------------------
collidex:       push ax
                push bx
                push dx

                mov dx, [hero_x]
                cmp word [hero_vx], 0
                je colx_end             ; not moving sideways
                jl colx_left
                add dx, 13              ; moving right: right edge
                jmp colx_check
colx_left:      add dx, 2               ; moving left: left edge

colx_check:     push dx                 ; point 1: top
                mov ax, [hero_y]
                sub ax, [hero_h]
                push ax
                call issolid
                cmp ax, 1
                je colx_hit

                push dx                 ; point 2: middle
                mov ax, [hero_h]
                shr ax, 1
                mov bx, [hero_y]
                sub bx, ax
                push bx
                call issolid
                cmp ax, 1
                je colx_hit

                push dx                 ; point 3: bottom
                mov ax, [hero_y]
                sub ax, 5
                push ax
                call issolid
                cmp ax, 1
                je colx_hit
                jmp colx_end

colx_hit:       mov bx, dx
                shr bx, 1
                shr bx, 1
                shr bx, 1
                shr bx, 1
                shl bx, 1
                shl bx, 1
                shl bx, 1
                shl bx, 1               ; bx = x of the wall tile
                cmp word [hero_vx], 0
                jl colx_hitleft
                sub bx, 14              ; stand left of the wall
                jmp colx_set
colx_hitleft:   add bx, 14              ; stand right of the wall
colx_set:       mov [hero_x], bx
                mov word [hero_xf], 0
                mov word [hero_vx], 0

colx_end:       pop dx
                pop bx
                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: collidey
; Purpose : floor and ceiling. Falling: stand on a solid tile
;           and set on_ground. Rising: hit the head and stop.
; Inputs  : hero variables
; Outputs : hero_y, hero_yf, hero_vy, on_ground may change
; Changes : no register is changed
; ------------------------------------------------------------
collidey:       push ax
                push bx
                push dx

                mov word [on_ground], 0
                cmp word [hero_vy], 0
                jl coly_up

                ; ---- falling: look at the tiles under the feet ----
                mov ax, [hero_x]
                add ax, 2
                push ax
                push word [hero_y]
                call issolid
                cmp ax, 1
                je coly_land

                mov ax, [hero_x]
                add ax, 13
                push ax
                push word [hero_y]
                call issolid
                cmp ax, 1
                je coly_land
                jmp coly_end

coly_land:      mov ax, [hero_y]
                shr ax, 1
                shr ax, 1
                shr ax, 1
                shr ax, 1
                shl ax, 1
                shl ax, 1
                shl ax, 1
                shl ax, 1               ; top of the tile = floor
                mov [hero_y], ax
                mov word [hero_yf], 0
                mov word [hero_vy], 0
                mov word [on_ground], 1
                jmp coly_end

                ; ---- rising: look at the tiles above the head ----
coly_up:        mov dx, [hero_y]
                sub dx, [hero_h]        ; dx = y of the top of Mario

                mov bx, [hero_x]
                add bx, 2
                push bx
                push dx
                call issolid
                cmp ax, 1
                je coly_head

                mov bx, [hero_x]
                add bx, 13
                push bx
                push dx
                call issolid
                cmp ax, 1
                je coly_head
                jmp coly_end

coly_head:      mov ax, [hero_x]
                add ax, 8               ; centre of the head (spec 5.9)
                push ax
                push dx
                call hitblock
                mov ax, dx
                shr ax, 1
                shr ax, 1
                shr ax, 1
                shr ax, 1
                inc ax                  ; row below the solid tile
                shl ax, 1
                shl ax, 1
                shl ax, 1
                shl ax, 1               ; y of the bottom of that tile
                add ax, [hero_h]        ; feet = top + height
                mov [hero_y], ax
                mov word [hero_yf], 0
                mov word [hero_vy], 0

coly_end:       pop dx
                pop bx
                pop ax
                ret
; ------------------------------------------------------------
; PROCEDURE: updatehero
; Purpose : reads the keys, changes speed, moves Mario
;           (tile collision, left wall = camera, right end = level end)
; Inputs  : keystate table, hero variables
; Outputs : hero variables changed
; Changes : no register is changed
; ------------------------------------------------------------
updatehero:     push ax
                push bx
                mov ax, [hero_y]
                mov [hero_prevy], ax    ; feet position of the last frame

                ; ---- speed limit: walk or run (either Shift) ----
                mov bx, WALK_MAX
                mov al, [keystate+SC_LSHIFT]
                or al, [keystate+SC_RSHIFT]
                jz uh_gotlimit
                mov bx, RUN_MAX
uh_gotlimit:    mov ax, [hero_vx]

                cmp byte [keystate+SC_RIGHT], 1     ; right arrow
                jne uh_notright
                cmp byte [keystate+SC_LEFT], 1     ; both keys = no move
                je uh_friction
                mov word [facing], 0
                cmp ax, 0
                jl uh_brake_r
                add ax, WALK_ACCEL
                cmp ax, bx
                jle uh_store
                mov ax, bx
                jmp uh_store
uh_brake_r:     add ax, 0x0040
                jmp uh_store

uh_notright:    cmp byte [keystate+SC_LEFT], 1     ; left arrow
                jne uh_friction
                mov word [facing], 1
                cmp ax, 0
                jg uh_brake_l
                sub ax, WALK_ACCEL
                neg bx
                cmp ax, bx
                jge uh_store
                mov ax, bx
                jmp uh_store
uh_brake_l:     sub ax, 0x0040
                jmp uh_store

uh_friction:    cmp ax, 0
                jg uh_fric_pos
                jl uh_fric_neg
                jmp uh_store
uh_fric_pos:    sub ax, FRICTION
                jge uh_store
                mov ax, 0
                jmp uh_store
uh_fric_neg:    add ax, FRICTION
                jle uh_store
                mov ax, 0
uh_store:       mov [hero_vx], ax

                ; ---- jump ----
                cmp byte [keystate+SC_SPACE], 1     ; space
                jne uh_nospace
                cmp word [space_prev], 0
                jne uh_jumpdone                 ; Space was already held
                cmp word [on_ground], 1
                jne uh_jumpdone                 ; no jump in the air
                mov word [hero_vy], JUMP_SPEED      ; -5.5
                mov word [on_ground], 0
                jmp uh_jumpdone
uh_nospace:     cmp word [hero_vy], JUMP_CUTOFF      ; -2.0
                jge uh_jumpdone
                mov word [hero_vy], JUMP_CUTOFF      ; cut the jump short
uh_jumpdone:    mov al, [keystate+SC_SPACE]
                mov ah, 0
                mov [space_prev], ax

                ; ---- gravity ----
                mov ax, [hero_vy]
                add ax, 0x0040
                cmp ax, MAX_FALL
                jle uh_vyok
                mov ax, MAX_FALL
uh_vyok:        mov [hero_vy], ax

                ; ---- move x ----
                mov ax, hero_x
                push ax
                mov ax, hero_xf
                push ax
                push word [hero_vx]
                call addfixed
                call collidex

                ; ---- move y ----
                mov ax, hero_y
                push ax
                mov ax, hero_yf
                push ax
                push word [hero_vy]
                call addfixed
                call collidey

                ; ---- walls ----
                mov ax, [camera_x]      ; left wall = left edge of screen
                cmp [hero_x], ax
                jge uh_leftok
                mov [hero_x], ax
                mov word [hero_xf], 0
                mov word [hero_vx], 0
uh_leftok:      cmp word [hero_x], LEVEL_RIGHT_X  ; right end of the level
                jle uh_rightok
                mov word [hero_x], LEVEL_RIGHT_X
                mov word [hero_xf], 0
                mov word [hero_vx], 0
uh_rightok:

                ; ---- pit: fell below the map, Mario dies ----
                mov ax, [hero_y]
                sub ax, [hero_h]
                cmp ax, MAP_PIXEL_H
                jl uh_notpit
                call killmario
uh_notpit:

uh_end:         pop bx
                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: updatecamera
; Purpose : camera rule of section 5.3 (follow Mario past screen
;           x 160, never go back, stop at 640)
; Inputs  : hero_x, camera_x
; Outputs : camera_x changed
; Changes : no register is changed
; ------------------------------------------------------------
updatecamera:   push ax

                mov ax, [hero_x]
                sub ax, [camera_x]      ; ax = screen x of Mario
                cmp ax, CAMERA_FOLLOW
                jle uc_end              ; not past the middle
                mov ax, [hero_x]
                sub ax, CAMERA_FOLLOW             ; wanted camera
                cmp ax, CAMERA_MAX
                jle uc_limited
                mov ax, CAMERA_MAX             ; last camera position
uc_limited:     cmp ax, [camera_x]
                jle uc_end              ; never decrease
                mov [camera_x], ax
uc_end:         pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: drawmapscroll
; Purpose : draws the map with pixel scrolling
;           (21 columns, first column = camera / 16,
;            shifted left by camera mod 16)
; Inputs  : [bp+4] = camera x
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawmapscroll:  push bp
                mov bp, sp
                push ax
                push bx
                push cx
                push dx
                push si

                mov dx, 1               ; dx = row (1 to 11)
dms_row:        mov cx, 0               ; cx = screen column (0 to 20)

dms_col:        mov si, [bp+4]
                shr si, 1
                shr si, 1
                shr si, 1
                shr si, 1               ; si = first column
                add si, cx              ; si = map column
                cmp si, 60
                jge dms_skip            ; outside the level

                mov al, dl
                mov bl, 60
                mul bl                  ; ax = row * 60
                add si, ax
                mov al, [workmap+si]    ; al = tile code
                mov ah, 0

                mov bx, cx
                shl bx, 1
                shl bx, 1
                shl bx, 1
                shl bx, 1               ; bx = column * 16
                mov si, [bp+4]
                and si, 15              ; si = camera mod 16
                sub bx, si              ; x = column*16 - offset
                push bx
                mov bx, dx
                shl bx, 1
                shl bx, 1
                shl bx, 1
                shl bx, 1               ; y = row * 16
                push bx
                push ax                 ; tile code
                call drawtile

dms_skip:       inc cx
                cmp cx, 21
                jne dms_col

                inc dx
                cmp dx, 12
                jne dms_row
                call drawcastle

                pop si
                pop dx
                pop cx
                pop bx
                pop ax
                pop bp
                ret 2

; ------------------------------------------------------------
; PROCEDURE: addscore
; Purpose : adds points to the 32-bit score (ADD/ADC),
;           the score never goes above 999999
; Inputs  : [bp+4] = points
; Outputs : score_lo, score_hi changed
; Changes : no register is changed
; ------------------------------------------------------------
addscore:       push bp
                mov bp, sp
                push ax

                mov ax, [bp+4]
                add [score_lo], ax
                adc word [score_hi], 0
                cmp word [score_hi], 0x0f
                jb as_end
                ja as_clamp
                cmp word [score_lo], 0x423f
                jbe as_end
as_clamp:       mov word [score_hi], 0x0f       ; 999999 = 0x000F423F
                mov word [score_lo], 0x423f
as_end:         pop ax
                pop bp
                ret 2

; ------------------------------------------------------------
; PROCEDURE: addcoin
; Purpose : coins + 1, score + 200, 100 coins = extra life
; Inputs  : none
; Outputs : coins, lives, score changed
; Changes : no register is changed
; ------------------------------------------------------------
addcoin:        push ax

                inc word [coins]
                mov ax, 200
                push ax
                call addscore
                cmp word [coins], 100
                jb ac_end
                mov word [coins], 0
                cmp word [lives], MAX_LIVES
                jae ac_end
                inc word [lives]
ac_end:         pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: hitblock
; Purpose : Mario's head hit the tile at this pixel
;           brick: Super breaks it (+50), Small does nothing
;           "?" coin: empty block, coin, +200
;           "?" mushroom: empty block, mushroom appears
; Inputs  : [bp+6] = px, [bp+4] = py
; Outputs : working map changed
; Changes : no register is changed
; ------------------------------------------------------------
hitblock:       push bp
                mov bp, sp
                push ax
                push bx
                push cx
                push si

                mov bx, [bp+4]
                cmp bx, MAP_PIXEL_H
                jb hb_ok
                jmp hb_end
hb_ok:
                shr bx, 1
                shr bx, 1
                shr bx, 1
                shr bx, 1               ; bx = row
                mov cx, [bp+6]
                shr cx, 1
                shr cx, 1
                shr cx, 1
                shr cx, 1               ; cx = column
                mov al, 60
                mul bl                  ; ax = row * 60
                mov si, ax
                add si, cx              ; si = tile index
                mov al, [workmap+si]

                cmp al, 2
                je hb_brick
                cmp al, 3
                je hb_coin
                cmp al, 4
                je hb_mush
                jmp hb_end

hb_brick:       cmp word [hero_h], 32
                jne hb_end              ; small Mario: nothing
                mov byte [workmap+si], 0
                mov ax, 50
                push ax
                call addscore
                jmp hb_end

hb_coin:        mov byte [workmap+si], 5
                call addcoin
                mov ax, cx
                shl ax, 1
                shl ax, 1
                shl ax, 1
                shl ax, 1
                mov [pop_x], ax
                mov ax, bx
                shl ax, 1
                shl ax, 1
                shl ax, 1
                shl ax, 1
                sub ax, 16
                mov [pop_y], ax
                mov word [pop_t], 12
                mov word [pop_on], 1
                jmp hb_end

hb_mush:        mov byte [workmap+si], 5
                mov ax, cx
                shl ax, 1
                shl ax, 1
                shl ax, 1
                shl ax, 1
                mov [mush_x], ax
                mov ax, bx
                shl ax, 1
                shl ax, 1
                shl ax, 1
                shl ax, 1
                sub ax, 16
                mov [mush_y], ax
                mov word [mush_dir], 1
                mov word [mush_vy], 0
                mov word [mush_on], 1

hb_end:         pop si
                pop cx
                pop bx
                pop ax
                pop bp
                ret 4

; ------------------------------------------------------------
; PROCEDURE: checkcoin
; Purpose : if the tile at this pixel is a map coin, collect it
; Inputs  : [bp+6] = px, [bp+4] = py
; Outputs : map, score, coins changed
; Changes : no register is changed
; ------------------------------------------------------------
checkcoin:      push bp
                mov bp, sp
                push ax
                push bx
                push si

                mov bx, [bp+4]
                cmp bx, MAP_PIXEL_H
                jae cc_end
                shr bx, 1
                shr bx, 1
                shr bx, 1
                shr bx, 1
                mov al, 60
                mul bl                  ; ax = row * 60
                mov si, [bp+6]
                shr si, 1
                shr si, 1
                shr si, 1
                shr si, 1
                add si, ax
                cmp byte [workmap+si], 11
                jne cc_end
                mov byte [workmap+si], 0
                call addcoin
cc_end:         pop si
                pop bx
                pop ax
                pop bp
                ret 4

; ------------------------------------------------------------
; PROCEDURE: collectcoins
; Purpose : checks 4 points inside Mario for map coins
; Inputs  : hero variables
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
collectcoins:   push ax

                mov ax, [hero_x]
                add ax, 4
                push ax
                mov ax, [hero_y]
                sub ax, 4
                push ax
                call checkcoin

                mov ax, [hero_x]
                add ax, 11
                push ax
                mov ax, [hero_y]
                sub ax, 4
                push ax
                call checkcoin

                mov ax, [hero_x]
                add ax, 8
                push ax
                mov ax, [hero_y]
                sub ax, [hero_h]
                add ax, 4
                push ax
                call checkcoin

                mov ax, [hero_x]
                add ax, 8
                push ax
                mov ax, [hero_h]
                shr ax, 1
                neg ax
                add ax, [hero_y]
                push ax
                call checkcoin

                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: updatemushroom
; Purpose : moves the mushroom (1 pixel per frame, gravity,
;           turns at walls), removes it in a pit or far left,
;           and lets Mario collect it (+1000, becomes Super)
; Inputs  : mushroom variables, hero variables
; Outputs : mushroom variables, score, hero_h changed
; Changes : no register is changed
; ------------------------------------------------------------
updatemushroom: push ax
                push bx
                push cx

                cmp word [mush_on], 1
                je um_run
                jmp um_end
um_run:
                ; ---- sideways ----
                mov bx, [mush_x]
                add bx, [mush_dir]      ; bx = new x
                cmp bx, 0
                jge um_fwd
                jmp um_gone
um_fwd:         mov ax, bx
                cmp word [mush_dir], 0
                jl um_leading
                add ax, 15              ; moving right: right edge
um_leading:     push ax
                mov cx, [mush_y]
                add cx, 8
                push cx
                call issolid
                cmp ax, 1
                je um_turn
                mov [mush_x], bx
                jmp um_vert
um_turn:        neg word [mush_dir]

                ; ---- gravity ----
um_vert:        mov ax, [mush_vy]
                inc ax
                cmp ax, 4
                jle um_vok
                mov ax, 4
um_vok:         mov [mush_vy], ax
                mov bx, [mush_y]
                add bx, ax              ; bx = new y
                mov cx, bx
                add cx, 16              ; cx = feet

                mov ax, [mush_x]
                add ax, 4
                push ax
                push cx
                call issolid
                cmp ax, 1
                je um_land
                mov ax, [mush_x]
                add ax, 11
                push ax
                push cx
                call issolid
                cmp ax, 1
                je um_land
                mov [mush_y], bx
                jmp um_checks
um_land:        shr cx, 1
                shr cx, 1
                shr cx, 1
                shr cx, 1
                shl cx, 1
                shl cx, 1
                shl cx, 1
                shl cx, 1
                sub cx, 16
                mov [mush_y], cx
                mov word [mush_vy], 0

                ; ---- pit and left of the camera ----
um_checks:      cmp word [mush_y], 192
                jge um_gone
                mov ax, [camera_x]
                sub ax, 32
                cmp [mush_x], ax
                jl um_gone

                ; ---- touching Mario? ----
                mov ax, [hero_x]
                add ax, 13
                cmp ax, [mush_x]
                jle um_end
                mov ax, [mush_x]
                add ax, 16
                mov bx, [hero_x]
                add bx, 2
                cmp bx, ax
                jge um_end
                mov ax, [hero_y]
                cmp ax, [mush_y]
                jle um_end
                mov ax, [hero_y]
                sub ax, [hero_h]
                mov bx, [mush_y]
                add bx, 16
                cmp ax, bx
                jge um_end

                mov word [mush_on], 0   ; collected
                mov ax, 1000
                push ax
                call addscore
                mov word [hero_h], 32   ; Super Mario, feet stay fixed
                jmp um_end

um_gone:        mov word [mush_on], 0
um_end:         pop cx
                pop bx
                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: updatepop
; Purpose : moves the coin that pops out of a block
; Inputs  : pop variables
; Outputs : pop variables changed
; Changes : no register is changed
; ------------------------------------------------------------
updatepop:      cmp word [pop_on], 1
                jne up_end
                sub word [pop_y], 2
                dec word [pop_t]
                jnz up_end
                mov word [pop_on], 0
up_end:         ret

; ------------------------------------------------------------
; PROCEDURE: drawdigit
; Purpose : draws one 8x8 digit into the frame buffer
; Inputs  : [bp+10] = x, [bp+8] = y, [bp+6] = digit, [bp+4] = colour
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawdigit:      push bp
                mov bp, sp
                push es
                push ax
                push bx
                push cx
                push dx
                push si
                push di

                mov ax, [drawseg]
                mov es, ax
                mov bx, [bp+6]
                shl bx, 1
                shl bx, 1
                shl bx, 1               ; digit * 8
                mov si, digitfont
                add si, bx

                mov ax, [bp+8]          ; y
                mov bx, ax
                mov cl, 8
                shl ax, cl
                mov cl, 6
                shl bx, cl
                add ax, bx              ; y * 320
                add ax, [bp+10]         ; + x
                mov di, ax

                mov dx, 8               ; 8 rows
dd_row:         mov ah, [si]
                mov cx, 8
dd_pix:         shl ah, 1
                jnc dd_skip
                mov al, [bp+4]
                mov [es:di], al
dd_skip:        inc di
                loop dd_pix
                add di, 312
                inc si
                dec dx
                jnz dd_row

                pop di
                pop si
                pop dx
                pop cx
                pop bx
                pop ax
                pop es
                pop bp
                ret 8

; ------------------------------------------------------------
; PROCEDURE: drawnum32
; Purpose : draws a 32-bit number with a fixed count of digits
;           (zero padded), by repeated division by 10
; Inputs  : [bp+12] = x, [bp+10] = y, [bp+8] = high word,
;           [bp+6] = low word, [bp+4] = number of digits
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawnum32:      push bp
                mov bp, sp
                push ax
                push bx
                push cx
                push dx
                push si
                push di

                mov si, [bp+8]          ; si = high word
                mov di, [bp+6]          ; di = low word
                mov cx, [bp+4]          ; cx = digits
                mov bx, 10
dn_div:         mov ax, si
                mov dx, 0
                div bx                  ; divide high word
                mov si, ax
                mov ax, di
                div bx                  ; dx is the carried remainder
                mov di, ax
                push dx                 ; digit goes on the stack
                loop dn_div

                mov cx, [bp+4]
                mov si, [bp+12]         ; si = x of the next digit
dn_draw:        pop ax
                push si
                push word [bp+10]
                push ax
                mov ax, 15
                push ax
                call drawdigit
                add si, 8
                loop dn_draw

                pop di
                pop si
                pop dx
                pop cx
                pop bx
                pop ax
                pop bp
                ret 10

; ------------------------------------------------------------
; PROCEDURE: resetenemies
; Purpose : copies the original enemy table into the working one
; Inputs  : none
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
resetenemies:   push es
                push cx
                push si
                push di

                push ds
                pop es
                cld
                mov si, enemies_orig
                mov di, enemies
                mov cx, 96
                rep movsb

                pop di
                pop si
                pop cx
                pop es
                ret

; ------------------------------------------------------------
; PROCEDURE: restartlevel
; Purpose : resets map, enemies and Mario (used by newgame,
;           life-lost screen)
; Inputs  : none
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
restartlevel:   call resetmap
                mov word [game_time], LEVEL_TIME
                mov word [tickpersec], 0
                call resetenemies
                mov word [hero_x], 32
                mov word [hero_xf], 0
                mov word [hero_y], 160
                mov word [hero_yf], 0
                mov word [hero_vx], 0
                mov word [hero_vy], 0
                mov word [hero_h], 16
                mov word [camera_x], 0
                mov word [invuln], 0
                mov word [mush_on], 0
                mov word [pop_on], 0
                mov word [stomp_chain], 0
                mov word [on_ground], 1
                mov word [facing], 0
                mov word [space_prev], 0
                ret

; ------------------------------------------------------------
; PROCEDURE: hurtmario
; Purpose : enemy touched Mario: Super becomes Small (2 s
;           invulnerable), Small dies, invulnerable = no effect
; Inputs  : none
; Outputs : hero_h, invuln changed
; Changes : no register is changed
; ------------------------------------------------------------
hurtmario:      cmp word [invuln], 0
                jne hm_end
                cmp word [hero_h], 32
                jne hm_die
                mov word [hero_h], 16   ; feet stay fixed
                mov word [invuln], INVULN_FRAMES   ; 2 seconds at 30 frames
                jmp hm_end
hm_die:         call killmario
hm_end:         ret

; ------------------------------------------------------------
; PROCEDURE: mariooverlap
; Purpose : rectangle overlap test between Mario and an enemy
; Inputs  : [bp+4] = address of the enemy record
; Outputs : ax = 1 if they overlap, else 0
; Changes : only ax
; ------------------------------------------------------------
mariooverlap:   push bp
                mov bp, sp
                push bx
                push dx
                push si

                mov si, [bp+4]
                mov ax, 0
                mov bx, [hero_x]
                sub bx, [si+4]          ; x difference
                cmp bx, -11
                jl mo_end
                cmp bx, 11
                jg mo_end
                mov bx, [hero_y]
                cmp bx, [si+6]
                jle mo_end              ; feet above enemy top
                sub bx, [hero_h]        ; bx = top of Mario
                mov dx, [si+6]
                add dx, 16              ; dx = bottom of enemy
                cmp bx, dx
                jge mo_end
                mov ax, 1
mo_end:         pop si
                pop dx
                pop bx
                pop bp
                ret 2

; ------------------------------------------------------------
; PROCEDURE: enemyahead
; Purpose : is another walking enemy within 16 pixels ahead?
; Inputs  : [bp+4] = address of this enemy record
; Outputs : ax = 1 if blocked, else 0
; Changes : only ax
; ------------------------------------------------------------
enemyahead:     push bp
                mov bp, sp
                push cx
                push si
                push di

                mov si, [bp+4]
                mov di, enemies
                mov cx, 6
ea_loop:        cmp di, si
                je ea_next
                cmp word [di], 0
                je ea_next
                cmp word [di+2], 1
                jne ea_next
                mov ax, [di+6]
                cmp ax, [si+6]
                jne ea_next             ; not on the same level
                mov ax, [di+4]
                sub ax, [si+4]          ; other x - my x
                cmp word [si+8], 0
                jge ea_check
                neg ax                  ; moving left: mirror
ea_check:       cmp ax, 0
                jle ea_next
                cmp ax, 16
                jg ea_next
                mov ax, 1
                jmp ea_end
ea_next:        add di, 16
                loop ea_loop
                mov ax, 0
ea_end:         pop di
                pop si
                pop cx
                pop bp
                ret 2

; ------------------------------------------------------------
; PROCEDURE: enemyfall
; Purpose : gravity for one enemy; lands on solid tiles,
;           removed when it falls out of the map
; Inputs  : [bp+4] = address of the enemy record
; Outputs : enemy y and vy changed
; Changes : no register is changed
; ------------------------------------------------------------
enemyfall:      push bp
                mov bp, sp
                push ax
                push bx
                push cx
                push si

                mov si, [bp+4]
                mov ax, [si+14]
                inc ax
                cmp ax, 4
                jle ef_ok
                mov ax, 4
ef_ok:          mov [si+14], ax
                mov bx, [si+6]
                add bx, ax              ; bx = new y
                mov cx, bx
                add cx, 16              ; cx = feet

                mov ax, [si+4]
                add ax, 4
                push ax
                push cx
                call issolid
                cmp ax, 1
                je ef_land
                mov ax, [si+4]
                add ax, 11
                push ax
                push cx
                call issolid
                cmp ax, 1
                je ef_land
                mov [si+6], bx
                cmp word [si+6], 192
                jl ef_end
                mov word [si], 0        ; fell into a pit: removed
                jmp ef_end
ef_land:        shr cx, 1
                shr cx, 1
                shr cx, 1
                shr cx, 1
                shl cx, 1
                shl cx, 1
                shl cx, 1
                shl cx, 1
                sub cx, 16
                mov [si+6], cx
                mov word [si+14], 0
ef_end:         pop si
                pop cx
                pop bx
                pop ax
                pop bp
                ret 2

; ------------------------------------------------------------
; PROCEDURE: enemystep
; Purpose : walking / sliding. Turns at walls and other enemies
;           (Koopa also at platform edges), else moves.
; Inputs  : [bp+4] = address of the enemy record
; Outputs : enemy x, xfraction, direction changed
; Changes : no register is changed
; ------------------------------------------------------------
enemystep:      push bp
                mov bp, sp
                push ax
                push bx
                push cx
                push dx
                push si
                push di

                mov si, [bp+4]
                mov dx, [si+8]          ; dx = direction
                mov bx, 1               ; probe distance
                mov cx, 0x0080          ; Goomba speed 0.5
                cmp word [si+2], 4
                jne est_notshell
                mov bx, 3               ; sliding shell
                mov cx, 0x0300
                jmp est_probe
est_notshell:   cmp word [si], 2
                jne est_probe
                mov cx, 0x00C0          ; Koopa speed 0.75

est_probe:      mov ax, [si+4]
                cmp dx, 0
                jl est_left
                add ax, bx
                add ax, 15
                jmp est_gotx
est_left:       sub ax, bx
est_gotx:       mov di, ax              ; di = x of the probe point

                push di                 ; wall ahead?
                mov ax, [si+6]
                add ax, 8
                push ax
                call issolid
                cmp ax, 1
                je est_turn

                cmp word [si+2], 4
                je est_move             ; shells only check walls
                cmp word [si], 2
                jne est_noedge
                cmp word [si+14], 0
                jne est_noedge
                push di                 ; Koopa: floor ahead?
                mov ax, [si+6]
                add ax, 16
                push ax
                call issolid
                cmp ax, 1
                jne est_turn
est_noedge:     push si                 ; another enemy ahead?
                call enemyahead
                cmp ax, 1
                je est_turn

est_move:       cmp dx, 0
                jge est_pos
                neg cx
est_pos:        lea ax, [si+4]
                push ax
                lea ax, [si+12]
                push ax
                push cx
                call addfixed
                jmp est_end
est_turn:       neg word [si+8]
est_end:        pop di
                pop si
                pop dx
                pop cx
                pop bx
                pop ax
                pop bp
                ret 2

; ------------------------------------------------------------
; PROCEDURE: enemymove
; Purpose : one frame of movement for one enemy
; Inputs  : [bp+4] = address of the enemy record
; Outputs : enemy record changed
; Changes : no register is changed
; ------------------------------------------------------------
enemymove:      push bp
                mov bp, sp
                push ax
                push si

                mov si, [bp+4]
                mov ax, [camera_x]
                sub ax, 32
                cmp [si+4], ax
                jge em_alive
                mov word [si], 0        ; left behind: removed
                jmp em_end
em_alive:       mov ax, [si+2]
                cmp ax, 0
                jne em_n0
                mov ax, [si+4]          ; waiting: start when near
                sub ax, [camera_x]
                cmp ax, 336
                jge em_end
                mov word [si+2], 1
                jmp em_end
em_n0:          cmp ax, 2
                jne em_n2
                dec word [si+10]        ; flat Goomba: timer
                jnz em_end
                mov word [si], 0
                jmp em_end
em_n2:          cmp ax, 4
                jne em_n4
                cmp word [si+10], 0
                je em_n4
                dec word [si+10]        ; kick grace time
em_n4:          cmp ax, 3
                je em_fall
                push si
                call enemystep
em_fall:        push si
                call enemyfall
em_end:         pop si
                pop ax
                pop bp
                ret 2

; ------------------------------------------------------------
; PROCEDURE: enemykick
; Purpose : still shell touched: it slides away (+400)
; Inputs  : [bp+4] = address of the enemy record
; Outputs : enemy state, direction changed
; Changes : no register is changed
; ------------------------------------------------------------
enemykick:      push bp
                mov bp, sp
                push ax
                push si

                mov si, [bp+4]
                mov word [si+2], 4
                mov word [si+10], 8     ; ignores Mario for 8 frames
                mov word [si+8], 1
                mov ax, [hero_x]
                cmp ax, [si+4]
                jl ek_go                ; Mario on the left: go right
                mov word [si+8], -1
ek_go:          mov ax, 400
                push ax
                call addscore

                pop si
                pop ax
                pop bp
                ret 2

; ------------------------------------------------------------
; PROCEDURE: enemystomp
; Purpose : Mario stomped an enemy: stomp chain points,
;           Goomba flat, Koopa becomes a shell, Mario bounces
; Inputs  : [bp+4] = address of the enemy record
; Outputs : enemy, score, hero_y, hero_vy changed
; Changes : no register is changed
; ------------------------------------------------------------
enemystomp:     push bp
                mov bp, sp
                push ax
                push bx
                push si

                mov si, [bp+4]
                mov bx, [stomp_chain]
                cmp bx, 10
                jb esm_points
                cmp word [lives], MAX_LIVES    ; 11th stomp: extra life
                jae esm_next
                inc word [lives]
                jmp esm_next
esm_points:     shl bx, 1
                mov ax, [chaintab+bx]
                push ax
                call addscore
esm_next:       cmp word [stomp_chain], 200
                jae esm_effect
                inc word [stomp_chain]
esm_effect:     cmp word [si], 1
                jne esm_koopa
                mov word [si+2], 2      ; Goomba: flat for 1 second
                mov word [si+10], 30
                jmp esm_bounce
esm_koopa:      mov word [si+2], 3      ; Koopa / sliding shell: still shell
esm_bounce:     mov ax, [si+6]
                mov [hero_y], ax        ; feet on top of the enemy
                mov word [hero_yf], 0
                mov word [hero_vy], 0xFD00      ; bounce -3.0
                cmp byte [keystate+SC_SPACE], 1
                jne esm_end
                mov word [hero_vy], 0xFC00      ; Space held: -4.0
esm_end:        pop si
                pop bx
                pop ax
                pop bp
                ret 2

; ------------------------------------------------------------
; PROCEDURE: enemyhit
; Purpose : Mario against one enemy (rules of section 5.6)
; Inputs  : [bp+4] = address of the enemy record
; Outputs : score, health, enemy changed
; Changes : no register is changed
; ------------------------------------------------------------
enemyhit:       push bp
                mov bp, sp
                push ax
                push bx
                push si

                mov si, [bp+4]
                mov ax, [si+2]
                cmp ax, 0
                je eh_out
                cmp ax, 2
                je eh_out               ; waiting or flat: no contact
                push si
                call mariooverlap
                cmp ax, 1
                jne eh_out
                cmp word [si+2], 3
                jne eh_notstill
                push si
                call enemykick          ; still shell: kick
                jmp eh_out
eh_notstill:    cmp word [hero_vy], 0
                jle eh_side
                mov ax, [hero_prevy]
                mov bx, [si+6]
                add bx, 8
                cmp ax, bx
                jg eh_side              ; feet were not above the upper half
                push si
                call enemystomp
                jmp eh_out
eh_side:        cmp word [si+2], 4
                jne eh_hurt
                cmp word [si+10], 0
                jne eh_out              ; shell grace time
eh_hurt:        call hurtmario
eh_out:         pop si
                pop bx
                pop ax
                pop bp
                ret 2

; ------------------------------------------------------------
; PROCEDURE: shellkill
; Purpose : a sliding shell removes every walking enemy it
;           touches (+500 each)
; Inputs  : [bp+4] = address of the enemy record (the shell)
; Outputs : other enemies, score changed
; Changes : no register is changed
; ------------------------------------------------------------
shellkill:      push bp
                mov bp, sp
                push ax
                push cx
                push si
                push di

                mov si, [bp+4]
                cmp word [si+2], 4
                jne sk_end
                mov di, enemies
                mov cx, 6
sk_loop:        cmp di, si
                je sk_next
                cmp word [di], 0
                je sk_next
                cmp word [di+2], 1
                jne sk_next
                mov ax, [di+4]
                sub ax, [si+4]
                cmp ax, -12
                jl sk_next
                cmp ax, 12
                jg sk_next
                mov ax, [di+6]
                sub ax, [si+6]
                cmp ax, -12
                jl sk_next
                cmp ax, 12
                jg sk_next
                mov word [di], 0        ; removed
                mov ax, 500
                push ax
                call addscore
sk_next:        add di, 16
                loop sk_loop
sk_end:         pop di
                pop si
                pop cx
                pop ax
                pop bp
                ret 2

; ------------------------------------------------------------
; PROCEDURE: updateenemies
; Purpose : all enemies, one frame (indexed addressing, loop)
; Inputs  : enemy table
; Outputs : enemy table, score, health changed
; Changes : no register is changed
; ------------------------------------------------------------
updateenemies:  push ax
                push cx
                push si

                cmp word [on_ground], 1
                jne ue_nochain
                mov word [stomp_chain], 0       ; landing resets the chain
ue_nochain:     cmp word [invuln], 0
                je ue_start
                dec word [invuln]
ue_start:       mov si, enemies
                mov cx, 6
ue_loop:        cmp word [si], 0
                je ue_next
                push si
                call enemymove
                cmp word [si], 0
                je ue_next
                push si
                call enemyhit
                cmp word [si], 0
                je ue_next
                push si
                call shellkill
ue_next:        add si, 16
                loop ue_loop

                pop si
                pop cx
                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: drawenemies
; Purpose : draws all enemies into the frame buffer
; Inputs  : enemy table, camera_x
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawenemies:    push ax
                push bx
                push cx
                push dx
                push si

                mov si, enemies
                mov cx, 6
de_loop:        cmp word [si], 0
                je de_next
                mov bx, 0               ; flags
                cmp word [si], 1
                jne de_koopa
                mov ax, spr_goomba
                cmp word [si+2], 2
                jne de_gwalk
                mov ax, spr_goomba_flat
                jmp de_draw
de_gwalk:       mov bx, [tickcount]     ; walking animation: mirror often
                shr bx, 1
                shr bx, 1
                shr bx, 1
                and bx, 1
                jmp de_draw
de_koopa:       mov ax, spr_koopa
                cmp word [si+2], 3
                jb de_kdir
                mov ax, spr_shell
                jmp de_draw
de_kdir:        cmp word [si+8], 0
                jge de_draw
                mov bx, 1               ; facing left
de_draw:        mov dx, [si+4]
                sub dx, [camera_x]
                push dx
                push word [si+6]
                push ax
                push bx
                call drawsprite
de_next:        add si, 16
                loop de_loop

                pop si
                pop dx
                pop cx
                pop bx
                pop ax
                ret

; --- font characters (the order matches the pictures) ---
fontchars:      db '0123456789ABCDEFGHILMNOPRSTUVWx->!#X'

; --- one byte per key: 1 = pressed since the last check ---
keyhit:         times 128 db 0

; --- HUD texts (end with 0) ---
str_score:      db 'SCORE',0
str_coins:      db 'COINS',0
str_worldh:     db 'WORLD',0
str_time:       db 'TIME',0
str_lives:      db 'LIVES',0
str_health:     db 'HEALTH',0
str_w11:        db '1-1',0
str_xtimes:     db 'x',0

; --- HUD text table: x, y, address of text, colour ---
hud_labels:     dw 8,0,str_score,14
                dw 72,0,str_coins,14
                dw 128,0,str_worldh,14
                dw 184,0,str_time,14
                dw 224,0,str_lives,14
                dw 272,0,str_health,14
                dw 128,8,str_w11,15
                dw 72,8,str_xtimes,15
                dw 232,8,str_xtimes,15

; ------------------------------------------------------------
; PROCEDURE: gethit
; Purpose : was this key pressed since the last check?
;           (clears the flag)
; Inputs  : [bp+4] = scan code
; Outputs : ax = 1 if pressed, else 0
; Changes : only ax
; ------------------------------------------------------------
gethit:         push bp
                mov bp, sp
                push bx

                mov bx, [bp+4]
                mov ax, 0
                cmp byte [keyhit+bx], 0
                je gh_end
                mov byte [keyhit+bx], 0
                mov ax, 1
gh_end:         pop bx
                pop bp
                ret 2

; ------------------------------------------------------------
; PROCEDURE: drawtext
; Purpose : draws a text (ended by 0) with the 8x8 font.
;           Characters not in the font (space) are skipped.
; Inputs  : [bp+10] = x, [bp+8] = y, [bp+6] = address of text,
;           [bp+4] = colour
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawtext:       push bp
                mov bp, sp
                push ax
                push bx
                push cx
                push dx
                push si
                push di
                push es

                push ds
                pop es                  ; es = ds for scasb
                cld
                mov dx, [bp+10]         ; dx = x of the next letter
                mov si, [bp+6]          ; si = text
dt_next:        mov al, [si]
                cmp al, 0
                je dt_end
                mov di, fontchars
                mov cx, 36
                repne scasb             ; search the letter
                jne dt_skip             ; not found (space)
                mov bx, 35
                sub bx, cx              ; bx = picture number
                push dx
                push word [bp+8]
                push bx
                push word [bp+4]
                call drawdigit
dt_skip:        add dx, 8
                inc si
                jmp dt_next

dt_end:         pop es
                pop di
                pop si
                pop dx
                pop cx
                pop bx
                pop ax
                pop bp
                ret 8

; ------------------------------------------------------------
; PROCEDURE: drawtexts
; Purpose : draws many texts from a table (x, y, text, colour)
; Inputs  : [bp+6] = address of the table, [bp+4] = count
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawtexts:      push bp
                mov bp, sp
                push cx
                push si

                mov si, [bp+6]
                mov cx, [bp+4]
dts_loop:       push word [si]
                push word [si+2]
                push word [si+4]
                push word [si+6]
                call drawtext
                add si, 8
                loop dts_loop

                pop si
                pop cx
                pop bp
                ret 4

; ------------------------------------------------------------
; PROCEDURE: drawhudfull
; Purpose : the real HUD: SCORE, COINS, WORLD, TIME, LIVES, HEALTH
; Inputs  : score, coins, game_time, lives, hero_h
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawhudfull:    push ax

                mov ax, hud_labels
                push ax
                mov ax, 9
                push ax
                call drawtexts

                mov ax, 8               ; score, 6 digits
                push ax
                mov ax, 8
                push ax
                push word [score_hi]
                push word [score_lo]
                mov ax, 6
                push ax
                call drawnum32

                mov ax, 80              ; coins, 2 digits
                push ax
                mov ax, 8
                push ax
                mov ax, 0
                push ax
                push word [coins]
                mov ax, 2
                push ax
                call drawnum32

                mov ax, 184             ; time, 3 digits
                push ax
                mov ax, 8
                push ax
                mov ax, 0
                push ax
                push word [game_time]
                mov ax, 3
                push ax
                call drawnum32

                mov ax, 240             ; lives, 2 digits
                push ax
                mov ax, 8
                push ax
                mov ax, 0
                push ax
                push word [lives]
                mov ax, 2
                push ax
                call drawnum32

                mov ax, 272             ; heart 1 (always filled)
                push ax
                mov ax, 8
                push ax
                mov ax, 34
                push ax
                mov ax, 4
                push ax
                call drawdigit

                mov ax, 288             ; heart 2 (filled if Super)
                push ax
                mov ax, 8
                push ax
                mov ax, 34
                push ax
                mov ax, 8               ; grey
                cmp word [hero_h], 32
                jne hh_grey
                mov ax, 4               ; red
hh_grey:        push ax
                call drawdigit

                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: updateclock
; Purpose : the level clock goes down 1 every second
;           (30 timer ticks). At 0 Mario dies.
; Inputs  : none
; Outputs : game_time, tickpersec changed
; Changes : no register is changed
; ------------------------------------------------------------
updateclock:    inc word [tickpersec]
                cmp word [tickpersec], 30
                jb ucl_end
                mov word [tickpersec], 0
                cmp word [game_time], 0
                je ucl_end
                dec word [game_time]
                jnz ucl_end
                call killmario
ucl_end:        ret

; ------------------------------------------------------------
; PROCEDURE: debugkeys
; Purpose : test keys (listed in the README):
;           T = time 5 seconds, C = 99 coins
; Inputs  : none
; Outputs : game_time, coins changed
; Changes : no register is changed
; ------------------------------------------------------------
debugkeys:      push ax

                mov ax, SC_T            ; T
                push ax
                call gethit
                cmp ax, 1
                jne dk_c
                mov word [game_time], 5
dk_c:           mov ax, SC_C            ; C
                push ax
                call gethit
                cmp ax, 1
                jne dk_end
                mov word [coins], 99
dk_end:         pop ax
                ret
; --- game state ---
state:          dw 0
sel:            dw 0            ; title menu: 0 = START, 1 = EXIT
lifetimer:      dw 0

; --- jump table: one handler per state ---
statetable:     dw st_title, st_playing, st_paused, st_dying
                dw st_lifelost, st_winseq, st_levelcomplete
                dw st_gameover, st_exit

; --- texts ---
str_title:      db 'SUPER MARIO ENGINE',0
str_start:      db 'START GAME',0
str_exit:       db 'EXIT',0
str_group:      db 'GROUP 06',0
str_arrow:      db '>',0
str_world:      db 'WORLD 1-1',0
str_lleft:      db 'LIVES LEFT',0
str_gameover:   db 'GAME OVER',0
str_final:      db 'FINAL SCORE',0
str_entertitle: db 'PRESS ENTER FOR THE TITLE',0
str_paused:     db 'PAUSED',0
str_pressp:     db 'PRESS P TO RESUME',0

; --- box tables: x, y, width, height, colour ---
title_boxes:    dw 0,0,320,200,9
                dw 0,160,320,16,2
                dw 0,176,320,24,6
                dw 96,70,128,70,15
                dw 98,72,124,66,0
pa_boxes:       dw 80,80,160,40,15
                dw 82,82,156,36,0
ll_boxes:       dw 0,0,320,200,0
go_boxes:       dw 0,0,320,200,0
                dw 40,40,240,130,4
                dw 43,43,234,124,0

; --- text tables: x, y, text, colour ---
title_texts:    dw 88,30,str_title,4
                dw 120,90,str_start,15
                dw 120,108,str_exit,15
                dw 128,180,str_group,15
pa_texts:       dw 136,88,str_paused,14
                dw 92,104,str_pressp,15
ll_texts:       dw 124,60,str_world,15
                dw 150,98,str_xtimes,15
                dw 120,130,str_lleft,15
go_texts:       dw 124,60,str_gameover,4
                dw 116,96,str_final,15
                dw 96,128,str_coins,14
                dw 176,128,str_time,14
                dw 60,150,str_entertitle,10

; ------------------------------------------------------------
; PROCEDURE: drawboxes
; Purpose : fills many rectangles from a table
; Inputs  : [bp+6] = address of the table, [bp+4] = count
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawboxes:      push bp
                mov bp, sp
                push cx
                push si

                mov si, [bp+6]
                mov cx, [bp+4]
dbx_loop:       push word [si]
                push word [si+2]
                push word [si+4]
                push word [si+6]
                push word [si+8]
                call fillrect
                add si, 10
                loop dbx_loop

                pop si
                pop cx
                pop bp
                ret 4

; ------------------------------------------------------------
; PROCEDURE: setstate
; Purpose : changes the game state and clears the key-press flags
; Inputs  : [bp+4] = new state
; Outputs : state changed
; Changes : no register is changed
; ------------------------------------------------------------
setstate:       push bp
                mov bp, sp
                push ax
                push cx
                push di
                push es

                mov ax, [bp+4]
                mov [state], ax
                push ds
                pop es
                cld
                mov di, keyhit
                mov cx, 64
                mov ax, 0
                rep stosw               ; clear 128 bytes

                pop es
                pop di
                pop cx
                pop ax
                pop bp
                ret 2

; ------------------------------------------------------------
; PROCEDURE: newgame
; Purpose : score 0, coins 0, lives 3, level reset
; Inputs  : none
; Outputs : game variables reset
; Changes : no register is changed
; ------------------------------------------------------------
newgame:        mov word [score_lo], 0
                mov word [score_hi], 0
                mov word [coins], 0
                mov word [lives], START_LIVES
                call restartlevel
                ret

; ------------------------------------------------------------
; PROCEDURE: killmario
; Purpose : Mario dies: lives - 1, then LIFE LOST screen,
;           or GAME OVER when no life is left
; Inputs  : none
; Outputs : lives, state changed
; Changes : no register is changed
; ------------------------------------------------------------
killmario:      push ax

                cmp word [state], 1
                jne kmn_end             ; only while playing
                mov word [hero_h], 16   ; draw small Mario in the animation
                mov word [hero_vx], 0
                mov word [hero_vy], 0xFB00      ; hop up (-5.0)
                cmp word [hero_y], 200
                jb kmn_go
                mov word [hero_vy], 0           ; pit death: no hop
kmn_go:         mov word [die_t], 0
                mov ax, 3               ; DYING state
                push ax
                call setstate
kmn_end:        pop ax
                ret
; ------------------------------------------------------------
; STATE HANDLER: st_title  (state 0)
; Purpose : title screen. Up/Down move the > arrow, Enter on
;           START begins a new game, Enter on EXIT or Esc exits
; Inputs  : key-press flags (keyhit), sel
; Outputs : state, sel changed; title picture drawn
; Changes : ax, bx, cx, dx, si, di (not kept; mainloop does not need them)
; ------------------------------------------------------------
st_title:       mov ax, SC_ESC            ; Esc
                push ax
                call gethit
                cmp ax, 1
                jne ti_noesc
                mov ax, 8
                push ax
                call setstate
                ret
ti_noesc:       mov ax, SC_UP            ; Up
                push ax
                call gethit
                cmp ax, 1
                jne ti_noup
                mov word [sel], 0
ti_noup:        mov ax, SC_DOWN            ; Down
                push ax
                call gethit
                cmp ax, 1
                jne ti_nodown
                mov word [sel], 1
ti_nodown:      mov ax, SC_ENTER            ; Enter
                push ax
                call gethit
                cmp ax, 1
                jne ti_draw
                cmp word [sel], 0
                jne ti_exit
                call newgame
                mov ax, 1
                push ax
                call setstate
                ret
ti_exit:        mov ax, 8
                push ax
                call setstate
                ret

ti_draw:        mov ax, title_boxes
                push ax
                mov ax, 5
                push ax
                call drawboxes
                mov ax, title_texts
                push ax
                mov ax, 4
                push ax
                call drawtexts

                mov ax, 40              ; Mario on the grass
                push ax
                mov ax, 144
                push ax
                mov ax, spr_mario_stand
                push ax
                mov ax, 0
                push ax
                call drawsprite
                mov ax, 260             ; Goomba
                push ax
                mov ax, 144
                push ax
                mov ax, spr_goomba
                push ax
                mov ax, 0
                push ax
                call drawsprite

                mov bx, 90              ; the > arrow
                cmp word [sel], 0
                je ti_arrow
                mov bx, 108
ti_arrow:       mov ax, 104
                push ax
                push bx
                mov ax, str_arrow
                push ax
                mov ax, 14
                push ax
                call drawtext

                call copybuf
                ret

; ------------------------------------------------------------
; STATE HANDLER: st_playing  (state 1)
; Purpose : one frame of the game in the order of section 5.13.
;           P = pause, Esc = title
; Inputs  : keys, hero, enemies, map, clock
; Outputs : all game variables; the frame is drawn and copied
; Changes : ax, bx, cx, dx, si, di (not kept; mainloop does not need them)
; ------------------------------------------------------------
st_playing:     mov ax, SC_P            ; P
                push ax
                call gethit
                cmp ax, 1
                jne pl_nopause
                mov ax, 2
                push ax
                call setstate
                ret
pl_nopause:     mov ax, SC_ESC            ; Esc
                push ax
                call gethit
                cmp ax, 1
                jne pl_noesc
                mov ax, 0
                push ax
                call setstate
                ret
pl_noesc:
                call updatehero
                call updatecamera
                call updatemushroom
                call updatepop
                call updateenemies
                call collectcoins
                call updateclock
                call debugkeys
                call debugflag
                call checkflag

                call clearbuf
                push word [camera_x]
                call drawmapscroll

                cmp word [mush_on], 1
                jne nomush
                mov ax, [mush_x]
                sub ax, [camera_x]
                push ax
                push word [mush_y]
                mov ax, spr_mushroom
                push ax
                mov ax, 0
                push ax
                call drawsprite
nomush:
                cmp word [pop_on], 1
                jne nopop
                mov ax, [pop_x]
                sub ax, [camera_x]
                push ax
                push word [pop_y]
                mov ax, spr_coin
                push ax
                mov ax, 0
                push ax
                call drawsprite
nopop:
                call drawenemies

                cmp word [invuln], 0    ; blink while invulnerable
                je drawmario1
                test word [invuln], 2
                jnz drawmario1
                jmp herodone
drawmario1:
                cmp word [hero_h], 32
                je drawsuperhero

                mov bx, spr_mario_stand
                cmp word [hero_vx], 0
                je pose_nomove
                mov bx, spr_mario_run
pose_nomove:    cmp word [on_ground], 1
                je pose_done
                mov bx, spr_mario_jump
pose_done:      mov ax, [hero_x]
                sub ax, [camera_x]
                push ax
                mov ax, [hero_y]
                sub ax, 16
                push ax
                push bx
                push word [facing]
                call drawsprite
                jmp herodone

drawsuperhero:  mov bx, spr_super_stand_bot
                cmp word [hero_vx], 0
                je sp_nomove
                mov bx, spr_super_run_bot
sp_nomove:      cmp word [on_ground], 1
                je sp_done
                mov bx, spr_super_jump_bot
sp_done:        mov ax, [hero_x]
                sub ax, [camera_x]
                push ax
                mov ax, [hero_y]
                sub ax, 32
                push ax
                push bx
                push word [facing]
                call drawsuper
herodone:
                call drawhudfull
                call copybuf
                ret

; ------------------------------------------------------------
; STATE HANDLER: st_paused  (state 2)
; Purpose : the last picture stays in the frame buffer, a PAUSED box
;           is drawn over it. P = resume, Esc = title
; Inputs  : key-press flags (keyhit)
; Outputs : state changed; pause box drawn
; Changes : ax, bx, cx, dx, si, di (not kept; mainloop does not need them)
; ------------------------------------------------------------
st_paused:      mov ax, SC_P            ; P
                push ax
                call gethit
                cmp ax, 1
                jne pa_nop
                mov ax, 1
                push ax
                call setstate
                ret
pa_nop:         mov ax, SC_ESC            ; Esc
                push ax
                call gethit
                cmp ax, 1
                jne pa_draw
                mov ax, 0
                push ax
                call setstate
                ret
pa_draw:        mov ax, pa_boxes
                push ax
                mov ax, 2
                push ax
                call drawboxes
                mov ax, pa_texts
                push ax
                mov ax, 2
                push ax
                call drawtexts
                call copybuf
                ret

; ------------------------------------------------------------
; STATE HANDLER: st_lifelost  (state 4)
; Purpose : shows WORLD 1-1, Mario and the lives left for 2 seconds,
;           then resets the level and goes back to PLAYING
; Inputs  : lives, lifetimer
; Outputs : lifetimer, level variables, state
; Changes : ax, bx, cx, dx, si, di (not kept; mainloop does not need them)
; ------------------------------------------------------------
st_lifelost:    mov ax, ll_boxes
                push ax
                mov ax, 1
                push ax
                call drawboxes
                mov ax, ll_texts
                push ax
                mov ax, 3
                push ax
                call drawtexts

                mov ax, 116
                push ax
                mov ax, 90
                push ax
                mov ax, spr_mario_stand
                push ax
                mov ax, 0
                push ax
                call drawsprite

                mov ax, 164             ; lives number
                push ax
                mov ax, 98
                push ax
                mov ax, 0
                push ax
                push word [lives]
                mov ax, 2
                push ax
                call drawnum32

                call copybuf
                dec word [lifetimer]
                jnz ll_end
                call restartlevel
                mov ax, 1
                push ax
                call setstate
ll_end:         ret

; ------------------------------------------------------------
; STATE HANDLER: st_gameover  (state 7)
; Purpose : shows the final score, coins and time. Enter = title
; Inputs  : score, coins, game_time, key-press flags
; Outputs : state changed; game over picture drawn
; Changes : ax, bx, cx, dx, si, di (not kept; mainloop does not need them)
; ------------------------------------------------------------
st_gameover:    mov ax, SC_ENTER            ; Enter
                push ax
                call gethit
                cmp ax, 1
                jne go_draw
                mov ax, 0
                push ax
                call setstate
                ret
go_draw:        mov ax, go_boxes
                push ax
                mov ax, 3
                push ax
                call drawboxes
                mov ax, go_texts
                push ax
                mov ax, 5
                push ax
                call drawtexts

                mov ax, 136             ; final score
                push ax
                mov ax, 108
                push ax
                push word [score_hi]
                push word [score_lo]
                mov ax, 6
                push ax
                call drawnum32

                mov ax, 144             ; coins
                push ax
                mov ax, 128
                push ax
                mov ax, 0
                push ax
                push word [coins]
                mov ax, 2
                push ax
                call drawnum32

                mov ax, 216             ; time
                push ax
                mov ax, 128
                push ax
                mov ax, 0
                push ax
                push word [game_time]
                mov ax, 3
                push ax
                call drawnum32

                call copybuf
                ret

; --- death and win sequence variables ---
die_t:          dw 0            ; frames of the death animation
winphase:       dw 0            ; 0 = slide down, 1 = walk to castle, 2 = inside
wintimer:       dw 0
win_sh:         dw 0            ; score before the time bonus (high word)
win_sl:         dw 0            ; score before the time bonus (low word)
win_bonus:      dw 0            ; the time bonus

; --- Level Complete texts and boxes ---
str_lvlcomp:    db 'LEVEL COMPLETE!',0
str_timeleft:   db 'TIME LEFT',0
str_timebonus:  db 'TIME BONUS',0
str_50:         db '50',0
str_pressenter: db 'PRESS ENTER TO CONTINUE',0

lc_boxes:       dw 0,0,320,200,1
                dw 30,20,260,160,14
                dw 33,23,254,154,1
lc_texts:       dw 100,36,str_lvlcomp,14
                dw 60,70,str_score,15
                dw 60,86,str_coins,15
                dw 60,102,str_timeleft,15
                dw 204,102,str_xtimes,15
                dw 220,102,str_50,15
                dw 60,118,str_timebonus,15
                dw 60,138,str_final,14
                dw 68,162,str_pressenter,10

; ------------------------------------------------------------
; PROCEDURE: drawcastle
; Purpose : draws a small castle at the end of the level
;           (rectangles only, not solid)
; Inputs  : camera_x
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawcastle:     push ax
                push bx

                mov bx, [camera_x]

                mov ax, 928             ; body
                sub ax, bx
                push ax
                mov ax, 120
                push ax
                mov ax, 32
                push ax
                mov ax, 40
                push ax
                mov ax, 4
                push ax
                call fillrect

                mov ax, 928             ; battlement 1
                sub ax, bx
                push ax
                mov ax, 112
                push ax
                mov ax, 8
                push ax
                push ax
                mov ax, 4
                push ax
                call fillrect

                mov ax, 940             ; battlement 2
                sub ax, bx
                push ax
                mov ax, 112
                push ax
                mov ax, 8
                push ax
                push ax
                mov ax, 4
                push ax
                call fillrect

                mov ax, 952             ; battlement 3
                sub ax, bx
                push ax
                mov ax, 112
                push ax
                mov ax, 8
                push ax
                push ax
                mov ax, 4
                push ax
                call fillrect

                mov ax, 936             ; door
                sub ax, bx
                push ax
                mov ax, 136
                push ax
                mov ax, 16
                push ax
                mov ax, 24
                push ax
                mov ax, 0
                push ax
                call fillrect

                pop bx
                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: drawscene
; Purpose : draws the world without Mario and without the HUD
;           (map, mushroom, popping coin, enemies)
; Inputs  : world variables
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawscene:      push ax

                call clearbuf
                push word [camera_x]
                call drawmapscroll

                cmp word [mush_on], 1
                jne dsc_nomush
                mov ax, [mush_x]
                sub ax, [camera_x]
                push ax
                push word [mush_y]
                mov ax, spr_mushroom
                push ax
                mov ax, 0
                push ax
                call drawsprite
dsc_nomush:     cmp word [pop_on], 1
                jne dsc_nopop
                mov ax, [pop_x]
                sub ax, [camera_x]
                push ax
                push word [pop_y]
                mov ax, spr_coin
                push ax
                mov ax, 0
                push ax
                call drawsprite
dsc_nopop:      call drawenemies

                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: debugflag
; Purpose : debug key F (listed in the README): Mario jumps
;           to the ground near the stairs and the flag pole
; Inputs  : none
; Outputs : hero variables, camera_x changed
; Changes : no register is changed
; ------------------------------------------------------------
debugflag:      push ax

                mov ax, SC_F            ; F
                push ax
                call gethit
                cmp ax, 1
                jne df_end
                mov word [hero_x], 780
                mov word [hero_xf], 0
                mov word [hero_y], 160
                mov word [hero_yf], 0
                mov word [hero_vx], 0
                mov word [hero_vy], 0
                mov word [camera_x], 640
df_end:         pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: checkflag
; Purpose : if Mario touches the flag pole (tile 12), give the
;           points for the height of his feet and start the
;           WIN state. Zones: rows 2-3 = 5000, 4 = 2000,
;           5 = 800, 6-7 = 400, 8 = 100
; Inputs  : hero variables, map
; Outputs : score, state, hero position changed
; Changes : no register is changed
; ------------------------------------------------------------
checkflag:      cmp word [state], 1
                je cf_run
                ret
cf_run:         push ax
                push bx

                mov ax, [hero_x]        ; point 1: feet
                add ax, 13
                push ax
                mov bx, [hero_y]
                dec bx
                push bx
                call gettile
                cmp ax, 12
                je cf_hit

                mov ax, [hero_x]        ; point 2: middle
                add ax, 13
                push ax
                mov bx, [hero_h]
                shr bx, 1
                neg bx
                add bx, [hero_y]
                push bx
                call gettile
                cmp ax, 12
                je cf_hit

                mov ax, [hero_x]        ; point 3: head
                add ax, 13
                push ax
                mov bx, [hero_y]
                sub bx, [hero_h]
                push bx
                call gettile
                cmp ax, 12
                je cf_hit
                jmp cf_end

cf_hit:         mov ax, [hero_y]
                dec ax
                shr ax, 1
                shr ax, 1
                shr ax, 1
                shr ax, 1               ; ax = map row of the feet
                mov bx, 5000
                cmp ax, 3
                jle cf_pts
                mov bx, 2000
                cmp ax, 4
                je cf_pts
                mov bx, 800
                cmp ax, 5
                je cf_pts
                mov bx, 400
                cmp ax, 7
                jle cf_pts
                mov bx, 100
cf_pts:         push bx
                call addscore

                mov word [hero_x], 904  ; Mario sticks to the pole
                mov word [hero_xf], 0
                mov word [hero_vx], 0
                mov word [hero_vy], 0
                mov word [camera_x], 640
                mov word [winphase], 0
                mov word [wintimer], 0
                mov ax, 5               ; WIN state
                push ax
                call setstate
cf_end:         pop bx
                pop ax
                ret

; ------------------------------------------------------------
; PROCEDURE: drawherowin
; Purpose : draws Mario (small or Super) during the win sequence
; Inputs  : hero variables, winphase
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
drawherowin:    push ax
                push bx

                cmp word [hero_h], 32
                je dhw_super

                mov bx, spr_mario_jump          ; small Mario
                cmp word [winphase], 0
                je dhw_small
                mov bx, spr_mario_run
dhw_small:      mov ax, [hero_x]
                sub ax, [camera_x]
                push ax
                mov ax, [hero_y]
                sub ax, 16
                push ax
                push bx
                mov ax, 0
                push ax
                call drawsprite
                jmp dhw_end

dhw_super:      mov bx, spr_super_jump_bot      ; Super Mario
                cmp word [winphase], 0
                je dhw_big
                mov bx, spr_super_run_bot
dhw_big:        mov ax, [hero_x]
                sub ax, [camera_x]
                push ax
                mov ax, [hero_y]
                sub ax, 32
                push ax
                push bx
                mov ax, 0
                push ax
                call drawsuper
dhw_end:        pop bx
                pop ax
                ret

; ------------------------------------------------------------
; STATE HANDLER: st_dying  (state 3)
; Purpose : death animation: Mario hops up and falls out of the screen
;           (gravity, no collisions, everything else frozen). Then
;           lives - 1 and LIFE LOST or GAME OVER
; Inputs  : hero variables, die_t, lives
; Outputs : hero_y, hero_vy, die_t, lives, lifetimer, state
; Changes : ax, bx, cx, dx, si, di (not kept; mainloop does not need them)
; ------------------------------------------------------------
st_dying:       call drawscene

                mov ax, [hero_x]
                sub ax, [camera_x]
                push ax
                mov ax, [hero_y]
                sub ax, 16
                push ax
                mov ax, spr_mario_jump
                push ax
                mov ax, [facing]
                push ax
                call drawsprite

                call drawhudfull
                call copybuf

                mov ax, [hero_vy]       ; gravity
                add ax, 0x0040
                cmp ax, MAX_FALL
                jle sd_vyok
                mov ax, MAX_FALL
sd_vyok:        mov [hero_vy], ax
                mov ax, hero_y
                push ax
                mov ax, hero_yf
                push ax
                push word [hero_vy]
                call addfixed

                inc word [die_t]
                cmp word [die_t], 20
                jl sd_end
                cmp word [hero_y], 216
                jl sd_end

                dec word [lives]        ; animation finished
                mov word [lifetimer], 60
                mov ax, 4               ; LIFE LOST
                cmp word [lives], 0
                jne sd_set
                mov ax, 7               ; GAME OVER
sd_set:         push ax
                call setstate
sd_end:         ret

; ------------------------------------------------------------
; PROCEDURE: winslide
; Purpose : Mario slides down the pole (4 pixels per frame)
;           until his feet reach the base block (y = 144)
; Inputs  : hero_y
; Outputs : hero_y changed; winphase = 1 when the base is reached
; Changes : no register is changed
; ------------------------------------------------------------
winslide:       add word [hero_y], 4
                cmp word [hero_y], 144
                jl wsl_end
                mov word [hero_y], 144
                mov word [winphase], 1
wsl_end:        ret

; ------------------------------------------------------------
; PROCEDURE: winwalk
; Purpose : Mario walks to the castle door (1 pixel per frame),
;           steps down from the base block, then goes inside
; Inputs  : hero_x
; Outputs : hero_x, hero_y changed; winphase = 2 and wintimer = 20
;           when Mario reaches the door
; Changes : no register is changed
; ------------------------------------------------------------
winwalk:        inc word [hero_x]
                cmp word [hero_x], 922
                jl wwk_nodrop
                mov word [hero_y], 160
wwk_nodrop:     cmp word [hero_x], 936
                jl wwk_end
                mov word [winphase], 2
                mov word [wintimer], 20
wwk_end:        ret

; ------------------------------------------------------------
; PROCEDURE: winfinish
; Purpose : adds time left x 50 to the score (MUL) and shows
;           the LEVEL COMPLETE screen
; Inputs  : game_time, score_hi, score_lo
; Outputs : win_sh, win_sl, win_bonus, score changed; state = 6
; Changes : no register is changed
; ------------------------------------------------------------
winfinish:      push ax
                push bx
                push dx

                mov ax, [score_hi]
                mov [win_sh], ax
                mov ax, [score_lo]
                mov [win_sl], ax
                mov ax, [game_time]
                mov bx, 50
                mul bx                  ; ax = time left * 50
                mov [win_bonus], ax
                push ax
                call addscore
                mov ax, 6               ; LEVEL COMPLETE state
                push ax
                call setstate

                pop dx
                pop bx
                pop ax
                ret

; ------------------------------------------------------------
; STATE HANDLER: st_winseq  (state 5)
; Purpose : win sequence. Clock and keys are frozen. Phase 0 = slide
;           down the pole, 1 = walk to the castle, 2 = go inside
; Inputs  : winphase, wintimer, hero variables
; Outputs : hero_x, hero_y, winphase, state
; Changes : ax, bx, cx, dx, si, di (not kept; mainloop does not need them)
; ------------------------------------------------------------
st_winseq:      cmp word [winphase], 0
                jne ws_n0
                call winslide
                jmp ws_draw
ws_n0:          cmp word [winphase], 1
                jne ws_n1
                call winwalk
                jmp ws_draw
ws_n1:          dec word [wintimer]
                jnz ws_draw
                call winfinish
                ret
ws_draw:        call drawscene
                cmp word [winphase], 2
                je ws_nohero
                call drawherowin
ws_nohero:      call drawhudfull
                call copybuf
                ret

; ------------------------------------------------------------
; STATE HANDLER: st_levelcomplete  (state 6)
; Purpose : shows score, coins, time left x 50, bonus and final score.
;           Enter = title. (No extra life for finishing the level.)
; Inputs  : win_sh, win_sl, win_bonus, coins, game_time, score
; Outputs : state changed; level complete picture drawn
; Changes : ax, bx, cx, dx, si, di (not kept; mainloop does not need them)
; ------------------------------------------------------------
st_levelcomplete:
                mov ax, SC_ENTER            ; Enter
                push ax
                call gethit
                cmp ax, 1
                jne lc_draw
                mov ax, 0
                push ax
                call setstate
                ret
lc_draw:        mov ax, lc_boxes
                push ax
                mov ax, 3
                push ax
                call drawboxes
                mov ax, lc_texts
                push ax
                mov ax, 9
                push ax
                call drawtexts

                mov ax, 172             ; score before the bonus
                push ax
                mov ax, 70
                push ax
                push word [win_sh]
                push word [win_sl]
                mov ax, 6
                push ax
                call drawnum32

                mov ax, 172             ; coins
                push ax
                mov ax, 86
                push ax
                mov ax, 0
                push ax
                push word [coins]
                mov ax, 2
                push ax
                call drawnum32

                mov ax, 172             ; time left
                push ax
                mov ax, 102
                push ax
                mov ax, 0
                push ax
                push word [game_time]
                mov ax, 3
                push ax
                call drawnum32

                mov ax, 172             ; time bonus
                push ax
                mov ax, 118
                push ax
                mov ax, 0
                push ax
                push word [win_bonus]
                mov ax, 6
                push ax
                call drawnum32

                mov ax, 172             ; final score
                push ax
                mov ax, 138
                push ax
                push word [score_hi]
                push word [score_lo]
                mov ax, 6
                push ax
                call drawnum32

                call copybuf
                ret
; ------------------------------------------------------------
; STATE HANDLER: st_exit
; Purpose : does nothing; mainloop sees state 8 and leaves
;           the loop, then restores everything and exits to DOS
; Inputs  : none
; Outputs : none
; Changes : no register is changed
; ------------------------------------------------------------
st_exit:
                ret

; ------------------------------------------------------------
; MAIN - program start, main loop and clean exit
; ------------------------------------------------------------
start:          mov ax, 0x0013          ; VGA mode 13h
                int 0x10

                mov ax, ds              ; frame buffer = free segment
                add ax, 0x1000
                mov [bufseg], ax
                mov [drawseg], ax

                call newgame
                call installkb
                call installtimer
                call setrate30
                mov ax, 0               ; start in the TITLE state
                push ax
                call setstate

mainloop:       mov ax, [tickcount]     ; wait for the next timer tick
waitframe:      cmp ax, [tickcount]
                je waitframe

                mov bx, [state]
                shl bx, 1
                call word [statetable+bx]       ; jump table

                cmp word [state], 8
                jne mainloop

                call restorerate
                call restoretimer
                call restorekb

                mov ax, 0x0003          ; back to text mode
                int 0x10
                mov ax, 0x4c00          ; exit to DOS
                int 0x21