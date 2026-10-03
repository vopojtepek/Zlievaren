# Rozhranie podľa webovej verzie — 3. 10. 2026

## Zákazky — aktualizácia 3. 10. 2026

Panel `WebContracts.gd` zobrazuje pravidlá, aktívnu kapacitu, všetkých päť
stavov zákaziek a úplné vzťahy s firmami podľa lokálneho `dist/game.js`.
Karty sa aktualizujú podľa ID bez nahrádzania tlačidiel počas odpočtu;
uzavreté položky odstráni až denná obnova simulácie. Mriežka má 3/2/1
stĺpce pri šírkach nad 850/do 850/do 620 px. Príkazy a uloženie sa nemenia.
Záporné polovice bonusov sa zaokrúhľujú rovnako ako JavaScript Math.round.

Overenie: 13 testovacích sád vrátane TestContractsUI; samostatné vizuálne
overenie `tests/capture_contracts.gd` pri 1440, 800 a 600 px kontroluje
šírku, počet stĺpcov a zachovanie fokusu aj posúvania. Celá scéna sa
overuje cez `tests/capture_layout.gd`. Výstupy sú v `artifacts/`.

Referenciou sú lokálne súbory `Zlievaren-main/dist/index.html`, `style.css`,
`game.js` a `renderer.js`. Úpravy sú v natívnom Godot projekte.

## Rozloženie

`src/ui/WebLayout.gd` skladá existujúce scény po ich inicializácii do posúvateľnej
stránky: hlavička, nadpis a navigácia hál, hala a bočný inšpektor, smeny,
majster, mzdy, míľnik a záložky správy podniku. Zachováva odkazy na existujúce
ovládacie prvky a herné príkazy. Maximálna šírka obsahu je 1556 px (webová
stránka 1640 px mínus okraje), bočný panel 290/320/345 px a hala 1100:690.
Pri šírke pod 850 px sú hlavné stĺpce pod sebou.

Burza používa tabuľku cien a samostatný formulár nákupu, predaja a cenových
pokynov. Sklady, rozvoj a karty zákaziek sú prístupné pod halou.
Hlavička obsahuje pomoc a históriu prevzaté z webového zdroja.
Klávesy 1–6 vyberajú stroj, P prepína pauzu, medzerník spúšťa akciu stroja.

## Animácie a vykresľovanie

- Naklápanie panvy, kývanie počas prepravy, panvár a prúdy taveniny.
- Žeravý otvor pece, dym a pohyb vsádzky.
- Jemné gradientové svetlá namiesto pevných kruhov, gradientové pozadia hál.
- Chladiace trysky, kvapky, vnútorná aj vonkajšia para a doznievanie pary.
- 720 časovaných iskier s balistickými stopami a väčšie úlomky nepodarku.
- Pieskovač používa 86 kvapiek, rozstreky a odtok vody podľa fázy cyklu.
- Príchod a odchod panvárov pri výmene smeny.
- Animovaný náhľad vybraného stroja, orezaný do jeho vlastného panelu.

Existujúce pohyby CNC, skladníka, obsluhy, výrobkov a majstrov zostávajú
napojené na simuláciu. Vykresľovanie je natívne; nejde o vloženie webu do Godotu.

## Overenie

Simulačné a UI testy: `godot --headless --path . --script tests/RunTests.gd`.
Výsledok: 12 sád úspešných, 0 neúspešných.

Vizuálne kontroly vyžadujú grafický renderer:
`godot --path . --script tests/capture_layout.gd`.
Kontrolujú pomer strán, šírku bočného panelu, navigáciu, pauzu a šírky
800, 1024, 1280, 1440 a 1920 px. Ukladajú snímky hál, záložiek a vybraných
výrobných stavov do `artifacts/`. Používajú stav v pamäti a neukladajú hru.
Výsledok: 0 zlyhaní; snímky manuálne skontrolované.

Pri vizuálnom teste bola opravená aj chyba pôvodného Godot panelu zákaziek:
ponuka musí odpočítavať `offerDeadline`, nie prázdny `deadline`.

Náhľady overujú rozloženie a jednotlivé fázy; netvrdia pixelovú identitu
vykresľovania Canvas a Godot. Testovacie prostredie hlásilo nedostupnú cache
shaderov a systémové certifikáty, bez chýb GDScriptu vo finálnej vizuálnej kontrole.
