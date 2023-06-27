org 100h    

;subbyte process

subbytes MACRO input, sbox
    local Lsubbytes
    mov si, 00H 
    Lsubbytes:
    mov al, input[si] 
    index 
    mov al, sbox[di]
    mov input[si], al
    inc si
    cmp si, 16D 
    jnz Lsubbytes
           
ENDM

index MACRO  
    mov ah, al 
    AND al, 00FH
    AND ah, 0F0H
    shr ah, 04H
    sal ah, 04H 
    add al,ah    
    xor ah,ah     
    mov di,ax 
    
ENDM  

;shifting rows process

shiftingrow MACRO input 
    sal si, 02H
    mov al, input[si]
    inc si
    mov ah, input[si]
    dec si
    mov input[si], ah
    add si, 02H
    mov ah, input[si]
    dec si
    mov input[si], ah 
    add si, 02H
    mov ah, input[si]
    dec si
    mov input[si], ah
    inc si
    mov input[si], al   
ENDM

shiftrows MACRO input
    local Lshiftrows
    push cx 
    mov si, 01H 
    mov cx, si
    Lshiftrows: 
    push si   
    shiftingrow input
    pop si 
    Loop Lshiftrows
    inc si
    mov cx, si 
    cmp si, 04H
    jnz Lshiftrows  
    pop cx
ENDM

;keyschedule process

rotword Macro key, outputkey 
    local Lrotword
    mov di, 00H
    mov si, 07H
    Lrotword:  
    mov al, key[si]
    mov outputkey[di], al 
    add si, 04H
    add di, 04H 
    cmp di, 0CH
    jnz Lrotword
    mov si, 03H
    mov al, key[si]
    mov outputkey[di], al 
ENDM


subbytekey MACRO outputkey, sbox
    local Lsubbytekey
    mov si, 00H 
    Lsubbytekey:
    mov al, outputkey[si] 
    index 
    mov al, sbox[di]
    mov outputkey[si], al
    add si, 04H
    cmp si, 16D 
    jnz Lsubbytekey
ENDM

process MACRO key, outputkey, rcon
    local Lprocess
    pop si
    mov di, si
    push si 
    mov si, 00H
    Lprocess: 
    mov bl, rcon[di]
    mov bh, key[si] 
    xor bh, bl
    mov bl, outputkey[si] 
    xor bh, bl  
    mov outputkey[si], bh
    add si, 04H 
    add di, 0AH
    cmp si, 16D
    jnz Lprocess
ENDM
 
process2 MACRO key, outputkey
    local Lprocess2, END  
    mov cx, 04H
    mov si, 00H
    push si
    Lprocess2:
    mov bl, outputkey[si] 
    inc si
    mov bh, key[si]
    xor bh, bl
    mov outputkey[si], bh 
    dec si
    add si, 04H
    Loop Lprocess2
    mov cx, 04H
    pop si
    inc si
    push si
    cmp si, 03H
    jnz Lprocess2
    pop SI
END:     
ENDM


keyschedule MACRO key, outputkey, rcon, sbox
    
    rotword key, outputkey 
    subbytekey outputkey, sbox
    process key, outputkey, rcon 
    process2 key, outputkey
    overriding key, outputkey
     
        
ENDM

;mix columns process

two MACRO x   
    local multiplyone, multiply,END
    mov ah, x
    add ah, 00H
    js multiplyone 
    jmp multiply 
    
    multiplyone:
    mov al, 1BH
    sal ah, 01H
    xor ah, al
    JMP END
    multiply:
    sal ah, 01H
END:
ENDM

three MACRO x
    mov bh, x
    two bh
    xor ah, bh 
ENDM

xoring MACRO x
    local END
    cmp si, 00H
    jnz isnotzero
    jmp do
    
    isnotzero:
    cmp si, 04H
    jnz isnotfour 
    jmp do
    
    isnotfour:
    cmp si, 08H
    jnz isnoteight
    jmp do
    
    isnoteight:
    cmp si, 0CH
    jnz do2
    jmp do
    
    do:
    mov dh, ah
    JMP END
    do2:
    xor dh, ah 
    
END:
ENDM  

mixcolumnshelper MACRO input , output, mix 
    Local Lmix,mult2,mult3,other,do3
    push bx
    mov cx, 00H
    Lmix: 
    mov ah, input[di]
    mov al, mix[si]
    cmp al, 02H
    jz mult2
    jmp other
    mult2:
    two ah
    other:
    cmp al, 03H
    jz mult3 
    jmp do3
    mult3:
    three ah 
    do3:
    xoring ah
    inc si
    add di, 04H
    inc cx
    cmp cx, 04H
    jnz Lmix  
    mov di, bp
    mov output[di], dh 
    inc bp
    pop bx
ENDM

mixcolumns MACRO input, output, mix 
    local Lmix2, Lmix3
    mov cx, 00H
    mov bp, 00H 
    Lmix3:
    mov si, cx
    sal si, 02H 
    push cx  
    mov bx, 00H
    Lmix2: 
    mov di, bx
    mixcolumnshelper input, output, mix 
    pop cx
    mov si, cx
    sal si, 02H
    push cx
    inc bx
    cmp bx, 04H
    jnz Lmix2
    pop cx
    inc cx
    cmp cx, 04H
    jnz Lmix3 
    overriding input, output
ENDM

;round key process

roundkey MACRO input, key
    local Lround 
    mov si, 00H  
    Lround:
    mov ah, input[si]
    mov al, key[si]
    xor ah, al
    mov input[si], ah
    inc si
    cmp si, 16D
    jnz Lround  
ENDM

;overriding

overriding MACRO input, output  
    local Loverriding
    mov si, 00H
    Loverriding:
    mov al, output[si]
    mov input[si], al
    inc si
    cmp si, 16D
    jnz Loverriding
ENDM



.data segment
    
    output DB 00H,00H,00H,00H
           DB 00H,00H,00H,00H
           DB 00H,00H,00H,00H
           DB 00H,00H,00H,00H 
    
    input DB 032H,088H,031H,0E0H
          DB 043H,05AH,031H,037H
          DB 0F6H,030H,098H,007H
          DB 0A8H,08DH,0A2H,034H
          
    input1 DB 0EBH,059H,08BH,01BH
           DB 040H,02EH,0A1H,0C3H
           DB 0F2H,038H,013H,042H
           DB 01EH,084H,0E7H,0D2H
           
    outputkey DB 00H,00H,00H,00H
              DB 00H,00H,00H,00H
              DB 00H,00H,00H,00H
              DB 00H,00H,00H,00H
        
     key DB 02BH,028H,0ABH,009H
         DB 07EH,0AEH,0F7H,0CFH
         DB 015H,0D2H,015H,04FH
         DB 016H,0A6H,088H,03CH 
        
     key1 DB 0ACH,019H,028H,057H
          DB 077H,0FAH,0D1H,05CH
          DB 066H,0DCH,029H,000H
          DB 0F3H,021H,041H,06EH    
        
        
    
    mix DB 02H,03H,01H,01H
        DB 01H,02H,03H,01H
        DB 01H,01H,02H,03H
        DB 03H,01H,01H,02H     
               
               
    rcon DB 01H,02H,04H,08H,10H,20H,40H,80H,1BH,36H
         DB 00H,00H,00H,00H,00H,00H,00H,00H,00H,00H
         DB 00H,00H,00H,00H,00H,00H,00H,00H,00H,00H
         DB 00H,00H,00H,00H,00H,00H,00H,00H,00H,00H
      
    
    sbox DB 063H,07cH,077H,07bH,0f2H,06bH,06fH,0c5H,030H,001H,067H,02bH,0feH,0d7H,0abH,076H
         DB 0caH,082H,0c9H,07dH,0faH,059H,047H,0f0H,0adH,0d4H,0a2H,0afH,09cH,0a4H,072H,0c0H
         DB 0b7H,0fdH,093H,026H,036H,03fH,0f7H,0ccH,034H,0a5H,0e5H,0f1H,071H,0d8H,031H,015H
         DB 004H,0c7H,023H,0c3H,018H,096H,005H,09aH,007H,012H,080H,0e2H,0ebH,027H,0b2H,075H
         DB 009H,083H,02cH,01aH,01bH,06eH,05aH,0a0H,052H,03bH,0d6H,0b3H,029H,0e3H,02fH,084H
         DB 053H,0d1H,000H,0edH,020H,0fcH,0b1H,05bH,06aH,0cbH,0beH,039H,04aH,04cH,058H,0cfH
         DB 0d0H,0efH,0aaH,0fbH,043H,04dH,033H,085H,045H,0f9H,002H,07fH,050H,03cH,09fH,0a8H
         DB 051H,0a3H,040H,08fH,092H,09dH,038H,0f5H,0bcH,0b6H,0daH,021H,010H,0ffH,0f3H,0d2H
         DB 0cdH,00cH,013H,0ecH,05fH,097H,044H,017H,0c4H,0a7H,07eH,03dH,064H,05dH,019H,073H
         DB 060H,081H,04fH,0dcH,022H,02aH,090H,088H,046H,0eeH,0b8H,014H,0deH,05eH,00bH,0dbH
         DB 0e0H,032H,03aH,00aH,049H,006H,024H,05cH,0c2H,0d3H,0acH,062H,091H,095H,0e4H,079H
         DB 0e7H,0c8H,037H,06dH,08dH,0d5H,04eH,0a9H,06cH,056H,0f4H,0eaH,065H,07aH,0aeH,008H
         DB 0baH,078H,025H,02eH,01cH,0a6H,0b4H,0c6H,0e8H,0ddH,074H,01fH,04bH,0bdH,08bH,08aH
         DB 070H,03eH,0b5H,066H,048H,003H,0f6H,00eH,061H,035H,057H,0b9H,086H,0c1H,01dH,09eH
         DB 0e1H,0f8H,098H,011H,069H,0d9H,08eH,094H,09bH,01eH,087H,0e9H,0ceH,055H,028H,0dfH
         DB 08cH,0a1H,089H,00dH,0bfH,0e6H,042H,068H,041H,099H,02dH,00fH,0b0H,054H,0bbH,016H
         

.code segment 
    ;main function 
    
    CALL enterinput
    roundkey input, key
    mov si,00H
    main: 
    push si    
    subbytes input, sbox
    shiftrows input
    mixcolumns input, output, mix
    keyschedule key, outputkey, rcon, sbox
    roundkey input, key
    pop si
    inc si
    cmp si, 09H
    jnz main 
    subbytes input, sbox
    shiftrows input
    mov si, 09H  
    push si
    keyschedule key, outputkey, rcon, sbox
    pop si
    roundkey input, key 
    overriding output, input
    CALL getoutput
                                     
ret

enterinput proc 
    mov si, 00H
    Linput2:
    mov cx, 02H
    Linput:
    mov ah,01H
    int 21H
    cmp al,57H     
    jge Charactersin
    jmp numbersin
    
    charactersin:
    sub al, 57H
    jmp next
    numbersin:
    sub al, 48D 
    jmp next 
    
    next:
    cmp cx, 2
    jz firstin
    jmp secondin
    
    firstin: 
    shl al, 04H
    mov bl, al
    jmp againin
    
    secondin:
    add al, bl
    mov input[si], al
    jmp againin
     
    againin:
    Loop Linput
    
    put:
    inc si
    cmp si, 16D
    jnz Linput2
    ret
    
ENDP


getoutput proc                                                                 
    mov si, 00H
    Loutput2:
    mov cx, 02H  
    Loutput:
    mov dl, output[si]
    cmp cx, 02H
    jz firstout
    jmp secondout
   
    firstout:
    shr dl, 04H
    jmp compare
    
    secondout:
    and dl, 00FH
    jmp compare
    
    compare:
    cmp dl, 09H
    ja charactersout
    jmp numbersout
    
    charactersout:
    add dl, 57H
    jmp againout
   
    numbersout:
    add dl, 48D
    jmp againout
    
    againout:
    mov ah, 02H
    int 21H
    Loop Loutput
    
    get:
    inc si
    cmp si, 16D
    jnz Loutput2
    ret
ENDP