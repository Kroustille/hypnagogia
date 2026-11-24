# Story 5.3 : Porter un consommable

Status: ready-for-dev

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
3. **Utilisation** : nouvelle action d'entrée `use_consumable` (clavier A, manette Y ; réassignable). Sans consommable ou joueur mort : rien (pas de son). L'utilisation réussie vide l'emplacement.
4. **Se pincer** (`data/consumables/pinch.tres`) : `lucidity.gain(25, Source.CONSUMABLE)` (nouvelle valeur d'enum, ajoutée à la fin) et −½ cœur en retirant des PV, jamais de l'armure (`Health.lose_half_hearts_unarmored(amount)` : borne à ½ cœur restant, n'émet pas `player_hit`, n'est pas bloqué par l'invulnérabilité, peut ne pas tuer). **Refus** s'il ne reste que ½ cœur : `POWER_REFUSED_SOUND`, rien n'est consommé ni gagné.
5. **Café** (`data/consumables/coffee.tres`) : pendant 10 s, `MOVE_SPEED` +30 % et `FIRE_RATE` +30 % ; puis pendant 5 s, `MOVE_SPEED` −20 % ; puis plus rien. Tout passe par des modificateurs du `StatBlock` dont la source est l'instance de l'effet (une seule instance : en reprendre un pendant l'effet relance la phase 1, les modificateurs se remplacent, ne s'empilent pas).
6. **Cadence** : `Shooter.set_fire_rate(rate)` appelé quand `FIRE_RATE` change (le cooldown en cours n'est pas rallongé ; la période est recalculée). Base : `Tuning.SHOT.fire_rate`.
7. **Données** : `ConsumableDef` (`id`, `name_key`, `bonus_key`, `cost_key`, `effect_script`, `params: Dictionary[StringName, float]`). Tout vient de `pinch.tres` et `coffee.tres` : 25, ½ cœur, 0,3, 10, 0,2, 5. Aucun nombre dans les scripts d'effet.
8. **Durée** : les durées du Café se comptent en ticks de physique mis à l'échelle de `GameClock.Group.PLAYER` (pause et ralenti respectés) ; `BuildCarrier._physics_process` fait avancer les effets actifs.
9. **Débogage** : F1 fait apparaître le consommable suivant (touche `C`).

## Tâches

- [ ] `items/consumable_def.gd`, `items/consumable_effect.gd` (base : `use(player) -> bool`, `tick(ticks)`, `is_done()`), `items/effects/pinch_effect.gd`, `coffee_effect.gd`, `data/consumables/*.tres`, `ItemCatalog` étendu (ou `ConsumableCatalog`) pour F1 et les pools (5.4, 5.5).
- [ ] `Loadout.consumable`, `Loadout.set_consumable()` qui renvoie l'ancien ; `Offer.kind = CONSUMABLE` avec `consumable: ConsumableDef` ; `Pickup` gère la logique d'armement (`_armed`) pour tous les types (5.1 la prévoit : implémentée ici).
- [ ] `Player._update_consumable_input()` dans `_physics_process` (avant les pouvoirs), `project.godot` : action `use_consumable` (touche A par `physical_keycode`, comme les autres actions ; bouton manette Y = 3) ; légende du tutoriel des contrôles (4.8) : à ajouter si simple, sinon NON FAIT noté.
- [ ] `Shooter.set_fire_rate()`, `Lucidity.Source.CONSUMABLE`, `Health.lose_half_hearts_unarmored()`.
- [ ] `HudSlot.set_content(color, label)`, `Hud` écoute `consumable_changed`.
- [ ] Clés `strings.csv`, tests.

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
3. **Touches** : A / Y comme dans le GDD (`use_consumable`) ; la touche F1 `C` pour le consommable.
4. **Consommable déposé = `Offer` du stock de la salle courante**, armé à la sortie de la zone du joueur.
5. **Café : le malus de vitesse remplace le bonus** (même source), la cadence revient à la normale dès la fin des 10 s.
