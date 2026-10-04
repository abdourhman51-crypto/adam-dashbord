# Phase 1 — تحليل اللقطات (بزار الحاجة مغنية · 3 فيديوهات)

**المصدر:** مجلدات Drive `hadja 22` (h22) و `hadja mghnia vd 11` (h11)، **41 ملف** (كامل بالاسم الغالط «Document de إدارة مجتمع آدم» → خدمت بالـ file ID).
- حذف التكرار بـ md5: **3 أزواج متطابقة** → بقاو **38 ملف فريد**:
  - `1JB-2J7nbz…` = `1NHlWBH9NK…` (126 MB)
  - `1aihTl0YzS…` = `1hc0e3znjj…` (37 MB)
  - `1WxgW9b0-C…` = `1mReS1aECO…` (219 MB)
- كل الملفات **2160×3840 عمودي (4K)**، أغلبها 60 fps، مدة 1.1–36 s → الأصول للـ render، و proxies 1080p/30fps في `proxy/` للتحليل.
- frame كل 0.5 s → `sheets/<id>.jpg`؛ قياسات كل 0.5 s (حركة الكاميرا، jitter، الحدة، الإضاءة، الدفء) → `metrics.json`.
- Contact sheets لكل فئة: `contact_KIDS.jpg`, `contact_KNIT.jpg`, `contact_STORE.jpg`.

## ⚠️ BIBERON — ما كاين حتى لقطة
بعد ما شفت الـ 38 ملف كامل: **حتى biberon، لا sensible à la chaleur لا en verre، ولا علبة** في الزوج مجلدات.
باش ما نخترعوش حاجة: **فيديو 01 موقوف** حتى تبعثولي لقطات biberon. لازم تكون العلب مقروءة: ml، العمر، المادة، BPA free، anti-colique، الألوان، وإذا كانت مكتوبة خاصية تبدّل اللون مع السخانة.

## ملاحظة الماركات
حسب طلبكم: **logos الماركات ما نمحوهمش** (Dior على طقومات الأطفال، miu miu على الـ débardeurs، Lacoste على الـ polos). يبقاو كيما هوما، وحتى الأسماء عادي.

## ملخص الفئات
| فئة | عدد | أحسن لقطات |
|---|---|---|
| KIDS | 22 (+ 2 مشتركين مع STORE: #00، #33) | #33، #20، #25، #14، #15، #05 detail |
| KNIT (débardeur maille col polo) | 8 | #10 (Q5)، #24، #07، #13، #35، #09 |
| STORE / abundance | 2 (+ #00، #33) | #33 (Q5)، #00، #19، #32 |
| REJECT | 4 | #01 (قصير)، #12 و #16 (shaky)، #29 (انتقالي) |

- **KNIT للنساء؟** الـ débardeurs معلّقين على cintres dorés كبار، في rang الكبار مع polos نساء وmannequins. المقاس **ما هوش مكتوب** على l'étiquette.
  - OCR تاع l'étiquette (rose): `1027-19`، code-barres `6957792127191`، «WASH EXPLAIN DIRECTIONS»: wash gently / do not bleach / do not tumble dry / low iron / dry clean / line dry.
  - **ما كاين لا matière لا taille** → ما نقولوش «100% coton» ولا مقاسات.
- **الأسعار:** لافتات «100» تبان في #08، #22، #23، #25، #30، #31 → ما نذكروهاش، ونقصّوها بالـ crop.
- **body تاع رضيع** (#14، #15، #22، #25، #30، #31، #37، الجزء الثاني): قريب للـ sous-vêtement → نتجنبوه في المونتاج.
- **ضوء أصفر:** #02، #17، #27 (warm 25–30)، والـ KNIT شوية (#09، #11، #35) → grade محايد بلا ما نبدلو لون السلعة. #17 احتياط فقط.

## جدول الملفات (38)
| # | file ID | مجلد | مدة | فئة | نوع اللقطة | Q | أحسن مقطع (s) | المحتوى | ملاحظات |
|---|---|---|---|---|---|---|---|---|---|
| 00 | `10-pL3d9oAHGexbqSwA3H71622SH1Nae6` | h22 | 7.2 | KIDS/STORE | Wide (tilt) | 4 | 0.5–3.0 | رفّين طقومات أطفال | pan/tilt سلس، abundance |
| 01 | `12g42mPumjvGYkPYhngdj9oJDbOuAjHgf` | h22 | 1.1 | REJECT | Medium | 2 | — | manteau fourrure léopard | 1.1 s فقط — قصير بزاف |
| 02 | `14fVBMaUsR-a9QF_RaV10aubTo4ZU6PHR` | h11 | 19.6 | KIDS | Medium + يد | 3 | 2.5–4.5 | طقم rouge «Dior» strass قدّام logo البزار | ضوء دافي (warm 26) → grade محايد |
| 03 | `1ETkDA42r6pC-w7NL26FSb_82L77s8VHt` | h22 | 3.1 | KIDS | Medium | 3 | 0.0–2.5 | طقم beige دب + قبعة | soft (sharp 725) |
| 04 | `1IgQRY63vDvR2sOn79WfpgW8n-R-ZnTf1` | h11 | 36.0 | KIDS | Medium + يد | 3 | 26.0–28.0 | طقم bordeaux فراشة | 36 s، أغلبو يدين تتحرك |
| 05 | `1JB-2J7nbzkYDclMyYW34aXLRDsLzLsqe` | h22 | 32.6 | KIDS | Medium → Close-up | 4 | 18.5–20.5 / 27–30 detail | طقم beige دب: تطريز + قبعة | أحسن detail للدب |
| 06 | `1L-lze3GCGoTZNqGKsPlp0J1RJp0LYOBx` | h22 | 4.2 | KNIT | Medium | 4 | 2.5–4.2 | débardeur bleu ciel | ثابت |
| 07 | `1MAsLM4nPim1pQ99y-gad64BHB_Vh2-FA` | h22 | 5.7 | KNIT | Medium | 4 | 0.5–2.5 | débardeur rose + logo miu miu | ثابت |
| 08 | `1M_Z2Qc4RjlGZi-Vt13t8SKQla9-LnIzj` | h22 | 4.4 | KIDS | Medium | 3 | 0.0–2.0 | طقم bleu قبعة بوذنين → body | لافتة «100» تبان في التحت → crop |
| 09 | `1Mp8auH0qHr-9xKk1-6uKx4I3T3JaOEgZ` | h22 | 9.4 | KNIT | Wide (pan) | 4 | 0.0–2.0 / 6.5–9.0 | rang débardeurs 4 ألوان + polos | abundance KNIT (30 fps) |
| 10 | `1Phgdq5TtIcJSzKJpcO5EblT4YTsa52ZJ` | h22 | 5.7 | KNIT | Medium | 5 | 0.5–2.5 | débardeur bleu ciel | أثبت لقطة (jitter 0.23) — reveal |
| 11 | `1Q9vfJlEE4Lt___0QgrkkjcW5rkAlCakm` | h22 | 3.8 | KNIT | Medium | 3 | 0.5–2.5 | débardeur noir | حركة خفيفة |
| 12 | `1REPCOb1r_-THcgxj2yxAsqXhwduIfCrl` | h11 | 19.0 | REJECT | Medium + يد | 2 | — | طقم crème fleur | shaky (jitter 2.3) + flou |
| 13 | `1RMF28TVHGNIRpcnVfafGvNLW_8616hHB` | h22 | 4.4 | KNIT | Medium | 4 | 2.0–4.0 | débardeur marron | ثابت |
| 14 | `1Sb4krjfBicfkeXPReQx1XqeQ1vbboYgC` | h22 | 7.8 | KIDS | Medium | 4 | 0.5–2.5 | طقم kaki دب + قبعة → body | ثابت (jitter 0.2)، الجزء ديال body نتجنبوه |
| 15 | `1T97WhiUuxe5gfGwKJBjgfPPRGtFCorp4` | h22 | 10.5 | KIDS | Medium | 4 | 0.2–3.0 | طقم beige دب + قبعة → body | ثابت |
| 16 | `1UO6IaVA6PPEYbfObl2XzIL9Zf4g68Bs_` | h11 | 3.6 | REJECT | Close-up + يد | 1 | — | طقم bordeaux فراشة | shaky (jitter 5.1) |
| 17 | `1UfonV9R6ac0prTG5T7wVI4-0mAlDq4fE` | h11 | 11.4 | KIDS | Medium + يد | 2 | 9.5–11.4 | طقم rouge «Dior» | ضوء أصفر (warm 30) + soft — احتياط فقط |
| 18 | `1V9G3gwrwXiqEud2Ql0lOJTjS4HQjAEE6` | h11 | 8.4 | KIDS | Medium + يد | 3 | 6.0–8.0 | طقم noir «LOVE» قطة | مقبول |
| 19 | `1VdbiYS2l9od0Co4eBCuLaYVe60xCsi81` | h22 | 7.2 | STORE | Wide (pan) | 3 | 4.0–7.0 | pan رفوف أطفال | pan سريع شوية |
| 20 | `1WxgW9b0-CQEPM39sbhfdh-uAyi8DcceN` | h22 | 18.8 | KIDS | Medium | 4 | 7.0–9.5 | طقم beige دب + قبعة + سروال مطبوع | ثابت، بنور مليح — reveal 1 |
| 21 | `1Y0AZeayDvukzEO5UPDC0ooCGoVq9ie-8` | h11 | 8.8 | KIDS | Close-up + يد | 3 | 3.5–5.5 | LOVE strass detail | حاد بصح يتحرك (jitter 2.0) |
| 22 | `1Yxco1Z_t7ppx4VLv1uyR9t_tD30ct6iN` | h22 | 9.8 | KIDS | Medium | 2 | 7.0–9.0 | طقم bleu → body | البداية shaky + «100» |
| 23 | `1_DQXXGIrXdyR7LcfLiXXTNHErA6Yt-I3` | h22 | 6.9 | KIDS | Medium | 3 | 1.5–3.5 | طقم bleu قبعة بوذنين | «100» يبان |
| 24 | `1aihTl0YzSMepDebACKzasXFTvHhp_Wgm` | h22 | 5.3 | KNIT | Medium | 4 | 2.0–4.0 | débardeur noir | أحدّ لقطة KNIT |
| 25 | `1dTLoiX0c4tgHxn0oCYraKgoy3QPYPWQ_` | h22 | 8.6 | KIDS | Medium | 4 | 1.5–3.5 | طقم bleu ciel قبعة بوذنين | ثابت؛ «100» في الزاوية → crop |
| 26 | `1dWEQLzDuLOiAgBIaYfaiSVWcv-r7nT--` | h11 | 11.5 | KIDS | Medium + يد | 2 | 3.0–5.0 | طقم mauve فراشة | flou (sharp 534) — احتياط |
| 27 | `1hf8K4wzAhgw_MZKPfHayh6MKL16jIt7s` | h11 | 13.3 | KIDS | Medium + يد | 3 | 2.5–4.5 | سروال rouge pattes d'éléphant strass | ضوء دافي (warm 25) |
| 28 | `1ndTOTxqJv2coCWbwy5cFlRZR5cX-o2AQ` | h22 | 5.7 | KIDS | Medium + يد | 2 | 4.0–5.7 | طقم rose «Dior» | flou (sharp 567) |
| 29 | `1nyqaCzVhiyNfsOAl_AaK0I1TAmgcjuGV` | h11 | 4.1 | REJECT | — | 1 | — | انتقالي (0–2.5 s يدين/حيط) ثم LOVE | انتقالي بلا قيمة + flou |
| 30 | `1p2UyTw1hTqFISMsGDxyF2DCeFl51q94N` | h22 | 16.4 | KIDS | Medium | 4 | 0.5–2.5 | طقم bleu قبعة بوذنين → body | «100» يبان |
| 31 | `1q0fh86uFfe-Hp4llMSmi2m6-sjWLN0z_` | h22 | 11.1 | KIDS | Medium → Detail | 3 | 7.0–9.0 / 10.4–11.1 | body + أزرار | body رضيع: نتجنبوه (قريب للـ sous-vêtement) |
| 32 | `1ryjrClXrOuwLWon7XO_Uc4W40UZb1qm-` | h22 | 13.2 | STORE | Wide (pan) | 2 | 9.0–11.0 | pan رفوف | pan سريع (motion 20) |
| 33 | `1t60KTDdmN8ap7PM509WbByfd2mBD1Ozo` | h22 | 7.8 | STORE/KIDS | Wide (pan) | 5 | 5.5–7.8 | رفوف عامرين طقومات أطفال | أحدّ لقطة في الكل — HOOK abundance |
| 34 | `1udD6wwtVLplwYIcbd-TvEFeJ7FZhcBnn` | h11 | 28.3 | KIDS | Medium + يد | 3 | 12.0–14.0 | طقم mauve فراشة | soft شوية |
| 35 | `1usbmwltp9sAjuPhMPn0cZUzi-znI0OmY` | h22 | 6.5 | KNIT | Medium → Wide | 4 | 0.0–2.0 / 5.0–6.5 | débardeur rose ثم marron/rose/noir | HOOK KNIT |
| 36 | `1yarzLacMbgpUoP4QC2HCM-OPy2tPoY47` | h22 | 4.5 | KIDS | Medium | 3 | 2.5–4.5 | طقم beige دب | حركة خفيفة |
| 37 | `1zkXdBBCS50Df5bs1Kj5Caafifw76ZQDm` | h22 | 10.8 | KIDS | Medium | 3 | 0.3–2.5 | طقم beige دب + قبعة → body | آخر frame flou |

> Q = جودة 1–5 (حدة + ثبات + إضاءة). «يد» = يد تشد الـ cintre (بلا وجوه زبائن، حتى وجه ما يبان).

## أحسن اللقطات حسب الفئة

### KIDS (contact_KIDS.jpg)
| # | file | t (s) | نوع | دور | الوصف |
|---|---|---|---|---|---|
| 1 | #33 `1t60KTDdmN8ap7PM509WbByfd2mBD1Ozo` | 5.5–7.8 | Wide | HOOK/abundance | رفوف مليانة طقومات أطفال، pan سلس، أحد clip |
| 2 | #00 `10-pL3d9oAHGexbqSwA3H71622SH1Nae6` | 0.5–3.0 | Wide | abundance | رفّين طقومات، tilt سلس |
| 3 | #20 `1WxgW9b0-CQEPM39sbhfdh-uAyi8DcceN` | 7.0–9.5 | Medium | piece 1 reveal | طقم beige: قبعة + sweat دب + سروال مطبوع |
| 4 | #05 `1JB-2J7nbzkYDclMyYW34aXLRDsLzLsqe` | 27.0–30.0 | Close-up | piece 1 detail | تطريز الدب + القبعة |
| 5 | #37 `1zkXdBBCS50Df5bs1Kj5Caafifw76ZQDm` | 0.3–2.5 | Medium | piece 1 alt | نفس الطقم beige |
| 6 | #25 `1dTLoiX0c4tgHxn0oCYraKgoy3QPYPWQ_` | 1.5–3.5 | Medium | piece 2 reveal | طقم bleu: قبعة بوذنين دب + sweat + سروال |
| 7 | #14 `1Sb4krjfBicfkeXPReQx1XqeQ1vbboYgC` | 0.5–2.5 | Medium | piece (alt) | طقم vert/kaki دب + قبعة |
| 8 | #31 `1q0fh86uFfe-Hp4llMSmi2m6-sjWLN0z_` | 10.4–11.1 | Detail | detail | أزرار + خامة body (لاحظ: body = تحت-لباس رضيع؟) |
| 9 | #02 `14fVBMaUsR-a9QF_RaV10aubTo4ZU6PHR` | 2.5–4.5 | Medium hand | piece 3 reveal | طقم rouge «Dior» قدّام logo البزار |
| 10 | #18 `1V9G3gwrwXiqEud2Ql0lOJTjS4HQjAEE6` | 6.0–8.0 | Medium hand | piece 4 reveal | طقم noir «LOVE» قطة |
| 11 | #21 `1Y0AZeayDvukzEO5UPDC0ooCGoVq9ie-8` | 3.5–5.5 | Close-up | piece 4 detail | LOVE بالـ strass |
| 12 | #34 `1udD6wwtVLplwYIcbd-TvEFeJ7FZhcBnn` | 12.0–14.0 | Medium hand | piece 5 reveal | طقم mauve فراشة |
| 13 | #04 `1IgQRY63vDvR2sOn79WfpgW8n-R-ZnTf1` | 26.0–28.0 | Medium hand | piece 5 alt | طقم bordeaux فراشة |
| 14 | #27 `1hf8K4wzAhgw_MZKPfHayh6MKL16jIt7s` | 2.5–4.5 | Medium hand | extra | سروال rouge pattes d'éléphant بالـ strass |

### KNIT (contact_KNIT.jpg)
| # | file | t (s) | نوع | دور | الوصف |
|---|---|---|---|---|---|
| 1 | #35 `1usbmwltp9sAjuPhMPn0cZUzi-znI0OmY` | 0.0–2.0 | Medium | HOOK | débardeur rose على cintre doré |
| 2 | #10 `1Phgdq5TtIcJSzKJpcO5EblT4YTsa52ZJ` | 0.5–2.5 | Medium | reveal | bleu ciel — أثبت لقطة (jitter 0.23) |
| 3 | #07 `1MAsLM4nPim1pQ99y-gad64BHB_Vh2-FA` | 0.5–2.5 | Medium | reveal | rose + col polo + logo miu miu |
| 4 | #13 `1RMF28TVHGNIRpcnVfafGvNLW_8616hHB` | 2.0–4.0 | Medium | color | marron |
| 5 | #24 `1aihTl0YzSMepDebACKzasXFTvHhp_Wgm` | 2.0–4.0 | Medium | color | noir — أحدّ لقطة |
| 6 | #06 `1L-lze3GCGoTZNqGKsPlp0J1RJp0LYOBx` | 2.5–4.2 | Medium | color alt | bleu |
| 7 | #11 `1Q9vfJlEE4Lt___0QgrkkjcW5rkAlCakm` | 0.5–2.5 | Medium | color alt | noir |
| 8 | #09 `1Mp8auH0qHr-9xKk1-6uKx4I3T3JaOEgZ` | 0.0–2.0 | Wide | abundance | rang كامل: noir/bleu/rose/marron + polos |
| 9 | #09 `1Mp8auH0qHr-9xKk1-6uKx4I3T3JaOEgZ` | 6.5–9.0 | Wide | abundance | نهاية الـ pan: 4 ألوان |
| 10 | #35 `1usbmwltp9sAjuPhMPn0cZUzi-znI0OmY` | 5.0–6.5 | Wide | colors reveal | marron / rose / noir جنب بعض |
| 11 | #10 `1Phgdq5TtIcJSzKJpcO5EblT4YTsa52ZJ` | 3.5–5.5 | Detail (crop 4K) | detail | maille + col + étiquette (crop 2x من 4K بلا خسارة) |

### STORE (contact_STORE.jpg)
| # | file | t (s) | نوع | دور | الوصف |
|---|---|---|---|---|---|
| 1 | #33 `1t60KTDdmN8ap7PM509WbByfd2mBD1Ozo` | 0.0–3.0 | Wide | abundance | رفوف أطفال من فوق لتحت |
| 2 | #00 `10-pL3d9oAHGexbqSwA3H71622SH1Nae6` | 4.0–7.0 | Wide | abundance | رفوف + الدروج |
| 3 | #19 `1VdbiYS2l9od0Co4eBCuLaYVe60xCsi81` | 4.0–7.0 | Wide | abundance | pan طقومات |
| 4 | #32 `1ryjrClXrOuwLWon7XO_Uc4W40UZb1qm-` | 9.0–11.0 | Wide | abundance | pan سريع — q2 |

### Hook shots
- **KIDS:** #33 `1t60KTDdmN…` 5.5–7.8 s → أحدّ لقطة wide، رفوف عامرين ألوان. من بعد reveal قطعة 1 (#20).
- **KNIT:** #35 `1usbmwltp9…` 0.0–2.0 s → débardeur rose وحدو (يخدم مع «وانتي؟»). الـ reveal تاع الألوان في #35 5.0–6.5 و #09 6.5–9.0.
- **Detail:** ما كاينش close-up حقيقي للـ maille → crop 2× من الأصل 4K (#10 3.5–5.5) بلا ما تنقص الجودة في 1080.
