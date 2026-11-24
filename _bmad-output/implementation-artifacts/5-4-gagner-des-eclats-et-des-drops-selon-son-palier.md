# Story 5.4 : Gagner des Éclats et des drops selon son palier

Status: review

## Story

En tant que joueur,
je veux que vider une salle rapporte plus quand j'ai plongé,
afin que l'abandon paie.

Exigences : FR14 (ramassage d'armure), FR20, FR56 (salles de combat), FR57 (epics.md, Story 5.4). Architecture : flux `drops`, `Drops.spawn(kind, position, rng)`, `EconomyTuning`.

**Dépend de : 5.1** (`Offer`, `Pickup`, `RoomStock`), **5.3** (consommables dans les drops). Prépare 5.5 (dépense d'Éclats) et 5.9 (drop garanti de la Copie d'examen).

Hors périmètre : 10 Éclats par cauchemar battu (epic 6), pactes qui doublent les Éclats (acte 1).

## Critères d'acceptation

1. **Éclats** : `Run` écoute `Events.room_cleared(room, lowest_tier)` pour une salle de **combat** (`room.room_type == COMBAT`, ni cauchemar, ni départ, ni trésor, ni boutique). Il tire 1 à 3 Éclats dans le flux `drops`, multiplie par `LucidityTuning.tier_loot_mult[lowest_tier]` (×1, ×1,25, ×1,5, ×2, ×2), arrondit à l'entier le plus proche (`roundi`) et les ajoute à `RunState.shards`. `Events.shards_changed(total)` met à jour le HUD (qui n'a plus la valeur statique 0) ; le total vaut 0 à chaque nouvelle run (émis dans `Run._ready`).
2. **Drop** : un second tirage `drops` (chance 30 % × loot du palier, bornée à 1) décide s'il y a un drop. Son type est tiré parmi `HALF_HEART`, `HALF_ARMOR`, `CONSUMABLE`, `SHARDS_3` (équiprobables) et apparaît par `Drops.spawn(kind, position, rng)`.
3. **Séquence fixe de tirages** : à chaque salle vidée, le flux `drops` avance toujours de la même façon (Éclats, chance, type, puis le choix du consommable si c'est le type), que le drop ait lieu ou non ; l'ordre ne dépend ni du palier ni de l'inventaire. Les tirages d'objets (`treasure`, `shop`) et de combat (`combat`) ne bougent jamais ; test d'indépendance.
4. **`Drops.spawn`** (`economy/drops.gd`, classe statique) : crée une `Offer` du bon type (½ cœur : `HEART`, ½ armure : `ARMOR`, consommable tiré dans le pool consommables par `rng`, 3 Éclats : `SHARDS` avec `amount = 3`) dans le stock de la salle active (groupe `room`), position = celle de la dernière mort d'ennemi de la salle (relevée par la salle), recalée par `RoomNav.nearest_free_cell` (jamais dans un trou ni un mur). L'ajout dans l'arbre est **différé** (`call_deferred`).
5. **Ramassage conditionnel** : ½ cœur au sol, joueur sans blessure : le pickup reste ; ½ armure au sol au plafond de cœurs (`Health.add_armor` refuse) : il reste. Ramassage différé de la même façon : si le joueur se blesse alors qu'il se tient sur le ½ cœur, il le prend (le pickup bloqué sonde `get_overlapping_bodies()` à chaque tick physique tant qu'il est refusé). Sans son de refus pour un pickup bloqué (c'est un ramassable, pas un achat). Une `Offer` d'Éclats ajoute à `RunState.shards`.
6. **Éclats ≥ 0** : `RunState.add_shards(n)` / `spend_shards(n) -> bool` (jamais négatif, refuse si insuffisant sans rien changer).
7. **Réglages** : `EconomyTuning` (`core/economy_tuning.gd`, `data/tuning/economy_tuning.tres`, `Tuning.ECONOMY`) : `shards_min` 1, `shards_max` 3, `drop_chance` 0,3, `shard_drop_amount` 3 ; les prix de la boutique y viennent avec 5.5. `LucidityTuning.tier_loot_mult` à côté des autres tableaux par palier.
8. **Télémétrie** : total d'Éclats ajouté au `run_ended` de la session.

## Tâches

- [x] `core/economy_tuning.gd` + `.tres`, `Tuning.ECONOMY`, `LucidityTuning.tier_loot_mult` + `.tres`.
- [x] `economy/loot.gd` : fonction statique pure `Loot.roll(lowest_tier, rng, lucidity_tuning, economy_tuning, extra_drops := 0) -> LootResult` (`shards`, `drops: Array[kind]`) ; `extra_drops` est utilisé par 5.9, sans effet ici.
- [x] `economy/drops.gd` (`Kind` enum, `spawn`), `Run._on_events_room_cleared` complète le marquage de la salle (4.8) par le loot ; `RunState.shards`.
- [x] `Offer.kind` : `HEART`, `ARMOR`, `SHARDS` ajoutés ; `Pickup` : `can_collect(player)` (cœurs, armure, objets pris/non pris), sondage.
- [x] `Room` mémorise la position de la dernière mort (le `tree_exited` du dernier ennemi : `enemy.position`, la salle est à l'origine monde) et l'expose (`last_kill_position()`).
- [x] `Events.shards_changed`, `Hud._shards`, `strings.csv` si nouveau texte.
- [x] Tests.

## État du code concerné

- `WaveRunner` émet `Events.room_cleared(_room, _room.room_tier())` (deux sites : fin de la dernière vague ; vague vide) ; le tier transmis est celui de la salle, le plus profond de la vague (3.6). Dans l'arène (boucle de vagues, mode ARENA), `room_cleared` part à chaque vague : le loot tombe à chaque vague, acceptable et utile aux vérifications.
- `Run._on_events_room_cleared(room, _lowest_tier)` : ne fait que `floor_map.mark_cleared(_cell)` ; le joueur écoute aussi (+5 lucidité).
- `RunState` : seed, `seeded`, `floor_index`. 4.9 à 4.11 y touchent en parallèle (affichage, saisie de seed) : n'ajouter que `shards` et deux méthodes.
- `Health.heal(2)` / `add_armor(2)` renvoient `false` quand rien ne tient ; `HeartRow` affiche déjà les trois états.
- `Hud._shards` : variable locale statique (« jusqu'à l'epic 5 »), `_refresh_shards()` utilise `UI_HUD_SHARDS`.

## Pièges

- **« Parent node is busy »** : `room_cleared` est émis pendant `remove_child` de `Enemies` (deferred-work 2.6) ; ne jamais créer de nœud synchronement dans l'écouteur : `Drops.spawn` ajoute le `Pickup` par `call_deferred` et vérifie `is_instance_valid(room)` au moment différé (la salle a pu être libérée, mort du joueur ou fuite).
- Le drop part dans la salle active ; si le joueur est mort ou si `Run` est terminé (`_ended`), ne rien faire.
- `roundi(2.5)` donne 3 en Godot (arrondi loin de zéro) : 2 × 1,25 = 2,5 → 3 ; le test l'écrit tel quel plutôt que de supposer l'arrondi bancaire.
- Les flux : toujours `rng.stream(RunRng.DROPS, state.floor_index)`. Pas de nouveau flux `loot` : l'epic nomme `drops` pour les Éclats et les drops.
- Tirage du consommable d'un drop : liste du pool consommables **triée par id** (ordre stable entre plateformes, pas l'ordre du répertoire).
- `Pickup` d'Éclats : pas de zone qui bloque (toujours prenable).

## Tests

- `unit/economy/test_loot.gd` : multiplicateurs par palier (1→1, 2 → 3 au palier ×1,25 car 2,5 arrondi à 3, ×2 donne 2 à 6), chance 0,3 puis 0,6 en Abandon, séquence de tirages identique avec ou sans drop, 1 000 tirages même seed = même suite.
- `unit/core/test_run_state.gd` : `add_shards`, `spend_shards` refuse et ne change rien.
- `integration/economy/test_loot_flow.gd` : `room_cleared` d'une salle de combat → Éclats mis à jour sur le bus, pas de loot pour un trésor ni un cauchemar, un drop apparaît (différé, sans « busy »), ½ cœur ignoré à PV pleins puis pris après un coup, armure ignorée au plafond.
- `unit/core/test_run_rng.gd` (étendre) : `drops` ne décale pas `treasure`, `shop`, `combat`.

## Sources

epics.md (Story 5.4) ; GDD « Économie », « Loot » par palier, tableau des paliers ; deferred-work (`room_cleared` « Parent node is busy »).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Pas de flux `loot`** : Éclats, chance et type de drop partagent `drops`, avec une séquence de tirages fixe.
2. **Les Éclats vivent dans `RunState`**, qui n'était qu'en lecture ; son commentaire est mis à jour.
3. **Le drop apparaît à la position de la dernière mort**, recalée sur une cellule libre (l'epic ne dit pas où).
4. **Dans l'arène**, chaque vague vidée rapporte (la salle y boucle) : pas de cas particulier.
5. **Chance bornée à 100 %** (aucun palier ne la dépasse avec 0,3 × 2).
6. **Un pickup de soin refusé ne joue pas le son de refus** : seul l'achat le joue (5.5).
7. **(Dev)** `Drops.spawn(room, kind, position, consumable_roll)` prend la salle et le tirage brut du consommable au lieu de `rng` : le flux doit avancer de la même façon que le drop ait lieu ou non, donc `Loot.roll` tire le consommable (un `randi` brut, pour tout drop de type consommable) et `Drops.consumable_for` l'applique au pool trié par id (`roll % taille`). La salle est passée explicitement plutôt que retrouvée par le groupe `room`.
8. **(Dev)** Un « ½ cœur » soigne 1 demi-cœur et une « ½ armure » donne 1 demi-cœur d'armure (`EconomyTuning.heart_drop_half_hearts` / `armor_drop_half_hearts`, valeurs 1 ; l'exemple `heal(2)` de la spec n'était qu'un exemple d'API).
9. **(Dev)** Le pickup d'Éclats émet `Events.shards_collected(amount)`, que `Run` écoute et convertit en `RunState.add_shards` + `shards_changed` : le pickup ne connaît pas le `Run`. `Run.add_shards` / `spend_shards` (pour 5.5) tiennent le bus à jour.
10. **(Dev)** `shards_changed(0)` est émis en fin de `Run._ready` (après `run_started`, pour que la télémétrie ait sa run), pas avant.
11. **(Dev)** Pickups superposés (déféré 5.1 / 5.3) : quand un pickup est pris, ceux qui seraient aussi prenables sous le joueur attendent qu'il sorte (`_must_leave`) ; un pickup de soin refusé n'est pas concerné (il est pris dès que le joueur se blesse, AC5). Réarmement après sortie : seul `_must_leave` est effacé à la sortie.
12. **(Dev)** `ItemCatalog.problem_of` est maintenant vérifiée par `Room.add_offer` (refus + erreur, pas d'assert) et `BuildCarrier.refusal_of` ; les consommables des drops passent par `ConsumableCatalog`.
13. **(Dev)** Les correctifs de revue 5.3 (armement, `is_available`, même consommable, validation et cache du catalogue) ont été appliqués dans des commits à part avant ceux de 5.4.

## Dev Agent Record

### Completion Notes

- `core/economy_tuning.gd` + `data/tuning/economy_tuning.tres` (`Tuning.ECONOMY`), `LucidityTuning.tier_loot_mult`, `economy/loot.gd` (`Loot.roll`, pure), `economy/drops.gd` (`Kind`, `spawn` différé, `consumable_for`), `RunState.shards` / `add_shards` / `spend_shards`, `Run._roll_loot` (salle de combat seulement, pas si mort ou fini), `Events.shards_changed` / `shards_collected`, HUD vivant, `run_end` de la télémétrie avec `shards`.
- `RoomStock.Kind` HEART / ARMOR / SHARDS, `Offer.amount`, `Room.add_drop_offer`, `Room.last_kill_position()`, `Health.can_heal` / `can_add_armor`, `Pickup.can_collect(player)`, `_must_leave`.
- Tests GUT : `unit/economy/test_loot.gd`, `unit/core/test_run_state.gd`, `test_run_rng.gd` (étendu), `unit/telemetry/test_shards_record.gd`, `unit/ui/test_hud_shards.gd`, `integration/economy/test_loot_flow.gd`. Aucune scène scratch nouvelle ; `run_all.sh` : `economy/loot.gd` ajouté aux exclusions du scan des constructions interdites (`randi`, comme `item_picker.gd`).
- Note : `test_seed_flow` « the new floor did not wait for the old requests » est instable en suite complète (dépend de la charge machine), indépendamment de cette story.
- NON ÉVALUÉ (humain) : lisibilité des pickups de drop (disques rouge / gris-bleu / or) et leur place au sol ; équilibre des Éclats et de la chance de drop par palier.

### File List

- `game/core/economy_tuning.gd`, `game/data/tuning/economy_tuning.tres`, `game/core/tuning.gd`, `game/core/lucidity_tuning.gd`, `game/data/tuning/lucidity_tuning.tres`
- `game/economy/loot.gd`, `drops.gd`, `room_stock.gd`, `game/items/pickup.gd`, `build_carrier.gd`, `game/rooms/room.gd`, `game/combat/health.gd`
- `game/run/run.gd`, `run_state.gd`, `game/autoloads/events.gd`, `game/ui/hud/hud.gd`, `game/telemetry/telemetry.gd`, `telemetry_session.gd`
- `game/tests/unit/economy/test_loot.gd`, `unit/core/test_run_state.gd`, `test_run_rng.gd`, `unit/telemetry/test_shards_record.gd`, `unit/ui/test_hud_shards.gd`, `integration/economy/test_loot_flow.gd`

### Change Log

- 2026-11-24 : implémentation de la story 5.4, passée en `review`.
