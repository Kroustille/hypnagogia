# Story 5.3 : Porter un consommable

Status: done

## Story

En tant que joueur,
je veux porter un consommable à double tranchant,
afin de le garder pour le bon moment.

Exigences : FR55 (epics.md, Story 5.3). Architecture : `ConsumableDef` (suit le modèle `ItemDef`), `StatBlock` pour les effets temporaires.

**Dépend de : 5.1** (`BuildCarrier`, `Pickup` / `Offer`, `StatBlock` étendu : `MOVE_SPEED`, `FIRE_RATE`). Prépare 5.4 (drop de consommable) et 5.5 (consommable de la boutique).

Hors périmètre : les autres consommables du brainstorm (acte 1).

## Critères d'acceptation

1. **Emplacement** : le `Loadout` porte au plus un consommable (`ConsumableDef` + rien d'autre). Le ramasser l'inscrit dans l'emplacement `ConsumableSlot` du HUD (icône provisoire : carré coloré + initiale du nom, via `HudSlot.set_content()`) ; `Events.consumable_changed(id, name_key)` (id vide = emplacement libre). Une bannière annonce nom, effet et coût (5.1).
2. **Remplacement** : en ramasser un second dépose l'ancien au sol, sur la position du joueur, comme `Offer` du stock de la salle. Le consommable déposé est **armé** seulement quand le joueur a quitté sa zone (`body_exited`) : on ne le reprend pas aussitôt (et on ne boucle pas entre deux consommables).
3. **Utilisation** : nouvelle action d'entrée `use_consumable` (clavier : touche physique Q, soit A sur AZERTY, voir décision 3 ; manette Y ; réassignable). Sans consommable ou joueur mort : rien (pas de son). L'utilisation réussie vide l'emplacement.
4. **Se pincer** (`data/consumables/pinch.tres`) : `lucidity.gain(25, Source.CONSUMABLE)` (nouvelle valeur d'enum, ajoutée à la fin) et −½ cœur en retirant des PV, jamais de l'armure (`Health.lose_half_hearts_unarmored(amount)` : borne à ½ cœur restant, n'émet pas `player_hit`, n'est pas bloqué par l'invulnérabilité, peut ne pas tuer). **Refus** s'il ne reste que ½ cœur : `POWER_REFUSED_SOUND`, rien n'est consommé ni gagné.
5. **Café** (`data/consumables/coffee.tres`) : pendant 10 s, `MOVE_SPEED` +30 % et `FIRE_RATE` +30 % ; puis pendant 5 s, `MOVE_SPEED` −20 % ; puis plus rien. Tout passe par des modificateurs du `StatBlock` dont la source est l'instance de l'effet (une seule instance : en reprendre un pendant l'effet relance la phase 1, les modificateurs se remplacent, ne s'empilent pas).
6. **Cadence** : `Shooter.set_fire_rate(rate)` appelé quand `FIRE_RATE` change (le cooldown en cours n'est pas rallongé ; la période est recalculée). Base : `Tuning.SHOT.fire_rate`.
7. **Données** : `ConsumableDef` (`id`, `name_key`, `bonus_key`, `cost_key`, `effect_script`, `params: Dictionary[StringName, float]`). Tout vient de `pinch.tres` et `coffee.tres` : 25, ½ cœur, 0,3, 10, 0,2, 5. Aucun nombre dans les scripts d'effet.
8. **Durée** : les durées du Café se comptent en ticks de physique mis à l'échelle de `GameClock.Group.PLAYER` (pause et ralenti respectés) ; `BuildCarrier._physics_process` fait avancer les effets actifs.
9. **Débogage** : F1 fait apparaître le consommable suivant (touche `K`, `C` étant déjà prise par le rejeu de la graine).

## Tâches

- [x] `items/consumable_def.gd`, `items/consumable_effect.gd` (base : `use(player) -> bool`, `tick(ticks)`, `is_done()`), `items/effects/pinch_effect.gd`, `coffee_effect.gd`, `data/consumables/*.tres`, `ItemCatalog` étendu (ou `ConsumableCatalog`) pour F1 et les pools (5.4, 5.5).
- [x] `Loadout.consumable`, `Loadout.set_consumable()` qui renvoie l'ancien ; `Offer.kind = CONSUMABLE` avec `consumable: ConsumableDef` ; `Pickup` gère la logique d'armement (`_armed`) pour tous les types (5.1 la prévoit : implémentée ici).
- [x] `Player._update_consumable_input()` dans `_physics_process` (avant les pouvoirs), `project.godot` : action `use_consumable` (touche physique Q (`physical_keycode` 81) ; bouton manette Y = 3) ; légende du tutoriel des contrôles (4.8) : à ajouter si simple, sinon NON FAIT noté.
- [x] `Shooter.set_fire_rate()`, `Lucidity.Source.CONSUMABLE`, `Health.lose_half_hearts_unarmored()`.
- [x] `HudSlot.set_content(color, label)`, `Hud` écoute `consumable_changed`.
- [x] Clés `strings.csv`, tests.

## État du code concerné

- `Player._try_awakening()` / `_try_glide()` : modèle des refus (`Audio.play_sfx(POWER_REFUSED_SOUND, 1)`), lecture d'`Input.is_action_just_pressed` après `clock_scale > 0`.
- `Lucidity.gain(amount, source)` plafonne à 100 et renvoie le gain réel ; `Source` est un enum à étendre (valeurs explicites).
- `Shooter` : `_period_ticks` fixé dans `_init` ; `tick()` porte déjà la logique de reliquat fractionnaire.
- `HudSlot` : cadre vide seulement ; `Hud.item_slots()` renvoie [actif, consommable].
- Pas d'action d'entrée d'objet dans `project.godot` (seules `power_1`, `power_2`, `dash`, `shoot`, `pause`, ...).

## Pièges

- L'action `use_consumable` doit être traitée dans `_physics_process` du joueur (`process_mode` du joueur désactivé pendant le fondu de 4.8 : pas d'usage dans le noir, voulu).
- Une `ConsumableDef.params` mal typée dans un `.tres` (Dictionary non typé) : lire avec `get(key, 0.0)` et refuser une clé absente avec `Log.error` à la validation.
- Déposer l'ancien par terre : `add_child` dans le callback d'Area2D est interdit, la collecte est déjà différée (5.1) ; l'ancien consommable est ajouté dans cette même fonction différée.
- Un dépôt sur une cellule de mur ou de trou : poser l'offre à `RoomNav.nearest_free_cell`, jamais dans un trou (le consommable tomberait hors de portée).
- `Health.lose_half_hearts_unarmored` ne doit pas déclencher `Events.player_hit` (ni lucidité, ni télémétrie « mort ») ; la mort est impossible par ce chemin, à garantir par le refus à ½ cœur.
- Café relancé : ne pas laisser deux timers ; l'effet est un seul objet réutilisé.

## Tests

- `unit/items/test_pinch_effect.gd` : +25 de lucidité (plafonné à 100), −1 PV d'un demi-cœur, armure intacte, refus à ½ cœur sans rien consommer ni gagner.
- `unit/items/test_coffee_effect.gd` : phase 1 (+30 % vitesse et cadence), phase 2 (−20 % vitesse, cadence normale), fin (tout revenu), relance sans empilement, durées en ticks avec `GameClock` ralenti.
- `unit/player/test_shooter_rate.gd` : `set_fire_rate` change la période sans salve gratuite.
- `integration/items/test_consumable_slot.gd` : ramasser deux consommables dépose le premier, non repris avant `body_exited`, `use_consumable` simulé vide l'emplacement, `Events.consumable_changed` émis.

## Sources

epics.md (Story 5.3) ; GDD « Consommables » ; deferred-work (`Shooter` / cadence, pas de borne).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Un consommable utilisé est consommé d'un coup** (pas de charges) ; Café repris pendant son effet relance la phase 1.
2. **Se pincer ne passe pas par le `Hurtbox`** : pas d'invulnérabilité de coup déclenchée, pas de `player_hit`, pas de télémétrie de mort. Le coût est lu comme un prix, pas un coup.
3. **Touches** (corrigé au développement) : la touche A du GDD est celle de l'AZERTY ; les actions de déplacement sont physiques (W/A/S/D QWERTY = Z/Q/S/D AZERTY) et `physical_keycode` 65 est déjà `move_left`. `use_consumable` prend donc la touche physique **Q** (81), libre, qui s'affiche A sur un clavier AZERTY (l'aide des contrôles lit la disposition) ; manette Y (bouton 3, libre : RB dash, LB Glissement, Start pause, Back carte). Touches du clavier déjà prises : W A S D, Espace, Tab, Échap, R (recommencer), F1 à F5, clic droit, Maj gauche. **Réservé pour 5.8** : `use_active` prend **E** (physique 69, libre) et le bouton manette X (2, libre) ; ne rien y mettre d'autre. Touche F1 du consommable : `K` (`C` = rejeu de la graine).
4. **Consommable déposé = `Offer` du stock de la salle courante**, armé à la sortie de la zone du joueur.
5. **Café : le malus de vitesse remplace le bonus** (même source), la cadence revient à la normale dès la fin des 10 s.
6. **Pendant la chute du Café** seule la vitesse est réduite de 20 % pendant les 5 s ; la cadence est normale (décision 5).
7. **Paramètres** : `pinch` : `lucidity_gain` 25, `half_hearts_cost` 1 ; `coffee` : `boost` 0,3, `boost_seconds` 10, `crash` 0,2, `crash_seconds` 5. `ConsumableCatalog` refuse un `.tres` sans une clé requise par son effet (`required_params()`), `Log.error` + assert.
8. **Un consommable déposé sur une cellule bloquée** (mur, trou, meuble) est posé au centre de la plus proche cellule libre de la grille de navigation ; sinon, exactement sous le joueur.
9. **Armement** : `Offer.armed` ; le pickup désarmé s'arme à `body_exited` ou, s'il n'a jamais touché le joueur (salle revisitée, joueur ailleurs), 3 ticks après sa création quand le joueur ne le recouvre pas. Le premier cas est celui de la story ; le second évite un consommable mort à jamais.
10. **Consommable et vie à ½ cœur** : `PinchEffect` refuse si `half_hearts - coût < 1`. `Shooter.set_fire_rate` raccourcit au besoin le temps de recharge en cours à la nouvelle période (jamais de salve gratuite, jamais d'attente plus longue).
11. **Légende des contrôles (4.8)** : ligne ajoutée (`UI_TUTORIAL_CONSUMABLE`, bouton Y nommé dans `JOY_BUTTON_NAMES`).
12. **Nouvelle partie** : le HUD vide l'emplacement à `run_started` (le joueur d'une nouvelle `Run` commence sans consommable).
13. **(Revue)** Se pincer à 100 de lucidité reste permis (AC4 ne refuse qu'à ½ cœur ; le joueur choisit) : pas de refus « lucidité pleine ».
14. **(Revue)** Un consommable déposé non armé est grisé comme un pickup refusé (`is_available()` tient compte de `_armed`) : « inerte = grisé », règle du pickup de 5.1.
15. **(Revue)** Ramasser un consommable du même id que celui porté reste un échange (bannière, dépôt) ; le refuser est reporté à 5.4 (deferred-work).

### Review Findings

Revue de code 2026-11-24 (trois couches : Blind Hunter, Edge Case Hunter, Acceptance Auditor). Les AC 1 à 9 sont tenus ; trois correctifs sur l'armement du pickup.

- [x] [Review][Patch] Pause / fondu de porte arment le consommable déposé sous le joueur [game/items/pickup.gd:102] — `Main._freeze` (pause, perte de focus) et `Run.travel` passent la salle en `PROCESS_MODE_DISABLED` : l'Area2D sort de l'espace physique et émet `body_exited` (vérifié par une scène : `can_process()` vaut false pendant ce signal) ; `_on_body_exited` arme alors le pickup et écrit `offer.armed = true`. À la reprise, `body_entered` revient et le consommable est repris aussitôt (échange à chaque pause, contraire à l'AC2). Correctif : dans `_on_body_exited`, `if not _armed and can_process() and _player.can_process(): _arm()`.
- [x] [Review][Patch] Le repli des 3 ticks arme un pickup que le joueur va toucher [game/items/pickup.gd:118] — (a) pendant le fondu, le joueur est désactivé (hors espace physique) alors que la nouvelle salle tourne : une offre non armée près de la porte d'entrée s'arme et est prise à la fin du fondu ; (b) un dépôt déplacé vers la cellule libre la plus proche (joueur qui plane ou dashe au-dessus d'un trou) ne recouvre pas le joueur, s'arme en 3 ticks et est repris dès que le joueur atterrit dessus. Correctif : `if not _player.can_process(): _alive_ticks = 0; return` en tête de `_update_arming`, et armer seulement si `_alive_ticks >= ARMING_SETTLE_TICKS and global_position.distance_to(_player.global_position) > ARM_DISTANCE_PX` (nouvelle constante `ARM_DISTANCE_PX: float = RADIUS_PX + Const.TILE_SIZE`) au lieu de « pas de chevauchement ».
- [x] [Review][Patch] Un consommable déposé non armé n'est pas grisé [game/items/pickup.gd:74] — `is_available()` ignore `_armed`, donc `_refresh_look()` le dessine prenable alors qu'il est inerte (doc : « grisé et inerte quand il ne peut pas être pris »). Correctif : `return not _collected and _armed and _player != null and _can_take()` (décision 14).

Correctifs appliqués et vérifiés le 2026-11-24 (un test GUT chacun dans `test_consumable_slot.gd`, suite verte).

## Dev Agent Record

### Completion Notes

- `items/consumable_def.gd` (`ConsumableDef`), `consumable_effect.gd` (base : `use`, `tick`, `is_done`, `cancel`, `required_params`), `effects/pinch_effect.gd`, `effects/coffee_effect.gd` (phases IDLE / BOOST / CRASH, une source de modificateurs = l'instance), `consumable_catalog.gd` (`all`, `by_id`, `problem_of`, `make_effect`), `data/consumables/pinch.tres` et `coffee.tres` (tous les nombres).
- `Loadout.consumable` / `set_consumable()` (renvoie l'ancien) / signal `consumable_changed` ; `BuildCarrier` : `acquire_consumable` (bannière + journal), `use_consumable` (`UseResult` NONE / USED / REFUSED), effets durables gardés par id et avancés dans `_physics_process` à l'échelle du groupe PLAYER, relais `Events.consumable_changed(id, name_key)`.
- `RoomStock.Kind.CONSUMABLE`, `Offer.consumable` / `armed` / `id()`, `add_consumable()` ; `Pickup` : armement, signal `consumable_replaced`, dessin rond ; `Room.add_consumable_offer()` (cellule libre, dépose de l'ancien non armé).
- `Player._update_consumable_input` (avant les pouvoirs), action `use_consumable` (Q physique / manette Y), `Shooter.set_fire_rate()` appelé sur `FIRE_RATE`, `Health.lose_half_hearts_unarmored()`, `HudSlot.set_content()` / `clear_content()`, `Hud` écoute `consumable_changed` et `run_started`, F1 `K`, ligne de légende des contrôles, 7 clés `strings.csv`. `Lucidity.Source.CONSUMABLE` existait déjà.
- Tests GUT : `unit/items/test_pinch_effect.gd`, `test_coffee_effect.gd`, `test_consumable_catalog.gd`, `unit/player/test_shooter_rate.gd`, `integration/items/test_consumable_slot.gd`, `unit/ui/test_controls_tutorial.gd` (étendu), aide `tests/support/player_factory.gd`. Pas de scène scratch nouvelle (tout en GUT).
- NON ÉVALUÉ (humain) : ressenti du Café (+30 % / −20 %, durées), lisibilité de l'icône provisoire (carré coloré + initiale) et du pickup rond, confort de la touche Q à côté de W/A/S/D (clavier AZERTY : A à côté de Z/Q), manette Y réelle.

### File List

- `game/items/consumable_def.gd`, `consumable_effect.gd`, `consumable_catalog.gd`, `effects/*.gd`, `loadout.gd`, `build_carrier.gd`, `pickup.gd`, `game/data/consumables/*.tres`
- `game/economy/room_stock.gd`, `game/rooms/room.gd`, `game/player/player.gd`, `shooter.gd`, `game/combat/health.gd`, `game/autoloads/events.gd`, `game/project.godot`
- `game/ui/hud/hud.gd`, `hud_slot.gd`, `game/ui/tutorial/controls_tutorial.gd`, `game/debug/debug_panel.gd`, `game/localization/strings.csv`
- `game/tests/unit/items/*`, `game/tests/unit/player/test_shooter_rate.gd`, `game/tests/unit/ui/test_controls_tutorial.gd`, `game/tests/integration/items/test_consumable_slot.gd`, `game/tests/support/player_factory.gd`

### Change Log

- 2026-11-24 : consommables portés (Se pincer, Café), emplacement HUD, remplacement et armement du pickup, `use_consumable`.
