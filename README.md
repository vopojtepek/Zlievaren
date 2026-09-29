# Žeravá zlievareň — projekt na pokračovanie

Balík pripravený 29. 9. 2026 z verzie 21. Komunikuj s Pavlom po slovensky.

Existujúca hra: https://zlievaren-pavol-190926.pavol-bubala451602.chatgpt.site/
Sites project_id: appgprj_6aaf007356a88191b0a175ea1438d78e
Zdrojový commit: 4874d193eceb197b2966c1b85e5f17bf24928b58

Pokračuj v existujúcom webe, nevytváraj druhý Sites projekt. Zachovaj verejnú adresu a kompatibilitu uložených hier. Balík neobsahuje prihlasovacie údaje ani osobnú rozohranú pozíciu. Tá je uložená v localStorage prehliadača a medzi počítačmi sa týmto balíkom neprenesie.

## Spustenie a vývoj

Samostatnú hru otvor cez Zerava-zlievaren.html. Na vývoj s Node.js spusti `node serve.cjs` a otvor http://127.0.0.1:4319/.
Upravuj dist/engine.js (simulácia), dist/game.js (ovládanie), dist/renderer.js (Canvas grafika), dist/index.html a dist/style.css. Testy spúšťaj jednotlivo cez `node tests/personnel.cjs` a rovnako ostatné testy; fixtures.cjs je pomocný súbor.
Pri každej viditeľnej zmene doplň datovaný záznam do Noviniek v dist/index.html. Súbor SOURCE_CODE.txt obsahuje čitateľný export zdrojov aj testov na priloženie do ChatGPT projektu. Nákresy hál sú v references/.

## Súčasné pravidlá

- Päť miestností: Zlievareň, Sklad, Pieskovač, CNC, Kancelária. Deň trvá 180 sekúnd, mzdy sa vyplácajú týždenne.
- Začiatok: 1000 mincí, 60 kg železa, 20 kg zinku, ostatné materiály 0; zamestnaní iba majstri Mišo a Miro. Ostatné profesie sa najímajú osobitne na smeny.
- Každá odstredivka potrebuje vlastnú obsluhu; pieskovač tiež. Kancelária spravuje nábor, absencie, zastupovanie s príplatkom a odstupné.
- Riziko nepodarku rúry je 30/20/10 % podľa úrovne odstredivky plus riziko jej obsluhy. Skladníci, pieskovači a majstri už nemajú štatistiku rizika nepodarku; náhrada zatiaľ nie je navrhnutá. Ich novú mzdu určuje spoľahlivosť, existujúce mzdy sa zachovávajú.
- Všetky štyri výrobky treba pred predajom alebo dodaním zákazky očistiť v pieskovači. Výrobky nemožno kupovať.
- Sklady železa a zinku sú odomknuté, ostatné sa kupujú. CNC 1–6 stoja 500, 750, 1000, 1250, 1500, 1750; AMADA ostáva zamknutá. CNC výroba zatiaľ nie je zapojená.
- Zákazky majú termíny prijatia a dodania a budujú vzťahy s firmami. Históriu zmien obsahuje okno Novinky. Schéma uloženia je 14.

## Pokyny pre ChatGPT projekt

Názov projektu: Žeravá zlievareň. Prilož README.md a SOURCE_CODE.txt; ZIP slúži na rozbalenie na počítači. Pokračuj v týchto zdrojoch, rešpektuj existujúce pravidlá a grafické referencie, zmeny over testami a pri publikovaní použi existujúci Sites identifikátor.
