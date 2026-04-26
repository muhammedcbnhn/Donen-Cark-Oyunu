org 100h
jmp start

baslik          db '==== DONEN CARK OYUNU ====',0
baslamak_msg    db 'Carki dondurmek icin SPACE tusuna basin...',0
yon_msg         db 'YON SECIN: 1) Saat yonu  2) Ters yon   (ESC=CIKIS)',0
hiz_msg         db 'HIZ SECIN (1-5): ',0
donuyor_msg     db 'CARK DONUYOR... Durdurmak icin SPACE tusuna basin',0
sonucmsg        db 'SONUC: ',0
iflasmsg        db 'IFLAS! (Puan Sifirlandi)            ',0
iflasyazisi     db 'IFLAS',0
puanmsg         db ' Puan Kazandiniz!                   ',0
toplammsg       db 'TOPLAM PUANINIZ: ',0
devam_msg       db 'Devam etmek icin SPACE, cikmak icin ESC...',0

; VRAM Hilesi icin dilimlerin tam 5 karakterlik formatlanmis halleri
dilim_str     db ' 100 ', ' 250 ', 'IFLAS', ' 500 ', ' 750 ', '1000 '
              db ' 300 ', ' 800 ', 'IFLAS', ' 50  ', '1500 ', ' 80  '

renkler       db 0Ah, 0Bh, 0Ch, 0Eh, 0Dh, 09h, 0Ah, 0Bh, 0Ch, 0Eh, 0Dh, 09h
dilimler      dw 100, 250, 0, 500, 750, 1000, 300, 800, 0, 50, 1500, 80

toplam        dw 0
mevcut        db 0
guncel_renk   db 07h

hiz_cs        db 10     
last_time     db 0      
wait_cnt      db 0      
spin_pos      db 0      
spin_offset   db 0       ; Carkin ne kadar dondugunu tutar
spin_tab      db '|', '/', '-', '\'

yon           db 0
hiz_tab_cs    db 20, 10, 5, 2, 0   ; 1: Yavas, 5: Fisek (Bekleme Yok)

cark_x        db 38, 45, 50, 52, 50, 45, 38, 31, 26, 24, 26, 31
cark_y        db  8,  9, 11, 14, 17, 19, 20, 19, 17, 14, 11,  9

cerc_tablo:
    db  4, 40, 40
    db  5, 35, 45
    db  6, 30, 50
    db  7, 27, 53
    db  8, 24, 56
    db  9, 23, 57
    db 10, 22, 58
    db 11, 21, 59
    db 12, 21, 59
    db 13, 21, 59
    db 14, 21, 59
    db 15, 21, 59
    db 16, 21, 59
    db 17, 22, 58
    db 18, 23, 57
    db 19, 24, 56
    db 20, 27, 53
    db 21, 30, 50
    db 22, 35, 45
    db 23, 40, 40
cerc_tablo_son:

start:
    mov ax, cs
    mov ds, ax

ana:
    call temizle
    call arayuz_ciz
    call skor_yaz

    call satir24_temizle
    mov dh, 24
    mov dl, 2
    call gotoxy
    mov si, offset baslamak_msg
    mov bl, 0Fh
    call yaz_renkli

    call space_veya_esc_bekle
    call yon_hiz_sec

    call satir24_temizle
    mov dh, 24
    mov dl, 2
    call gotoxy
    mov si, offset donuyor_msg
    mov bl, 0Eh
    call yaz_renkli

    call cark_dondur

    call satir24_temizle
    mov dh, 24
    mov dl, 2
    call gotoxy
    call sonucu_yaz

    call skor_yaz

    call satir25_temizle
    mov dh, 25
    mov dl, 2
    call gotoxy
    mov si, offset devam_msg
    mov bl, 07h
    call yaz_renkli

    call space_veya_esc_bekle
    jmp ana

; ================================================================
; ARKADASININ VRAM HILESÝ: YAZILARI FIZIKSEL OLARAK KAYDIRIR
; ================================================================
carki_ciz:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, 0B800h
    mov es, ax

    mov cx, 12          
    xor bx, bx          ; Ekrandaki slot sirasi (0-11)

ciz_dongu:
    ; 1) VRAM Adresini Hesapla
    xor ah, ah
    mov al, [cark_y + bx]
    push cx
    mov cl, 80
    mul cl
    pop cx
    xor dh, dh
    mov dl, [cark_x + bx]
    add ax, dx
    shl ax, 1
    mov di, ax          ; DI = Bu dilimin VRAM adresi

    ; 2) Kaydirilmis Veri Indeksini Bul
    mov al, bl
    add al, spin_offset
    cmp al, 12
    jb index_ok
    sub al, 12
index_ok:
    push bx
    xor ah, ah
    mov bx, ax          ; BX = Gercek data indeksi

    ; 3) Rengi Al
    mov ah, [renkler + bx]

    ; 4) Yazinin Baslangic Adresini Bul
    mov si, bx
    shl si, 1           ; x2
    shl si, 1           ; x4
    add si, bx          ; x5 (Cunku her yazi 5 karakter)
    add si, offset dilim_str

    ; 5) 5 Karakteri Isik Hizinda Ekrana Kopyala
    push cx
    mov cx, 5
kopyala_dongu:
    lodsb               
    stosw               
    loop kopyala_dongu
    pop cx

    pop bx              
    inc bx
    loop ciz_dongu

    ; Ortadaki Cubuk Animasyonu
    inc spin_pos
    and spin_pos, 03h
    push bx
    xor bx, bx
    mov bl, spin_pos
    mov al, [spin_tab + bx]
    pop bx
    mov ah, 0Eh
    mov di, 2316        ; Ortadaki VRAM adresi
    mov es:[di], ax

    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ================================================================
; KAZANAN (TEPE) DILIMI MUKEMMEL SEKILDE PARLATIR
; ================================================================
parlat_top_slot:
    push ax
    push cx
    push di
    push es
    mov ax, 0B800h
    mov es, ax
    mov di, 1356        ; Tepedeki slotun (X=38, Y=8) VRAM adresi
    mov cx, 5
parlat_loop:
    mov al, es:[di+1]
    or al, 08h          ; Yaziyi parlak yap
    and al, 0Fh         ; Arka plani sifirla
    add al, 10h         ; Lacivert arka plan ekle (Gorsel Solen)
    mov es:[di+1], al
    add di, 2
    loop parlat_loop
    pop es
    pop di
    pop cx
    pop ax
    ret

satir24_temizle:
    push ax
    push bx
    push cx
    push dx
    mov dh, 24
    mov dl, 0
    call gotoxy
    mov ah, 09h
    mov al, ' '
    mov bl, 07h
    mov bh, 0
    mov cx, 79
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret

satir25_temizle:
    push ax
    push bx
    push cx
    push dx
    mov dh, 25
    mov dl, 0
    call gotoxy
    mov ah, 09h
    mov al, ' '
    mov bl, 07h
    mov bh, 0
    mov cx, 79
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret

yaz_renkli:
    lodsb
    or al, al
    jz yaz_renkli_bit
    mov ah, 09h
    mov bh, 0
    push cx
    mov cx, 1
    int 10h
    pop cx
    call imlec_ilerlet
    jmp yaz_renkli
yaz_renkli_bit:
    ret

sayi_yaz_renkli:
    push ax
    push bx
    push cx
    push dx
    mov guncel_renk, bl
    mov bx, 10
    xor cx, cx
bol_renkli:
    xor dx, dx
    div bx
    add dl, '0'
    push dx
    inc cx
    or ax, ax
    jnz bol_renkli
yazdir_loop_renkli:
    pop ax
    mov ah, 09h
    mov bl, guncel_renk
    mov bh, 0
    push cx
    mov cx, 1
    int 10h
    pop cx
    call imlec_ilerlet
    loop yazdir_loop_renkli
    pop dx
    pop cx
    pop bx
    pop ax
    ret

imlec_ilerlet:
    push ax
    push bx
    push cx
    push dx
    mov ah, 03h
    mov bh, 0
    int 10h
    inc dl
    mov ah, 02h
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret

yildiz_yaz:
    push ax
    push bx
    push cx
    call gotoxy
    mov ah, 09h
    mov al, '*'
    mov bl, 02h
    mov bh, 0
    mov cx, 1
    int 10h
    pop cx
    pop bx
    pop ax
    ret

cerceve_ciz:
    push ax
    push bx
    push cx
    push dx
    push si

    mov si, offset cerc_tablo
    mov cx, (cerc_tablo_son - cerc_tablo) / 3

cerc_dis_dongu:
    mov dh, [si]
    mov al, [si+1]
    mov bl, [si+2]
    add si, 3
    mov dl, al

    cmp dh, 4
    je cerc_dis_yatay
    cmp dh, 23
    je cerc_dis_yatay

    call yildiz_yaz
    mov dl, bl
    call yildiz_yaz
    jmp cerc_dis_sonraki

cerc_dis_yatay:
    call yildiz_yaz
    inc dl
    cmp dl, bl
    jle cerc_dis_yatay

cerc_dis_sonraki:
    loop cerc_dis_dongu

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

arayuz_ciz:
    call cerceve_ciz

    mov dh, 1
    mov dl, 27
    call gotoxy
    mov si, offset baslik
    mov bl, 0Bh
    call yaz_renkli

    ; Kazanan dilimi isaret eden OK isareti
    mov dh, 6
    mov dl, 40
    call gotoxy
    mov ah, 09h
    mov al, 'V'
    mov bl, 0Eh
    mov bh, 0
    mov cx, 1
    int 10h

    ; Carki ekrana bas
    call carki_ciz
    ret

skor_yaz:
    mov dh, 2
    mov dl, 2
    call gotoxy
    mov si, offset toplammsg
    mov bl, 0Fh
    call yaz_renkli
    mov ax, toplam
    mov bl, 0Eh
    call sayi_yaz_renkli
    mov al, ' '
    mov ah, 0Eh
    int 10h
    int 10h
    ret

sonucu_yaz:
    mov si, offset sonucmsg
    mov bl, 0Fh
    call yaz_renkli
    xor bx, bx
    mov bl, mevcut
    shl bx, 1
    mov ax, [dilimler + bx]
    cmp ax, 0
    je iflas
    add toplam, ax
    mov bl, 0Ah
    call sayi_yaz_renkli
    mov si, offset puanmsg
    mov bl, 0Fh
    call yaz_renkli
    ret

iflas:
    xor ax, ax
    mov toplam, ax
    mov si, offset iflasmsg
    mov bl, 0Ch
    call yaz_renkli
    ret

hizli_space_kontrol:
    mov ah, 01h
    int 16h          
    jz sp_no          
    
    mov ah, 00h
    int 16h          
    cmp al, ' '       
    je sp_yes
    cmp ah, 39h       
    je sp_yes
    cmp al, 27
    je sp_esc
    
sp_no:
    xor al, al
    ret
sp_yes:
    mov al, 1
    ret
sp_esc:
    mov al, 2
    ret

programi_kapat_jmp:
    jmp programi_kapat

; ==================== YENI DONDURME MOTORU ====================
cark_dondur:
    call klavye_temizle
    
    mov ah, 2Ch
    int 21h
    mov last_time, dl
    mov wait_cnt, 0

don_loop:
    call hizli_space_kontrol
    cmp al, 1
    je cark_durdu_islem
    cmp al, 2
    je programi_kapat_jmp

    ; Eger hiz 0 ise hic bekleme, direkt animasyona gec!
    mov al, hiz_cs
    cmp al, 0
    je animasyon_adimi

    mov ah, 2Ch
    int 21h
    cmp dl, last_time
    je don_loop          

    mov last_time, dl
    inc wait_cnt
    mov al, wait_cnt
    cmp al, hiz_cs       
    jb don_loop

    mov wait_cnt, 0

animasyon_adimi:
    mov al, yon
    or al, al
    jz don_saat

don_ters:
    inc spin_offset
    cmp spin_offset, 12
    jne don_devam
    mov spin_offset, 0
    jmp don_devam

don_saat:
    mov al, spin_offset
    or al, al
    jnz don_azalt
    mov spin_offset, 11
    jmp don_devam
don_azalt:
    dec spin_offset

don_devam:
    ; Tum yazilari kaydirilmis sekilde hizlica ekrana bas!
    call carki_ciz         
    jmp don_loop

cark_durdu_islem:
    mov al, spin_offset
    mov mevcut, al          ; En tepedeki dilim skoru belirler
    call parlat_top_slot    ; Tepedeki kazanan dilimi lacivert yap
    ret

klavye_temizle:
    push ax
klavye_temizle_loop:
    mov ah, 01h
    int 16h
    jz klavye_temizle_bitti
    mov ah, 00h
    int 16h
    jmp klavye_temizle_loop
klavye_temizle_bitti:
    pop ax
    ret

yon_hiz_sec:
    push ax
    push bx

    call klavye_temizle
    call satir24_temizle
    call satir25_temizle

    mov dh, 24
    mov dl, 2
    call gotoxy
    mov si, offset yon_msg
    mov bl, 0Fh
    call yaz_renkli

yon_bekle:
    mov ah, 0
    int 16h
    cmp al, 27
    je programi_kapat
    cmp al, '1'
    je yon_saat
    cmp al, '2'
    je yon_ters
    jmp yon_bekle

yon_saat:
    mov yon, 0
    jmp hiz_sec
yon_ters:
    mov yon, 1

hiz_sec:
    call satir25_temizle
    mov dh, 25
    mov dl, 2
    call gotoxy
    mov si, offset hiz_msg
    mov bl, 0Fh
    call yaz_renkli

hiz_bekle:
    mov ah, 0
    int 16h
    cmp al, 27
    je programi_kapat
    cmp al, '1'
    jb hiz_bekle
    cmp al, '5'
    ja hiz_bekle

    sub al, '1'
    xor ah, ah
    mov bx, ax
    mov al, [hiz_tab_cs + bx]
    mov hiz_cs, al

    pop bx
    pop ax
    ret

space_veya_esc_bekle:
    mov ah, 0
    int 16h
    cmp al, 27
    je programi_kapat
    cmp al, 32
    jne space_veya_esc_bekle
    ret

programi_kapat:
    call temizle
    mov ax, 4C00h
    int 21h

temizle:
    mov ax, 0003h
    int 10h
    ret

gotoxy:
    push ax
    push bx
    mov ah, 2
    mov bh, 0
    int 10h
    pop bx
    pop ax
    ret

end start