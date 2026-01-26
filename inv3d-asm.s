#define TEXTADDRESS $BB80
#define HIRESADDRESS $a000
#define TEXTCHAR $b400
#define HIRESCHAR $9800

#define stateAttract    0
#define stateInitGame   1
#define statePlayGame   2
#define stateNextLevel  3
#define stateLoseLife   4
#define stateInstruct   5

#define ztmp24      $3d
#define lineoffset  $32
#define ztSprPtr    ztmp24+0
#define ztWidth     ztmp24+2
#define ztHeight    ztmp24+3
#define ztSize      ztmp24+4
#define screenAddr $00
#define screenPixMode $02
#define screenMask $03
#define screenTmp $04

#define hiresText       $bf68
#define scoreAddress    $bf68+40*0+8
#define livesAddress    $bf68+40*0+20
#define enemiesBar      $bf68+40*1+24
#define base            $a000+199*40
#define horizon         80
#define perspective     4
#define leftMargin      10
#define rightMargin     210


;
; Hires bit mask to bit position look up
; 1=pos 5*2+7, 2=pos 4*2+7, 4=pos 3*2+7
; 8=pos 2*2+7,16=pos 1*2+7,32=pos 0*2+7
maskLookUp
    .byt  0,17,15,0, 13, 0, 0, 0
    .byt  11,0, 0, 0, 0, 0, 0, 0
    .byt  9, 0, 0, 0, 0, 0, 0, 0
    .byt  0, 0, 0, 0, 0, 0, 0, 0
    .byt  7, 0, 0, 0, 0, 0, 0, 0

; Bar sizes
barLookUp
    .dsb 200

;Message handling
msgSpeed    .byt 6
msgCount    .byt 0
msgIdx      .byt 0
msg         .byt "Galaxy Defender 3023, written in C using Oric Software develo"
            .byt "pment kit (OSDK). Hello to all Oric fans! By @6502Nerd :-)   ",0
;
; Game Variables
colour              .byt 0
scoreTick           .word 0
makeW               .byt 0
makeH               .byt 0
makeS               .byt 0
_spriteMask         .byt 0
frameCount          .byt 0
heightCount         .byt 0
_alienLevelSpeed    .byt 0
alienSpeed          .byt 0
alienSpeedCount     .byt 0
alienIdx            .byt 0
_alien2Delay        .byt 0
alien2DelayCount    .byt 0
alienExploding      .byt 0
alienDX             .word 0,0,0
alienDY             .word 0,0,0
alienX              .word 0,0,0
alienY              .word 0,0,0
lastAlienFrame      .word 0,0,0
explodeX            .word 0,0,0
explodeY            .word 0,0,0
explodeVol          .word 0,0,0
explodeFrame        .word 0,0,0
_xPos               .word 0
_yPos               .word 0
_dx                 .word 0
_dy                 .word 0
_xStep              .word 0
_yStep              .word 0
_friction           .word 0
ox                  .word 0
oy                  .word 0
_bulletX            .word 0
_bulletY            .word 0
bulletDX            .word 0
bulletDY            .word 0
lastBulletFrame     .word 0

_initBarLookUp
    ldy #0
initBarLoop
    jsr calcBarLookup
    sta barLookUp,y
    iny
    cpy #200
    bne initBarLoop
    rts

_invertPaper
    ldy #0;
    lda (sp),y
    pha
    lda #0
    sta invertLineEOR+1
    sta invertLineSTA+1
    lda #$a0
    sta invertLineEOR+2
    sta invertLineSTA+2
invertCounter
    ldy #200
invertLine
    pla
    pha
invertLineEOR
    eor $1234          ; Self modifying code
invertLineSTA
    sta $1234          ; Self modifying code
    clc
    lda invertLineEOR+1
    adc #40
    sta invertLineEOR+1
    sta invertLineSTA+1
    lda invertLineEOR+2
    adc #0
    sta invertLineEOR+2
    sta invertLineSTA+2
    dey
    bne invertLine
    pla
    rts
;
_initLand
 ; Start painting from bottom
    ldy #199
    lda #<base
    sta drawLineAbs+1
    lda #>base
    sta drawLineAbs+2
 ; Initialise bar size
    jsr calcBarSize
    cpx _startOffset
    bcs skipInitReset
; Needs to flip immediately
    lda #0
    sta _startOffset
    lda _colourFlip
    eor #1
    sta _colourFlip
skipInitReset
    sec
    txa
    sbc _startOffset
    tax
    lda _colourFlip
    bne initAltColour
    lda _startColour
    bne skipInitAltColour
initAltColour
    lda _altColour
skipInitAltColour
    sta colour
    lda _colourFlip
    pha
drawLand
doLineColour
    lda colour
drawLineAbs
    sta $1234:; Self modifying code
    ; Decrement y
    dey
    ; Update line address
    sec
    lda drawLineAbs+1
    sbc #40
    sta drawLineAbs+1
    lda drawLineAbs+2
    sbc #0
    sta drawLineAbs+2
 ; Decrement bar size counter
    dex
    bpl skipReset
 ; Reset current bar size in X
    jsr calcBarSize
 ; Flip colour
    lda _colourFlip
    eor #1
    sta _colourFlip
    bne useAltColour
    lda _startColour
    bne skipUseAltColour
useAltColour
    lda _altColour
skipUseAltColour
    sta colour
skipReset
    cpy #horizon
    bcs drawLand
    inc _startOffset
    inc _startOffset
    inc _startOffset
    pla
    sta _colourFlip
    rts
;
; Calculate new bar size (y-reg-horizon+2)/4
calcBarSize
    ldx barLookUp,y
    rts
calcBarLookup
    sec
    tya
    sbc #horizon
    clc
    adc #2
    lsr
    lsr
    tax
    rts
;
initLoop
 ; Reset some variables
    lda #0
    sta alienIdx
    sta _bulletY+1
    sta alienExploding
    ldx #4
initAlien
    sta explodeVol,x
    sta alienY+1,x
    dex
    dex
    bpl initAlien
    lda _alien2Delay
   adc #10
    sta alien2DelayCount
 ; Alien speed based on level
    lda _alienLevelSpeed
    sta alienSpeed
    sta alienSpeedCount
 ; Score tick is 20*(level+1) in BCD
    sed
    clc
    lda #0
    sta scoreTick
    sta scoreTick+1
    ldx #20
mult_tick
    sec
    lda scoreTick
    adc _level
    sta scoreTick
    lda scoreTick+1
    adc #0
    sta scoreTick+1
    dex
    bne mult_tick
    cld
    rts
;
; do one loop
_loopLand
    jsr initLoop
    jsr initMsg
    jsr initT2
gameLoop
    jsr timeoutT2
    jsr showMsg
    jsr _initLand
    jsr bulletUpdate
    jsr alienUpdate
    jsr checkBulletHit
 ; *This needs to be the last routine!*
    jsr playerUpdate
 ; Keep looping unless status has changed from 2
    lda _state
    cmp #statePlayGame
    beq gameLoop
    lda alienExploding
    bne gameLoop
 ; Erase aliens and bullets from screen
    lda #$40
    jsr drawBullet
    ldx #4
    stx alienIdx
eraseAliens
    lda #$40
    jsr drawAlien
    dec alienIdx
    dec alienIdx
    bpl eraseAliens
    rts
;
; Play sound using A=joystick (channel A)
playerSound
 ; Volume register A
    ldx #8
    and #3
    beq playerSilent
    lda #7
    jmp sndset
playerSilent
    lda #0
    jmp sndset
;
; Play explosion sound (channel C)
explodeSound
    ldx alienIdx
    lda explodeVol,x
    beq explodeSkip
    dec explodeVol,x
    lda explodeVol,x
    bne skipDecExploding
    dec alienExploding
skipDecExploding
 ; Volume register C attenuated
    ldx #10
    jsr sndset
    cmp #0
    beq explodeErase
    and #1
    beq explodeFlash
    lda #%01110011
    .byt $2c
explodeFlash
    lda #%01001100
explodeErase
    sta _spriteMask
    ldx alienIdx
    lda explodeFrame,x
    pha
    lda explodeX,x
    ldy explodeY,x
    tax
    pla
    jsr drawSprite
explodeSkip
    rts
;
; Initialise Timer 2
initT2
    lda #$4009&255
    sta $300+8
    lda #$4009>>8
    sta $300+9
    rts
;
; Wait for T2 timeout and re-start
timeoutT2
    lda $300+13
    and #$20
    beq timeoutT2
    jmp initT2

; C callable interface for drawSprite(sprNum, X, Y)
_drawSprite
	ldy #0							; Get spr num
	lda (sp),y
    pha
	ldy #2							; Get X coord
	lda (sp),y
	tax
    ldy #4							; Get Y coord
	lda (sp),y
    tay
    pla
; Draw sprite indexed in A at pos x,y
drawSprite
    pha
 ; Get line base and offset
    jsr gr_point_setup
    sty lineoffset
 ; Get sprite address
    pla
    asl
    tax
    lda _sprTable,x
    sta ztSprPtr;         	+0 = sprite pointer L
    lda _sprTable+1,x
    sta ztSprPtr+1;     	+1 = sprite pointer H
 ; Now save the width, height and size
    ldy #0
    lda (ztSprPtr),y
    sta ztWidth             ;     	+2 = width
    iny
    lda (ztSprPtr),y
    sta ztHeight        ;        	+3 = height
    iny
    lda (ztSprPtr),y
    sta ztSize            ;        	+4 = size
 ; Get sprite position pointer
    ldx screenMask
    ldy maskLookUp,x
 ; Initialise self-modifying addresses
    lda (ztSprPtr),y
    sta source1-2
    sta source2-2
    iny
    lda (ztSprPtr),y
    sta source1-1
    sta source2-1
 ; Set up line base with offset
    clc
    lda screenAddr
    adc lineoffset
    sta dest1-2
    sta dest2-2
    lda screenAddr+1
    adc #0
    sta dest1-1
    sta dest2-1
 ; Number of rows to do
    ldx ztHeight
nextSpriteRow
 ; Poke from right to left starting at width
    ldy ztWidth
plotSpriteRow
    lda $ffff,y:source1
    and _spriteMask
    sta $ffff,y:dest1
    dey
    bne plotSpriteRow
 ; Now plot the attribute
    lda $ffff:source2
    sta $ffff:dest2
 ; Increment sprite pointer by width+1
    sec
    lda source1-2
    adc ztWidth
    sta source1-2
    sta source2-2
    lda source1-1
    adc #0
    sta source1-1
    sta source2-1
 ; Move screen down by 40
    clc
    lda dest1-2
    adc #40
    sta dest1-2
    sta dest2-2
    lda dest1-1
    adc #0
    sta dest1-1
    sta dest2-1
 ; Keep going until all rows done
    dex
    bne nextSpriteRow
    rts
;
; Create a hitbox
; x,y = coord, A=sprite #
makeHitBox
 ; Save x in +2 and +4
 ; Save y in +3 and +5
    stx ztmp24+2
    stx ztmp24+4
    sty ztmp24+3
    sty ztmp24+5
 ; Index in to sprite table
    asl
    tax
 ; Get pointer to sprite
    lda _sprTable,x
    sta ztmp24          ;         	+0 = sprite pointer L
    lda _sprTable+1,x
    sta ztmp24+1            ;     	+1 = sprite pointer H
 ; Point to left coord add to origin x			+2 = box left
    ldy #3
    clc
    lda ztmp24+2
    adc (ztmp24),y
    sta ztmp24+2
 ; Point to top coord add to origin y			+3 = box top
    iny
    clc
    lda ztmp24+3
    adc (ztmp24),y
    sta ztmp24+3
 ; Point to right coord add to origin x			+4 = box right +1
    iny
    sec
    lda ztmp24+4
    adc (ztmp24),y
    sta ztmp24+4
 ; Point to top coord add to origin y			+5 = box bottom +1
    iny
    sec
    lda ztmp24+5
    adc (ztmp24),y
    sta ztmp24+5
    rts
; check x,y against hitbox
; C=1 if inside, C=0 if outside
checkHitBox
    cpx ztmp24+2
    bcc hitBox0
    cpy ztmp24+3
    bcc hitBox0
    cpx ztmp24+4
    bcs hitBox0
    cpy ztmp24+5
    bcs hitBox0
    sec
    rts
hitBox0
    clc
    rts
;
;add scoreTick plus whatever in A (y coord of bullet)
addToScore
; First adjust A to be number 1-9
; ycoord-horizon is range 0-100 ish
; div 8 then if >9 make equal to 9
    sec
    sbc #80
    lsr
    lsr
    lsr
    cmp #10
    bcc skipScoreAdj
    lda #9
skipScoreAdj
//    lda #0      ; ycoord doesn't matter for score now!
    sed
    clc
    adc scoreTick
    adc _score
    sta _score
    lda _score+1
    adc scoreTick+1
    sta _score+1
    cld
    rts
; 
updateScore
    lda _score+1
    pha
    lsr
    lsr
    lsr
    lsr
    ora #"0"
    sta scoreAddress
    pla
    and #$f
    ora #"0"
    sta scoreAddress+1
    lda _score
    pha
    lsr
    lsr
    lsr
    lsr
    ora #"0"
    sta scoreAddress+2
    pla
    and #$f
    ora #"0"
    sta scoreAddress+3
    rts
;
;
initMsg
    lda #8
    sta $bf68+40*2+0
    lda #3
    sta $bf68+40*2+1
    lda #5
    sta msgSpeed
    sta msgCount
    lda #0
    sta msgIdx
    rts
;
showMsg
    dec msgCount
    bne msgDone
    lda msgSpeed
    sta msgCount
    ldy msgIdx
    ldx #0
showMsgLoop
    lda msg,y
    bne writeMsg
    ldy #0
    lda msg,y
writeMsg
    iny
    sta $bf68+40*2+2,x
    inx
    cpx #36
    bne showMsgLoop
    ldy msgIdx
    iny
    lda msg,y
    bne msgSkipReset
    ldy #0
msgSkipReset
    sty msgIdx
msgDone
    rts
;
playerUpdate
    lda _xPos+1
    sta ox+1
    lda _yPos+1
    sta oy+1
    jsr _kb_stick
    pha    
    jsr playerSound
    pla    
    pha
    and #1
    beq skipLeft
  ; Do left dx only if not -2
    lda _dx+1
    cmp #-3&$ff
    beq dxLowerLimit
    sec
    lda _dx
    sbc _xStep
    tay
    lda _dx+1
    sbc _xStep+1
    bpl limitMinusDX
    cmp #-3&$ff
    bcs limitMinusDX
dxLowerLimit
    lda #-3&$ff
    ldy #$80
limitMinusDX
    sta _dx+1
    sty _dx
skipLeft
    pla
    pha
    and #2
    beq skipRight
  ; Do right dx only if not 2
    lda _dx+1
    cmp #2
    beq dxUpperLimit
    clc
    lda _dx
    adc _xStep
    tay
    lda _dx+1
    adc _xStep+1
    bmi limitPlusDX
    cmp #3
    bcc limitPlusDX
dxUpperLimit
    lda #2
    ldy #$80
limitPlusDX
    sta _dx+1
    sty _dx
skipRight
    pla
    pha
    and #16
    beq skipFire
    lda _bulletY+1
    bne skipFire
    jsr startBullet
skipFire
  ; Do _friction in x
    ldy _dx+1
    bmi _frictionXPlus
    sec
    lda _dx
    sbc _friction
    sta _dx
    tya
    sbc _friction+1
    sta _dx+1
    bcs _frictionY
_frictionXZero
    lda #0
    sta _dx
    sta _dx+1
    beq _frictionY
_frictionXPlus
    clc
    lda _dx
    adc _friction
    sta _dx
    tya
    adc _friction+1
    sta _dx+1
    bcs _frictionXZero
_frictionY
  ; Add x velocity to position
    clc
    lda _xPos
    adc _dx
    tya
    lda _xPos+1
    adc _dx+1
    cmp #leftMargin
    bcs skipLeftMargin
    lda #leftMargin
    ldy #$80
    jsr dxNegate
skipLeftMargin
    cmp #rightMargin+1
    bcc skipRightMargin
    lda #rightMargin
    ldy #$80
    jsr dxNegate
skipRightMargin
    sta _xPos+1
    sty _xPos
  ; Add y velocity to position
    clc
    lda _yPos
    adc _dy
    sta _yPos
    lda _yPos+1
    adc _dy+1    
    cmp #100
   bcs skipTopMargin
   lda #10
skipTopMargin
    cmp #185
    bcc skipBottomMargin
    lda #185
skipBottomMargin
    sta _yPos+1
  ; Check old and new positions
    lda _xPos+1
    cmp ox+1    
    bne doUpdate
    lda _yPos+1
    cmp oy+1
    bne doUpdate
  ; first getstick status off stack
    pla    
    rts
dxNegate
    pha
    sec
    lda #0
    sbc _dx
    sta _dx
    lda #0
    sbc _dx+1
    sta _dx+1
    pla
    rts
doUpdate
    lda #$40
    sta _spriteMask
    ldx ox+1
    ldy oy+1
    lda #0
    jsr drawSprite
    lda #$ff
    sta _spriteMask
    ldx _xPos+1
    ldy _yPos+1
    lda #0
    jsr drawSprite
  ; first getstick status off stack
    pla    
    rts
;
; Calculate bullet pos and vel from bottom
; x=position
initBulletPos
    stx _bulletX+1
    stx _bulletX    ;	Scaled integer x pos - use MSB
    txa
    sec
    sbc #10
    sta bulletDX    ; C still set as x >= 10
    lda #(rightMargin-leftMargin)/2
    sbc bulletDX
    sta bulletDX
    lda #0
    sbc #0
    sta bulletDX+1      ; Scaled integer dx
    lda _yPos+1
    sec
    sbc #6
    sta _bulletY+1       ; Y is at ship position-6 use MSB
    rts
;; Start a bullet and show it
startBullet
    lda _xPos+1
    adc #8
    tax
    jsr initBulletPos
    tay                 ; A=Bullet Y pos
    ldx #255
    jsr drawBullet
bulletInactive
    rts
;
; Draw bullet based on mask in A
drawBullet
    sta _spriteMask
 ; Y is vert pos
    ldy _bulletY+1
    beq bulletInactive
    jsr calcBulletFrame
    ldx _bulletX+1
    ldy _bulletY+1
    jmp drawSprite
;
; Check bullet for hit with each alien
checkBulletHit
    lda _state
    cmp #statePlayGame
    bne bulletInactive
    lda #0
    sta alienIdx
checkAlienHit
    ldx alienIdx
    ldy _bulletY+1
    beq skipBulletHit
    ldy alienY+1,x
    beq skipBulletHit
    lda lastAlienFrame,x
    pha
    lda alienX+1,x
    tax
    pla
    jsr makeHitBox
    ldx _bulletX+1
    ldy _bulletY+1
    jsr checkHitBox
    bcs doBulletHit
    iny
    jsr checkHitBox
    bcs doBulletHit
    dey
    dey
    jsr checkHitBox
    bcc skipBulletHit
doBulletHit
    inc alienExploding
    ldx alienIdx
    lda alienY+1,x
    sta explodeY,x
    pha
    lda alienX+1,x
    sta explodeX,x
    lda lastAlienFrame,x
    sta explodeFrame,x
    lda #0
    sta alienY+1,x
    lda #15
    sta explodeVol,x
    lda #$40
    jsr drawBullet
    lda _bulletY+1
    jsr clearBullet
    pla
    jsr addToScore
    jsr updateScore
    lda #" "
    dec _aliensLeft
    ldx _aliensLeft
    sta enemiesBar,x
    beq levelComplete
skipBulletHit
    jsr explodeSound
    ldx alienIdx
    inx
    inx
    stx alienIdx
    cpx #6
    beq allBulletsDone
    jmp checkAlienHit
allBulletsDone
    rts
levelComplete
    lda #stateNextLevel
    sta _state
    rts
 ;
 ;
bulletUpdate
    ldy _bulletY+1
    beq skipBulletUpdate
    lda #$40
    jsr drawBullet
    lda _bulletY+1
    jsr calcDY
    sty bulletDY+1
    jsr moveBulletUp
    ldy #horizon
    cpy _bulletY+1
    bcs clearBullet
    lda #$ff
    jsr drawBullet
    jmp bulletSound
clearBullet
    lda #0
    sta _bulletY+1
    jmp bulletSilent
skipBulletUpdate
    rts
; Play laser sound using bullet Y pos (channel B)
bulletSound
    lda _bulletY+1
    sec
    lda #255
    sbc _bulletY+1
 ; Fine freq register B
    ldx #2
    jsr sndset
 ; Volume register B attenuated
    ldx #9
    lda _bulletY+1
    lsr
    lsr
    lsr
    lsr
    jmp sndset
;
bulletSilent
 ; Set volume B to zero
    ldx #9
    lda #0
    jmp sndset
;
; Move bullet by Y rows up, adjusting X position
; y=how many rows
moveBulletUp
    clc
    lda _bulletX    
    adc bulletDX
    sta _bulletX    
    lda _bulletX+1
    adc bulletDX+1
    sta _bulletX+1
    dec _bulletY+1
    dey:bne moveBulletUp
    rts
;
; Calculate bullet frame, Y=coordinate
; output A=frame index
calcBulletFrame
    jsr calcSpriteFrame
    clc
    adc #15
    sta lastBulletFrame
    rts
;
; Calculate bullet pos and vel from bottom
; x=position
initAlienPos
    txa
    ldx alienIdx
    sta alienX+1,x
    sta alienX,x               ;	Scaled integer x pos - use MSB
    sec
    sbc #120
    sta alienDX,x               ; x-midpoint
    lda #0
    sbc #0
    sta alienDX+1,x             ; Scaled integer dx
    asl alienDX,x
    rol alienDX+1,x             ; dx=dx*2
    asl alienDX,x
    rol alienDX+1,x             ; dx=dx*2
    asl alienDX,x
    rol alienDX+1,x             ; dx=dx*2
    lda #horizon
    sta alienY+1,x              ; Y is at horizon use MSB
    rts
;
; Draw alien based on mask in A. If y=0 then do nothing
drawAlien
    sta _spriteMask
    ldx alienIdx
    ldy alienY+1,x:beq alienInactive
    lda alienX+1,x:sta drawAlienTmp
    jsr calcSpriteFrame
    clc
    adc #1
    ldx alienIdx
    sta lastAlienFrame,x
    ldx drawAlienTmp
    jmp drawSprite
alienInactive
    rts
drawAlienTmp
    .byt 0
;
alienUpdate
 ; Only move alien based on speed counter
    dec alienSpeedCount
    bne skipAlienMove
    lda alienSpeed
    sta alienSpeedCount
    ldy alien2DelayCount
    beq skipAlien2Dec
    dey
    sty alien2DelayCount
skipAlien2Dec
    lda #$40
    jsr drawAllAliens
    lda #4
    sta alienIdx
move1Alien
    jsr moveAlienDown
    jsr spawnAlien
    dec alienIdx
    dec alienIdx
    bpl move1Alien
skipAlienMove
    lda #$ff
    jsr drawAllAliens
    rts
;
; A=sprite mask
drawAllAliens
    pha
    lda #0
    sta alienIdx
    pla
    pha
    jsr drawAlien
    lda #2
    sta alienIdx
    pla
    pha
    jsr drawAlien
    lda #4
    sta alienIdx
    pla
    pha
    jsr drawAlien
    pla
    rts
;
spawnAlien
    ldx alienIdx
    lda alienY+1,x
    bne noSpawn
    ldy alien2DelayCount
    bne noSpawn
doSpawn
    ldy _alien2Delay
   sty alien2DelayCount
    jmp restartAlien
noSpawn
    rts
;
restartAlien
    lda IRQCounter            ; LSB of interrupt timer
    and #63
    clc
    adc #(120-32)
    tax
    jsr initAlienPos
    lda #$ff
    jmp drawAlien  
;
; Move alien by Y rows down, adjusting X position
; y=how many down
moveAlienDown
    ldx alienIdx
    lda alienY+1,x
    beq skipLoseLife
    jsr calcDY
    tya
    sta alienDY+1,x
alienDown1Row
    clc
    lda alienX,x
    adc alienDX,x
    sta alienX,x
    lda alienX+1,x
    adc alienDX+1,x
    sta alienX+1,x
    inc alienY+1,x
    dey
    bne alienDown1Row
 ; bounce check
    lda #24
    cmp alienX+1,x
    bcs alienBounce
    lda #200
    cmp alienX+1,x
    bcc alienBounce
    bcs alienAtBottomCheck
 ; Stop alien going off the side!
 ; 2s complement DX
alienBounce
    lda alienDX+1,x
    eor #$ff
    sta alienDX+1,x
    lda alienDX,x
    eor #$ff
    clc
    adc #1
    sta alienDX,x
    lda alienDX+1,x
    adc #0
    sta alienDX+1,x
 ; Bounds check
alienAtBottomCheck
    lda alienY+1,x
    cmp #186
    bcc skipLoseLife
    lda #0
    sta alienY+1,x          ;Disable alien
 ; Lost a life if alien got to bottom!
    lda #" "
    dec _lives
    ldx _lives
    sta livesAddress,x
    lda #stateLoseLife
    sta _state
skipLoseLife
    rts
;
; Calculate Y velocity based on A=Y coordinate
; Output in Y
calcDY
    sec
    sbc #horizon
    lsr
    lsr
    lsr
    lsr
    tay
    iny
    rts
;
; Calculate sprite frame, Y=coordinate
; output A=frame index
calcSpriteFrame
    tya
    sec
    sbc #horizon            ;			y-horizon
    lsr
    lsr
    lsr                     ;						/8
    rts
