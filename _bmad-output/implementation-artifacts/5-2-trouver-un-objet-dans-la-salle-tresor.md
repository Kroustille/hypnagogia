# Story 5.2 : Trouver un objet dans la salle trésor

Status: done

## Story

En tant que joueur,
je veux un objet gratuit dans la salle trésor de chaque étage,
afin d'avoir toujours au moins une pièce de build.

Exigences : FR44 (pas de doublon), FR59 (epics.md, Story 5.2). Architecture : flux `treasure` de `RunRng` (D8), pools en données.

**Dépend de : 5.1** (`ItemDef`, `Offer` / `RoomStock`, `Pickup`, `ItemCatalog`) et **4.7 / 4.8** (la salle trésor est une salle du pool, `Run._enter_cell`). Prépare 5.5 (boutique : même pool, même exclusion).

Hors périmètre : pool cauchemar (acte 1), salle de pacte, salle d'oubli.

## Critères d'acceptation

1. **Pool en données** : `data/pools/treasure_pool.tres` et `data/pools/shop_pool.tres` (`ItemPoolDef`, `economy/item_pool_def.gd` : `items: Array[ItemDef]`). Au MVP, les deux contiennent les 8 objets ; chaque story d'objet (5.1, 5.6, 5.8, 5.9, 5.10) ajoute le sien aux deux `.tres`. Un test vérifie que chaque `ItemDef` de `data/items/` est dans les deux pools.
2. **Tirage à la première entrée** : en entrant pour la première fois dans une salle de type trésor, `Run` demande à `ItemPicker.draw(pool, owned, health, rng.stream(TREASURE, floor_index))` un objet et le range comme `Offer` (position du `PickupSpot` `item`) dans le `RoomStock` de la cellule. À la sortie et au retour, la même offre est là si elle n'a pas été prise, absente sinon : pas de nouveau tirage.
3. **Exclusions** : un objet déjà dans le `Loadout` est exclu, sauf un objet `stackable` (Dent qui tombe). Une `ItemDef` dont `can_be_taken(health)` est faux (Dent à 1 cœur max) est exclue : le tirage se fait parmi les autres. Si le pool filtré est vide, la salle reste sans objet et `Log.warn("economy", ...)` (cas impossible avec 8 objets).
4. **Un seul tirage par appel** sur le flux, quel que soit le nombre d'exclus : la séquence du flux ne dépend que du nombre de salles trésor ouvertes, pas de la taille du pool filtré (le tirage prend un index dans la liste filtrée, c'est tout).
5. **Déterminisme** : même seed et mêmes objets déjà pris = même objet proposé. Les tirages `treasure` ne décalent ni `shop`, ni `drops`, ni `combat` (flux séparés, test).
6. **Piédestal** : l'objet est posé sur un `PickupSpot` (marqueur `rooms/markers/pickup_spot.gd`, enfant du nœud `PickupSpots` de la salle, propriété `slot` : `ITEM`, `CONSUMABLE`, `HEART`, `ARMOR`). La salle trésor provisoire (`onset_treasure_001`) en reçoit un `ITEM` au centre. Le ramassage est gratuit et définitif : le pickup disparaît, `offer.taken = true`.
7. **ASCII et validateur** : `RoomBuilder` accepte `pickup <item|consumable|heart|armor> <x> <y>` ; `RoomValidator` exige, pour une salle trésor, au moins un `PickupSpot` `ITEM` sur une cellule de sol, accessible depuis le point d'entrée, hors des 3 tuiles d'une porte ; pour les autres types de salle, aucun `PickupSpot` (la boutique est ajoutée par 5.5).
8. **Débogage** : le panneau F1 journalise l'objet de la salle trésor de l'étage (`Log.info("economy", "treasure item <id>")` à son tirage).

## Tâches

- [x] `economy/item_pool_def.gd`, `economy/item_picker.gd` (fonction statique pure `draw(...) -> ItemDef`, testable sans scène), `data/pools/*.tres`.
- [x] `rooms/markers/pickup_spot.gd` (+ groupe `Const.GROUP_PICKUP_SPOT`), `Room.pickup_spots()`, nœud `PickupSpots` dans `room_base.tscn`.
- [x] `RoomBuilder` : directive `pickup`, `art_source/rooms/onset_treasure_001.txt` mis à jour, scène regénérée par `tools/build_room.sh` ; `RoomValidator` : règles du critère 7 ; `tools/validate_rooms.sh` vert.
- [x] `Run._enter_cell()` : à la première entrée d'une salle `TREASURE` (stock absent), tirage et `Offer`. Le `RoomStock` est créé pour toute cellule (5.1).
- [x] `Loadout.owned_ids()` et `ItemDef.can_be_taken(health)` utilisés par le tirage.
- [x] Tests.

## État du code concerné

- `RunRng` a déjà les flux `treasure`, `shop`, `drops`, `combat` ; `stream(name, floor_index)` crée un `RandomNumberGenerator` par clé et le garde. Aucun flux nouveau n'est nécessaire dans cet epic.
- `Run` : `rng`, `state.floor_index`, `_enter_cell(cell, entry_side)` (instancie la salle, `RoomOptions`, `floor_map.mark_entered`) ; `floor_map.mark_cleared` pour les salles sans combat (`room.has_fight()` faux) : trésor et boutique sont donc « vidées » dès l'entrée, leurs portes restent ouvertes.
- `onset_treasure_001` : provisoire, vide, 4 portes ; `RoomValidator` ne connaît pas encore les marqueurs de ramassables.
- 5.1 fournit `Room.add_offer()`, `Pickup`, `RoomStock`, `ItemCatalog`.

## Pièges

- Le tirage dépend du `Loadout` du moment : le faire **à la première entrée seulement**, et mémoriser le résultat dans le stock, sinon un retour dans la salle après avoir pris un autre objet changerait l'offre (et décalerait le flux).
- Ne tirer que dans `Run`, jamais dans `Room._ready()` (le `Room` stand-alone n'a pas de `Run`).
- `RoomValidator` charge la salle par `RoomBuilder` : un marqueur `PickupSpot` sans `slot` valide doit être une erreur claire, pas un crash.
- Les cellules `Vector2i` comme clé de `Dictionary` : typer `Dictionary[Vector2i, RoomStock]`.
- Un pickup de piédestal ne doit pas pouvoir être déplacé par une poussée d'Éveil (pas de corps physique, Area2D seule).

## Tests

- `unit/economy/test_item_picker.gd` : exclusion des possédés, Dent autorisée en double, Dent exclue à 1 cœur max, pool vide, un seul tirage par appel (le flux avance de la même façon avec 2 ou 8 candidats).
- `unit/economy/test_item_pool_defs.gd` : tous les objets du catalogue sont dans les deux pools.
- `unit/core/test_run_rng.gd` (étendre) : tirer `treasure` ne change pas `shop` ni `drops`.
- `unit/rooms/test_room_validator_pickups.gd` : trésor sans spot refusé, spot sur un mur refusé, spot près d'une porte refusé.
- `integration/run/test_treasure_room.gd` : `Run` en FLOOR sur seed fixe, entrée trésor → un pickup, deux runs même seed → même objet, objet pris puis retour → plus de pickup, objet non pris puis retour → le même.

## Sources

epics.md (Story 5.2) ; GDD « Pools d'objets » (pools trésor et boutique = 8 objets au MVP), « Pas de doublon » ; architecture D8.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Un `ItemPoolDef` par type de salle** plutôt qu'un seul pool tagué ; les listes sont identiques au MVP mais se séparent à l'acte 1.
2. **Tirage à la première entrée**, résultat figé dans `RoomStock` (le « même objet à la même seed » vaut à objets déjà pris égaux, comme l'epic le dit).
3. **Marqueur `PickupSpot` et directive ASCII `pickup`** (pas de position codée en dur) : même mécanisme pour la boutique (5.5).
4. **Le tirage ne fait qu'un `randi_range` sur la liste filtrée** : un objet exclu change l'objet tiré mais jamais le nombre de tirages.
5. **Pool filtré vide** : salle sans objet plutôt qu'une erreur bloquante (AR28).
6. **Pools à 2 objets** (pas 8) : seuls `falling_tooth` et `lead_legs` existent (5.1) ; chaque story d'objet ajoute le sien aux deux `.tres`, un test GUT échoue si l'un manque.
7. **Catégorie de journal `economy`** ajoutée à `Log.CATEGORIES` (le critère 3 et 8 l'exigent).
8. **`ItemDef.can_be_taken(max_half_hearts: int)`** prend le maximum de demi-cœurs (entier) plutôt que `Health` : le tirage reste pur et testable sans scène. `BuildCarrier.refusal_of` (5.1) n'est pas modifié (même règle, dupliquée en une ligne).
9. **Seul l'emplacement `ITEM` est lu par `Run`** ; `CONSUMABLE`, `HEART`, `ARMOR` sont acceptés par la directive et le validateur mais sans effet avant 5.5 et les stories de soin.
10. **Les autres salles du pool ne sont pas regénérées** pour ajouter le nœud `PickupSpots` (vide) : `Room.pickup_spots()` tolère son absence ; il apparaîtra à leur prochaine regénération.
11. **Pas de touche ajoutée** (critère 8 : seul le journal `treasure item <id>`).
12. **(Revue de code) Pool filtré vide : un tirage quand même.** Le critère 4 veut une séquence du flux qui ne dépend que du nombre de salles trésor ouvertes ; `draw` consomme donc toujours exactement un tirage, même si rien n'est proposable (au lieu de « aucun tirage » de l'implémentation).

### Review Findings

Revue de code 2026-11-24 (trois couches : Blind Hunter, Edge Case Hunter, Acceptance Auditor). 1 patch, 1 reporté, 9 écartés.

- [x] [Review][Patch] Un seul candidat ne fait avancer le flux d'aucun tirage : `RandomNumberGenerator.randi_range(0, 0)` rend 0 sans toucher l'état (vérifié sous Godot 4.7.2), donc le critère 4 (« un seul tirage par appel, quel que soit le nombre d'exclus ») est faux dès qu'un objet est possédé ou que la Dent est refusée à 1 cœur max ; le pool filtré vide ne tire rien non plus (décision 12) [game/economy/item_picker.gd:11-14] — dans `draw`, tirer d'abord `var roll: int = rng.randi()` (avant le test `candidates.is_empty()`), puis `return candidates[roll % candidates.size()]`. Tests (`game/tests/unit/economy/test_item_picker.gd`) : dans `test_one_draw_per_call_whatever_the_number_of_candidates`, ajouter un pool d'un seul candidat comparé à 8 ; `test_an_empty_filtered_pool_gives_null_and_draws_nothing` devient « avance d'un tirage par appel » (comparer à un flux de même seed qui a fait trois `randi()`).

Correctif appliqué et vérifié (2026-11-24, par l’orchestrateur) : `ItemPicker.draw` tire `randi()` avant le test du vide puis prend `roll % taille` ; un appel fait toujours avancer le flux d’un tirage, même avec un seul candidat ou aucun (décision 12). Tests : `test_one_candidate_draws_like_eight` et `test_an_empty_filtered_pool_gives_null_and_still_draws_once` ; `test_item_picker` et `test_treasure*` passent.
- [x] [Review][Defer] `Run.stocks` jamais vidé au changement d'étage rend aussi la salle trésor muette : `first_visit = not stocks.has(cell)` [game/run/run.gd:168] serait faux à l'étage N+1 pour une cellule déjà visitée à l'étage N — reporté, epic 6 (avec l'entrée `Run.stocks` de la revue 5.1)

Réglés par cette story (entrées de `deferred-work.md` étiquetées 5.2) : le test de revisite passe maintenant par `Run._enter_cell` (`test_an_item_left_is_offered_again_and_an_item_taken_is_gone`) ; les pools ne contiennent que des objets du catalogue validé (`test_item_pool_defs` compare aux `ItemCatalog.all()`, une `ItemDef` refusée par `validate()` le fait échouer).

Écartés : ordre de la liste filtrée (ordre du `.tres`, stable, indépendant du `Loadout`) ; pools à 2 objets (décision 6, le test échoue si un objet manque) ; `Room.pickup_spots()` qui tolère l'absence du nœud (seules les salles trésor ont des spots, et elles passent par `RoomBuilder` ; regénérer 33 scènes n'apporte rien) ; spot à x = 296 et non 304 (salle de largeur paire, pas de tuile centrale) ; ids d'`ext_resource` regénérés dans `onset_treasure_001.tscn` (sans effet) ; `load()` du pool à chaque première entrée (cache des ressources) ; insertion de `economy` au milieu de `Log.CATEGORIES` (seul `has()` est utilisé) ; salle trésor jouée seule (mode ROOM / F1) sans objet (le tirage n'appartient qu'à la `Run` d'étage, piège de la story) ; mort / recommencer (nouvelle `Run`, donc stocks et flux neufs : même seed = même objet).

## Dev Agent Record

### Completion Notes

- `economy/item_pool_def.gd` (`ItemPoolDef`), `economy/item_picker.gd` (`draw` / `candidates_of`, statiques, un seul `randi_range` par appel, aucun tirage si le pool filtré est vide), `data/pools/treasure_pool.tres` et `shop_pool.tres`. `Loadout.owned_ids()`, `ItemDef.can_be_taken()`.
- `rooms/markers/pickup_spot.gd` (`PickupSpot`, `Slot`, groupe `Const.GROUP_PICKUP_SPOT`), nœud `PickupSpots` dans `room_base.tscn`, `Room.pickup_spots()`. `RoomBuilder` : directive `pickup <slot> x y` (slot ou coordonnées invalides = erreur de texte). `RoomValidator._check_pickups` : trésor = au moins un spot `ITEM`, autres salles = aucun spot, slot valide, case libre, à 3 tuiles au moins d'une porte, accessible. `onset_treasure_001` : `pickup item 17 9`, scène regénérée, `tools/validate_rooms.sh` : 34 salles valides.
- `Run._enter_cell` : à la première visite d'une cellule `TREASURE` (stock absent), `_stock_treasure` tire dans `rng.stream(TREASURE, floor_index)` et pose l'`Offer` sur le spot ; `Log.info("economy", "treasure item <id>")`. Retour : même stock, donc même offre ou rien.
- Tests GUT : `unit/economy/test_item_picker.gd`, `test_item_pool_defs.gd`, `unit/rooms/test_room_validator_pickups.gd`, `unit/core/test_run_rng.gd` (étendu), `integration/run/test_treasure_room.gd`. `tools/run_tests.sh` : 405 verts (attention : le test d'intégration éloigne le joueur avant de sauter de salle, la physique garde une position un tick de plus).
- Scratch (non versionné) : `run_all.sh` autorise `economy/item_picker.gd` dans la règle « pas de `randi` », comme `floor_generator.gd`.
- NON ÉVALUÉ (humain) : lisibilité du piédestal (placeholder losange doré), position de l'objet au centre de la salle.

### File List

- `game/economy/item_pool_def.gd`, `item_picker.gd`, `game/data/pools/*.tres`, `game/items/item_def.gd`, `loadout.gd`
- `game/rooms/markers/pickup_spot.gd`, `game/rooms/room.gd`, `room_base.tscn`, `game/rooms/validator/room_builder.gd`, `room_validator.gd`, `game/rooms/pool/onset/onset_treasure_001.tscn`, `art_source/rooms/onset_treasure_001.txt`
- `game/run/run.gd`, `game/core/constants.gd`, `game/autoloads/log.gd`
- `game/tests/unit/economy/*`, `game/tests/unit/rooms/test_room_validator_pickups.gd`, `game/tests/unit/core/test_run_rng.gd`, `game/tests/integration/run/test_treasure_room.gd`

### Change Log

- 2026-11-24 : pools d'objets, tirage de la salle trésor à la première entrée, marqueur `PickupSpot`, directive `pickup`, règles du validateur.
