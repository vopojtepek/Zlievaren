# Tutoriál výroby

Tutoriál sa automaticky spúšťa pri novej hre v Godote. Nábor, nákupy, spotreba materiálu, nepodarky, čistenie a predaj sú skutočné herné akcie. Dá sa kedykoľvek preskočiť bez zahodenia rozpracovanej výroby.

`TutorialController.gd` riadi kroky, zvýraznenie, vstupy a samostatné zastavenie času cez `SimulationClock.tutorial_hold`. Bežná pauza sa nepoužíva, pretože blokuje aj príkazy. Počas pracovných cyklov sa čas aj smeny menia podľa bežných pravidiel. Chýbajúcu obsluhu sprievodca rieši návratom do Kancelárie; pri absencii ukáže existujúce zastupovanie.

Počas aktívneho tutoriálu automatické prevzatie hotového odliatku počká na hráčov klik. Po dokončení alebo preskočení opäť platí pôvodné automatické prevzatie. Ostatné výrobné pravidlá, ceny a riziko nepodarku zostávajú zachované.

Uloženie obsahuje voliteľný objekt `tutorial` s verziou 1, stavom `active` / `completed` / `skipped`, krokom, návratovým krokom pri prerušení kvôli obsadeniu a aktuálnou profesiou. Staré uloženia bez objektu tutoriál nespúšťajú. Celková schéma hry zostáva 14.

## Overenie

Spúšťaj v Godote 4.7.2 z koreňa projektu:

- `godot --headless --path godot --script res://tests/RunTests.gd` — existujúce simulačné a UI regresie.
- `godot --headless --path godot --script res://tests/TestTutorial.gd` — celý výrobný cyklus, nepodarok, zmena smeny, uloženie/obnovenie, staré uloženie, dokončenie a preskočenie.
- `godot --headless --path godot --script res://tests/TestTutorialInput.gd` — skutočné kliknutia, blokovanie okolitého ovládania a skratiek, potvrdenie predvoleného výrobku a preskočenie počas výroby.
- `godot --path godot --script res://tests/capture_tutorial.gd` — kontrola viditeľnosti cieľov a neprekrývania boxu; snímky desktopu a mobilu v `godot/artifacts/tutorial-*.png`.

Testy tutoriálu zastavujú autosave a nemenia používateľovo uloženie. Sú to samostatné SceneTree testy, preto sa spúšťajú oddelene od existujúceho synchronného runnera.
