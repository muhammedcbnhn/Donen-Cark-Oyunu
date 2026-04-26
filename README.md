# 🎡 Dönen Çark Oyunu (Wheel of Fortune - x86 Assembly)

Bu proje, 16-bit x86 Assembly (DOS Mimarisi) ile geliştirilmiş, kullanıcı etkileşimli ve animasyonlu bir "Dönen Çark" (Çarkıfelek) şans oyunudur. 

Projenin en büyük özelliği, standart ve yavaş BIOS video kesmeleri (`int 10h`) yerine, eski oyun programcılarının kullandığı **Doğrudan VRAM (Video RAM) Erişimi** tekniğini kullanarak işlemci sınırlarını zorlayan bir performans ve hız sunmasıdır.



## 🚀 Öne Çıkan Özellikler

* **Doğrudan VRAM Yazma (`0B800h`):** Ekrana karakter basmak için BIOS'u beklemek yerine doğrudan ekran kartı hafızasına ışık hızında veri yazılır. Bu sayede takılma veya yırtılma (tearing) olmadan pürüzsüz bir animasyon sağlanır.
* **Bellek Kaydırma (Memory Shifting) Animasyonu:** Çark dönerken sadece sayılar değişmez; 12 dilimlik dizi fiziksel olarak kaydırılarak gerçekçi bir dönüş hissi yaratılır.
* **Hassas Zamanlayıcı (Centisecond Timer):** Donanımı uyutan gecikme döngüleri yerine, sistem saatinin saniyenin yüzde biri (`int 21h, 2Ch`) değerleri okunarak kusursuz bir senkronizasyon elde edilir.
* **"Fişek" Hız Modu:** 5 farklı hız ayarı bulunur. 5. Seviye seçildiğinde bekleme süresi `0`'a inerek işlemcinin tam gücüyle, gözün takip edemeyeceği bir hızda dönüş gerçekleşir.
* **Renkli Vurgular ve Skor Takibi:** Çark durduğunda kazanan dilim VRAM üzerinden anında lacivert arka planla parlatılır ve toplam puan anlık olarak güncellenir. "IFLAS" durumunda puan sıfırlanır.

## 🎮 Nasıl Oynanır?

1. Oyunu başlattığınızda arayüz ve çark sizi karşılar.
2. Çarkın dönüş yönünü seçin:
   * `1` - Saat Yönü
   * `2` - Ters Yön
3. Çarkın dönüş hızını seçin (`1` en yavaş, `5` anında/gecikmesiz dönüş).
4. Çark dönmeye başladığında durdurmak için **SPACE (Boşluk)** tuşuna basın.
5. Ok işaretinin (`V`) altına gelen sayı kasanıza eklenir. Eğer `IFLAS` gelirse tüm puanınız silinir.
6. Oyundan çıkmak için herhangi bir menüde **ESC** tuşuna basabilirsiniz.

## 🛠️ Kurulum ve Çalıştırma

Bu proje 16-bit DOS ortamı için yazıldığından doğrudan modern 64-bit Windows işletim sistemlerinde çalışmaz. Çalıştırmak için aşağıdaki emülatörlerden birini kullanabilirsiniz:

### Seçenek 1: Emu8086 ile (Tavsiye Edilen)
1. Kodu Emu8086 programına yapıştırın.
2. `Compile` veya `Emulate` butonuna tıklayın.
3. Açılan sanal ekranda oyunu oynayabilirsiniz.

### Seçenek 2: DOSBox ve TASM/MASM ile
1. `cark.asm` dosyasını oluşturup kodu içine kaydedin.
2. DOSBox'ı başlatın ve dosyanın bulunduğu dizini mount edin.
3. Assembler ile derleyin:
   ```cmd
   tasm cark.asm
   tlink /t cark.obj
   cark.com
