extends RefCounted
# Help and history preserved from the local web source.
const HELP = """AKO RIADIŤ ZLIEVAREŇOd suroviny
po dobrý obchod.

Najprv zostav tím v Kancelárii. Nová hra začína s 1 000 ₵ a iba s majstrami Mišom a Mirom. Prijmi panvára, taviča, skladníka, obsluhu odstredivky a pieskovača na každú smenu. Nižšie riziká znamenajú vyššiu požadovanú mzdu. Skladníci, obsluha pieskovača a majstri majú zatiaľ iba riziko absencie; ich novú mzdu určuje spoľahlivosť.

Uskladni suroviny. Na začiatku je už uskladnených 60 kg železa a 20 kg zinku, ostatné suroviny sú nulové. Nové nákupy prídu na rampu. Tlačidlom vľavo dole prejdi do skladu, vyber surovinu a uskladni ju. Na začiatku máš otvorené zásobníky železa a zinku. Oceľ stojí 180 ₵, meď 240 ₵ a cín 180 ₵ na odomknutie. Zásobníky môžeš jednotlivo zväčšovať.

Prijmi obsluhu a priprav vsádzku. V Kancelárii vyber uchádzača na konkrétnu pozíciu a smenu. Má vlastný plat, riziko nepodarku 1–15 % a vynechania smeny 0,5–10 %. Bez neho nová dávka nezačne. Hotový kus odnesie na železnú paletu za 4 sekundy. Každý výrobok má vlastný recept. Suroviny sa pri spustení odoberú zo skladu.

Vyrob a uskladni. Pri rúrach je riziko nepodarku 30 % na MK I, 20 % na MK II a 10 % na MK III. K tomu sa pripočíta riziko konkrétnej obsluhy odstredivky. Nepodarok spotrebuje vsádzku, nepridá výrobok a stroj sa po 4 sekundách uvoľní. Robotník prinesie panvu, odleje výrobok a trysky ho schladia. Zapni sériovú výrobu, ak chceš automaticky pokračovať.

Očisti rúry v hale Pieskovač. Presuň odliatu rúru do skladu a otvor tretiu halu. Pieskovač potrebuje vlastnú obsluhu na aktuálnej smene; na naloženie aj skladníka. Bez obsluhy rozpracovaný cyklus počká. Čistenie stojí 6 ₵ a trvá 14 sekúnd. Všetky rúry, oceľové prstence aj bronzové puzdrá možno predávať a dodávať do zákaziek až po vyčistení. Výrobky sa nedajú nakupovať; suroviny áno. Séria automaticky nakladá voľné rúry zo skladu.

Rozhodni o predaji. Predaj hneď na burze, rezervuj výrobky na cenový pokyn alebo dodaj zákazku za pevnú odmenu. Burza sa preceňuje každé 2 herné hodiny.

Buduj vzťahy s firmami. Na prijatie ponuky máš 90 sekúnd, na dodanie 135 sekúnd od prijatia. Dodanie načas zvyšuje dôveru firmy o 10 bodov, zmeškanie ju znižuje o 15. Lepší vzťah prináša väčšie a lepšie platené ďalšie ponuky. Neprijaté ponuky vypršia bez postihu.

Plánuj kapacitu. Voľné miesto pre rozpracovaný výrobok sa rezervuje. Výrobky v cenových pokynoch sa nedajú predať druhýkrát ani použiť na zákazky.

Rast cez rozvoj. Odomkni ďalšie produkty, zväčši sklady a zrýchli obsluhu panvy. Nové zákazky prichádzajú každý deň.

Počítaj s výplatami. Platy závisia od zmluvy každého pracovníka. Nočná má príplatok 50 %. Neprítomný pracovník mzdu za vynechaný čas nedostáva. V Kancelárii zavolaj kolegu rovnakej profesie z inej smeny na nadčas s ďalším 50 % príplatkom. Odstupné po 1 / 2 / 3+ mesiacoch zamestnania je 1 / 2 / 4 týždenné mzdy; mesiac má 28 dní. Mišo (Majster) dohliada od 06:00 do 18:00, Miro (Majster) od 18:00 do 06:00. Ich mzda sa počíta podľa odpracovaných hodín a vypláca spolu s ostatnými pracovníkmi. Mzdy všetkých smien sa sčítavajú a vyplácajú pri začiatku nového týždňa o 00:00 (deň 8, 15, 22…). Jeden týždeň má 7 dní a trvá 21 minút aktívnej hry. Nedoplatok zastaví nové dávky; v Kancelárii ho môžeš doplatiť. Pri nedoplatku ďalšie mzdy nenabiehajú.

Jeden celý deň trvá presne 180 sekúnd aktívnej hry. Pauza, návod a skryté okno zastavia čas. Smeny sa menia o 06:00, 14:00 a 22:00; rozpracovanú panvu dokončí pôvodný robotník. Ide o zjednodušený herný model výroby a obchodovania.

1 – 6 výber stroja · Medzerník akcia · P pauza"""
const NEWS = """4. 10. 2026 · Mobilné rozhranie
Vedľa Novej hry je prepínač mobilného a desktopového zobrazenia. Ručná voľba sa pamätá aj po novej hre. Mobilné rozhranie ponúka dotykové ovládanie, zalamované panely a samostatné tlačidlá na výber zariadení a skladov.

3. 10. 2026 · Nová hra
Tlačidlo Nová hra je vedľa Noviniek v hornej lište. Reset postupu vyžaduje potvrdenie.

3. 10. 2026 · Godot: rozloženie podľa webovej verzie

Responzívne rozhranie, bočné ovládanie, burza, sklady a rozvoj. Doplnené animácie panvy, panvára, pece, pary, iskier a čistenia.

HISTÓRIA AKTUALIZÁCIÍNovinky

25. 9. 2026 · Verzia 21

Skladníci, obsluha pieskovača a majstri už nemajú štatistiku Riziko nepodarku. Odstránená je aj z existujúcich pracovníkov a uchádzačov.

Požadovaná mzda nových uchádzačov týchto profesií závisí iba od spoľahlivosti. Dohodnuté mzdy zamestnancov zostávajú zachované. Náhradné vlastnosti pribudnú neskôr.

25. 9. 2026 · Verzia 20

Nová hra: priamo v sklade 60 kg železa a 20 kg zinku; ostatné suroviny aj rampa sú prázdne. Zásoby rozhraných hier sa nemenia.

Rozšírené priezviská uchádzačov vrátane Kozák, Vojtek, Koleno, Majtán a Zvak.

Nová profesia Obsluha pieskovača na všetky tri smeny: nábor, mzdy, absencie, nadčasy a odstupné. Bez obsluhy pieskovač nezačne ani nepokračuje; kus zostáva v stroji.

CNC 1–6 sa kupujú za 500 / 750 / 1 000 / 1 250 / 1 500 / 1 750 ₵. Vlastníctvo sa ukladá. AMADA je zatiaľ zamknutá. Rezanie ešte nie je súčasťou výroby.

Tlačidlá hál používajú iba názvy bez čísel.

Existujúce uloženia si zachovajú zamestnancov a zásoby. Obsluhu pieskovača treba prijať; CNC, ktoré boli iba náhľadom, treba zakúpiť.

25. 9. 2026 · Verzia 19

Riziko absencie je polovičné: 0,5–10 %, aj existujúcim pracovníkom.

Riziko nepodarku rúry = riziko úrovne odstredivky + riziko jej obsluhy. Panvár ani tavič sa doň nepripočítavajú.

Udalosti smien uvádzajú skutočných pracovníkov v službe.

Aj oceľové prstence a bronzové puzdrá sa musia pred predajom alebo dodaním zákazky očistiť. Cena čistenia ostáva 6 ₵ a čas 14 sekúnd.

Nábor sa filtruje podľa pozície, jednotlivé smeny sú pod sebou.

Teplota taveniny je 1 700 °C.

Nové tlačidlo Novinky uchováva históriu zmien.

Nová hra má otvorené iba sklady železa a zinku. Odomknutie ocele: 180 ₵, medi: 240 ₵, cínu: 180 ₵. Staré uloženia si zachovajú otvorené sklady.

Staré zákazky na neočistené prstence a puzdrá teraz žiadajú očistené kusy. Aktívnym ostáva aspoň 135 sekúnd na dodanie; odmena sa nemení. Predajné pokyny na neočistené kusy sa uvoľnia.

24. 9. 2026 · Verzia 18

Mzdy uchádzačov rastú podľa kvality a spoľahlivosti, obe vlastnosti majú rovnakú váhu.

Nová hra začína iba s majstrami Mišom a Mirom. Ostatných pracovníkov prijíma hráč.

24. 9. 2026 · Verzia 17

Kancelária: nábor 2–5 uchádzačov na miesto, individuálne mzdy a štatistiky.

Dochádzka, absencie a ručné zastupovanie pracovníkom z inej smeny s 50 % príplatkom.

Prepúšťanie a odstupné po 1 / 2 / 3+ mesiacoch: 1 / 2 / 4 týždenné mzdy. Herný mesiac má 28 dní.

Predchádzajúce rozšírenia · do verzie 16

Týždne, spoločná týždenná výplata a štartovací kapitál 1 000 ₵.

Samostatná obsluha každej odstredivky a smeny, odnášanie výrobkov na palety.

Výrobky nemožno kupovať. Rúry sa predávajú až po čistení v Pieskovači.

Termíny zákaziek a vzťahy s odberateľmi, väčšie a lepšie odmenené zákazky za spoľahlivé dodávky.

CNC hala so siedmimi strojmi, signalizáciou a vývodmi na stružliny; zatiaľ vizuálny náhľad.

Pieskovač s vodným čistením, nakladaním a výstupnou koľajou.

Nepodarky s animáciou žeravého kovu, zinok vo vsádzke a odmeny zákaziek znížené o 25 %.

Mišo a Miro sa striedajú po 12 hodinách; nočné mzdy majú 50 % príplatok.

Sklady surovín, burza, viac výrobkov, nákup surovín, denný a nočný cyklus.

Obsluha pece a panvy, naklápanie pece, chladenie vodnými tryskami a výrazná para."""
