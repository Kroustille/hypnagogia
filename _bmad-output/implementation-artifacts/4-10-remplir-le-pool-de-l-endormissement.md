# Story 4.10 : Remplir le pool de l'Endormissement

Status: ready-for-dev

## Story

En tant que joueur,
je veux au moins 30 salles de combat différentes,
afin que deux runs ne se ressemblent pas.

Exigences : FR38, FR40 (trous omniprésents) (epics.md, Story 4.10). GDD : pool d'au moins 30 salles de combat pour l'Endormissement ; trous « omniprésents » ; chaque salle fixe ses emplacements et ses vagues ; apparitions jamais à moins de 3 tuiles du joueur ; renfort sur un emplacement prévu.

**Dépend de : 4.7** (générateur, catalogue, salles 001 à 012 et provisoires), **4.2 à 4.6** (format, trous, meubles et lampe, chemins, grandes salles : tout ce que les salles peuvent contenir) ; **4.8** pour jouer le résultat. Ne change aucun code de jeu : du contenu et des tests.

Hors périmètre : équilibrage fin (jalon B, avec les parties de Kroustille), art définitif du décor, salles trésor/boutique/cauchemar définitives (epics 5 et 6), pools des autres phases.

## Critères d'acceptation

1. **Quantité** : `rooms/pool/onset/` contient au moins **30** salles de combat `onset_combat_<nnn>.tscn` (numérotées sans trou, 001 à 030 au moins), plus les salles de départ, de trésor, de boutique et de cauchemar existantes (4.7). Les salles 001 à 012 déjà livrées restent (les 009 à 012, « simples », peuvent être enrichies sans changer leur nom).
2. **Trous** : au moins 70 % des salles de combat contiennent des trous (la plupart, FR40) ; au moins 6 salles en ont beaucoup (couloirs sur le vide, îlots, anneaux).
3. **Les 4 ennemis combinés en vagues variées** : chaque ennemi (Somnambule, Veilleuse, Berceuse, Mouton) apparaît dans au moins 10 salles ; au moins 8 salles combinent trois types ou plus ; 2 ou 3 vagues par salle (une seule pour quelques salles d'échauffement) ; une vague compte 2 à 6 ennemis (jamais plus de `WaveRunner.MAX_WAVE_ENEMIES`) ; au plus 2 Moutons par vague ; au plus 4 tireuses par vague ; première vague douce (voir plan de difficulté).
4. **Grandes salles** : au moins 3 salles `WIDE` et 2 `TALL`, parmi lesquelles 1 avec trous et 1 avec meubles.
5. **Éléments de salle** : au moins 6 salles avec meubles et au moins 3 avec une lampe ; obstacles hauts et bas présents dans au moins 15 salles ; aucune salle n'exige de détruire un meuble pour avancer (règle du validateur 4.4).
6. **Validateur** : `tools/validate_rooms.sh` passe sur tout le pool (dimensions, portes, apparitions à ≥ 3 tuiles de chaque porte, renfort présent, accessibilité sans trou isolant, aucune apparition sur un mur, un trou ou un obstacle). Au moins 2 `ReinforcementSpawn` par salle de combat, dont un à plus de 6 tuiles de toute porte.
7. **Portes** : au moins 90 % des salles de combat déclarent les quatre côtés (le générateur s'en sert librement) ; aucune salle n'a moins de deux portes.
8. **Variété sur 10 seeds** (test d'intégration, pool réel) : pour 10 seeds fixes, l'étage est généré avec le vrai catalogue ; les 12 salles de combat tirées **varient** d'une seed à l'autre : aucun couple de seeds n'a le même ensemble, et au moins 20 salles distinctes au total ; invariants de la 4.7 vrais pour les 10 ; le catalogue compte ≥ 30 combats.
9. **Salles jouables** (test de fumée d'intégration, toutes les salles de combat du pool) : charger la salle, démarrer, faire paraître toutes les vagues (les tuer ensuite) : chaque `EnemySpawn` produit un ennemi (aucun refus), `room_cleared` est émis une fois, les portes s'ouvrent.

## Plan de difficulté (valeurs de départ, à régler au jalon B)

| Rang des salles | Vagues | Ennemis par vague | Mélange |
|---|---|---|---|
| 001-008 (déjà livrées) | 1 à 3 | 2 à 5 | selon leur test |
| 013-020 | 2 | 2 à 4 | un ou deux types, trous modestes |
| 021-027 | 2 à 3 | 3 à 6 | trois types, trous et meubles |
| 028-030 et grandes salles | 3 | 4 à 6 | quatre types, trous larges |

La première vague d'une salle ne contient ni Mouton ni plus de 2 tireuses. Le tout est du contenu : un agent peut poser des chiffres plus justes s'il les justifie dans la salle (commentaire de l'ASCII).

## Tâches

- [ ] Rédiger les salles 013 à 030 (et plus si utile) comme textes `art_source/rooms/onset_combat_<nnn>.txt` (format de la 4.2), par lots de 6 : écrire, `tools/build_room.sh`, `tools/validate_rooms.sh`, corriger. Varier les motifs (colonnes, anneau, croix, couloirs, îlots, banc de meubles) ; ne pas dupliquer une salle avec un simple retournement sans le dire (une symétrie par miroir est acceptable si les vagues diffèrent).
- [ ] Enrichir 009 à 012 si besoin pour tenir les quotas.
- [ ] Script de statistiques du pool dans les tests (`tests/integration/rooms/test_pool_content.gd`) : compte les salles, trous, types d'ennemis, tailles, meubles, lampes, portes, ordre de numérotation.
- [ ] `tests/integration/generation/test_floor_real_pool.gd` (critère 8) et `tests/integration/rooms/test_pool_smoke.gd` (critère 9).
- [ ] Mettre à jour la liste des salles dans le Dev Agent Record (nom, taille, ennemis, trous, meubles) : le jalon B s'en servira pour équilibrer.
- [ ] Ne rien réécrire dans `game/.scratch` ; `run_all.sh` une fois.

## État du code concerné

- Le pool réel compte 001 à 008 (4.2 à 4.6) et 009 à 012 (4.7), plus départ, trésor, boutique, cauchemar provisoires. `RoomCatalog` trie par identifiant ; `FloorGenerator` tire dans `rooms` après tri.
- `WaveRunner` : `MAX_WAVE_ENEMIES = 12` ; les apparitions parcourent les `EnemySpawn` dans l'ordre de l'arbre, la salle repousse un point trop proche du joueur (3 tuiles) ou occupé.
- Ennemis (`data/enemies/*.tres`) : Somnambule (2,5 tuiles/s), Veilleuse (tire toutes les 2 s, immobile), Berceuse (1,5 s, 2 tuiles/s), Mouton (charge). Un tireur derrière un obstacle haut gâche ses tirs (pas de ligne de vue, décision 2.4).
- Le validateur (4.2 à 4.4, 4.6) porte toutes les règles de forme ; cette story n'ajoute pas de règle, sauf si une règle manque pour un quota (ex. portes déclarées).

## Pièges

- Un mauvais placement de trous peut isoler une porte ou une zone de combat : le validateur le dit, mais relire aussi à la main les salles de très grands trous.
- Des tireuses toutes alignées derrière un obstacle haut ne sont qu'une salle sans danger : vérifier à l'œil la lisibilité à la capture WSLg sur quelques salles (NON VÉRIFIÉ par un humain, à signaler dans `deferred-work.md`).
- Taille du `.tscn` : une salle de 72×19 avec beaucoup de cellules peintes est plus grosse, mais reste sous 100 Ko ; ne pas ajouter de textures par salle (le tileset est partagé).
- Les nouvelles salles sont de simples `.tscn` : relancer `godot --headless --path game --import` avant de lancer les tests, sinon le catalogue ne les voit pas.
- Les 30 salles chargées d'un coup (catalogue) coûtent plusieurs centaines de ms : le catalogue est mis en cache et le test réel ne l'instancie qu'une fois.
- Le test des 10 seeds du pool réel est déterministe (seeds fixes) mais dépend du contenu : si le quota de 20 salles distinctes échoue après un ajout, c'est le contenu (portes manquantes) qui change, pas le test.

## Fichiers prévus

`art_source/rooms/onset_combat_0xx.txt`, `game/rooms/pool/onset/onset_combat_013..030.tscn` (et plus), `tests/integration/rooms/test_pool_content.gd`, `test_pool_smoke.gd`, `tests/integration/generation/test_floor_real_pool.gd`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Quotas chiffrés** (70 % de trous, 4 types ≥ 10 salles, 3 grandes ≥ 2 hautes, 6 meubles, 3 lampes) : l'epic dit « la plupart » et « quelques » ; ces nombres servent de seuils de test.
2. **Salles produites par l'outil ASCII** (décision de la 4.2) : le contenu est verifié par validateur et tests de fumée, pas jugé à l'œil ; le jugement humain (lisibilité, plaisir) reste NON ÉVALUÉ jusqu'au playtest du jalon B.
3. **Au moins 2 renforts par salle** (le GDD exige un renfort prévu) pour que le tirage `combat` ait un choix, dont un loin des portes.
4. **Pas de duplication par retournement sans vagues différentes** : variété réelle plutôt que quantité.
5. **Plan de difficulté provisoire** : réglé au jalon B.
6. **Une seule salle de départ, trésor, boutique, cauchemar** : le contenu définitif viendra avec les epics 5 et 6.

## Dev Agent Record

### Agent Model Used

### Completion Notes

### File List
