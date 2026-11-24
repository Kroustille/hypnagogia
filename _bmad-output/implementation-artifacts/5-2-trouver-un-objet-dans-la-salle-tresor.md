# Story 5.2 : Trouver un objet dans la salle trésor

Status: ready-for-dev

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

- [ ] `economy/item_pool_def.gd`, `economy/item_picker.gd` (fonction statique pure `draw(...) -> ItemDef`, testable sans scène), `data/pools/*.tres`.
- [ ] `rooms/markers/pickup_spot.gd` (+ groupe `Const.GROUP_PICKUP_SPOT`), `Room.pickup_spots()`, nœud `PickupSpots` dans `room_base.tscn`.
- [ ] `RoomBuilder` : directive `pickup`, `art_source/rooms/onset_treasure_001.txt` mis à jour, scène regénérée par `tools/build_room.sh` ; `RoomValidator` : règles du critère 7 ; `tools/validate_rooms.sh` vert.
- [ ] `Run._enter_cell()` : à la première entrée d'une salle `TREASURE` (stock absent), tirage et `Offer`. Le `RoomStock` est créé pour toute cellule (5.1).
- [ ] `Loadout.owned_ids()` et `ItemDef.can_be_taken(health)` utilisés par le tirage.
- [ ] Tests.

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
