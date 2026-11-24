# Story 5.1 : Ramasser un objet et comprendre son prix

Status: review

## Story

En tant que joueur,
je veux ramasser des objets dont le bonus et le coût sont écrits en clair,
afin de choisir mon build en connaissance de cause.

Exigences : FR44, FR46, FR47, AR15 (epics.md, Story 5.1). Architecture : D9 (`StatBlock` + `Loadout`, `ItemDef` + `ItemEffect`, `TagTracker`), P5 (`BuildCarrier`).

**Dépend de : 3.5** (`StatBlock`, `Player.stats`), **4.8** (`Run`, salles par étage, `RoomOptions`), **2.7** (HUD). Aucune autre story 5.x. Cette story pose le socle de tout l'epic 5 : les 5.2 à 5.10 s'y accrochent.

Hors périmètre : salle trésor (5.2), consommables (5.3), Éclats et drops (5.4), objets Chute (5.6), synergies (5.7), objet actif (5.8). Les deux objets de cette story n'ont pas d'`effect_script`.

## Critères d'acceptation

1. **`BuildCarrier`** : nœud enfant du joueur (`items/build_carrier.gd`), créé par `Player._ready()` avec le `StatBlock` existant (`Player.stats` reste l'accès de tout le code actuel, c'est le même objet que `carrier.stats`). Il porte `Loadout` et `TagTracker` et émet `hit_incoming(info: DamageInfo)` (avant l'application, l'objet peut y modifier `amount`), `hit_taken(lost: int, source: int)` (après, seulement si `lost > 0`), `dash_ended`, `room_cleared(room: Node, lowest_tier: int)`. Le joueur les relaie (`_on_hurtbox_damage_received`, `_on_dash_ended`, `_on_room_cleared`). Aucune autre story ne câble de nouveau signal sur le joueur sans passer par lui.
2. **`ItemDef`** (Resource, `items/item_def.gd`) : `id`, `tags: Array[StringName]`, `name_key`, `bonus_key`, `cost_key`, `modifiers: Array[ModifierDef]` (`ModifierDef` : `stat`, `kind`, `value`), `effect_script: Script` facultatif, `lucidity_cost: int` (0 = aucun), `stackable: bool`, `active: bool`, `max_half_hearts_delta: int`, `params: Dictionary[StringName, float]`. Une `ItemDef` sans clé de nom, de bonus ou de coût est refusée au chargement (`ItemCatalog.validate()`, `Log.error`, `assert` en debug).
3. **Ramassage** : passer sur un objet posé au sol (`Pickup`, Area2D sur `LAYER_PICKUPS`) l'ajoute au `Loadout` : chaque copie est un `OwnedItem` (RefCounted), qui est la **source** de ses modificateurs (deux Dents = deux sources, elles s'additionnent) ; son `ItemEffect` éventuel est instancié et attaché (`attach(carrier)`). Le retrait (`Loadout.remove`) appelle `stats.clear_source(owned)` puis `effect.detach()`. Le pickup disparaît ; `Events.item_acquired(item_id, copies)`.
4. **Bannière** : à l'acquisition, une bannière (`ui/hud/banner.gd`, enfant du HUD, texte via `tr()`) affiche nom, bonus et coût de l'objet pendant ~3 s (réutilisée par 5.7 : titre + deux lignes). Signal de bus `Events.banner_requested(title_key, bonus_key, cost_key)`. Un nouvel appel remplace la bannière courante.
5. **Dent qui tombe** (`data/items/falling_tooth.tres`, tags Corps et Chute, `stackable`) : +30 % de dégâts (`ADD_PERCENT`), `max_half_hearts_delta = -2`. Deux copies : +60 %, −2 cœurs. Les PV courants sont ramenés au nouveau max, sans coup ni armure touchée. **Non prenable** si `max_half_hearts + delta < 2` : le pickup est grisé (`modulate`) et ne réagit pas ; vaut aussi quand le joueur n'a qu'un cœur max.
6. **Jambes de plomb** (`data/items/lead_legs.tres`, tag Chute) : tirs traversants (stat `PIERCE`, voir ci-dessous, `BulletParams.pierce`), vitesse de déplacement −20 % (stat `MOVE_SPEED`, `ADD_PERCENT −0.2`). Aucun code propre à l'objet dans la boucle des projectiles.
7. **Stats ajoutées à `StatBlock.Stat`** (valeurs ajoutées **à la fin** de l'enum) : `MOVE_SPEED`, `FIRE_RATE` (utilisée dès 5.3), `PIERCE`, `REAR_SHOT` (utilisée par 5.10), booléens portés par un flottant comme `CAN_FLY_OVER_PITS`. `StatBlock` gagne `set_bounds(stat, min, max)` ; `value_of` borne. Bornes posées par `Player._setup_stats()` : `SHOT_SPEED` < 60 (valeur technique : sous une tuile par tick, refus du `BulletManager`), `HURTBOX_SIZE` ≥ 0,0625, `DAMAGE` ≥ 0, `MOVE_SPEED` ≥ 1, `FIRE_RATE` ≥ 0,5 (deferred-work, revue 3.5, point c).
8. **Branchements** : `PlayerMotor.set_max_speed(tiles_per_s)` appelé quand `MOVE_SPEED` change ; `BulletParams.pierce: bool` lu par `BulletManager` (un tir traversant garde en mémoire les cibles déjà touchées, ne retouche pas la même, continue jusqu'au mur ou à la fin de vie). `Shooter.set_fire_rate()` est ajouté par 5.3.
9. **Débogage** : le panneau F1 fait apparaître l'objet suivant du catalogue (touche `I`) près du joueur.
10. **Télémétrie** : la liste des `item_id` pris est ajoutée à la session (`telemetry_session.gd`).

## Tâches

- [x] `items/` : `item_def.gd`, `modifier_def.gd`, `owned_item.gd`, `loadout.gd`, `tag_tracker.gd` (compte les `id` distincts par tag ; signal `tag_count_changed(tag, count)` ; 5.7 y branche les seuils), `build_carrier.gd`, `item_effect.gd` (base : `attach(carrier)`, `detach()`, `tick(dt)` appelé par le carrier seulement si `wants_tick`, `activate()` pour 5.8), `item_catalog.gd` (charge `data/items/*.tres`, trié, gère le suffixe `.remap` comme `RoomInfo.scene_paths`), `pickup.gd/.tscn`.
- [x] `RoomStock` / `Offer` (`economy/room_stock.gd`) : liste d'`Offer` d'une salle (`kind`, `item: ItemDef`, `position` en coordonnées de salle, `taken`, `price` = 0). `Run` en garde un par cellule (`stocks: Dictionary[Vector2i, RoomStock]`) et le passe à la salle par `RoomOptions.stock` ; `Room._ready()` crée un `Pickup` par offre non prise ; `Room.add_offer(offer)` en ajoute une (F1, drops 5.4). C'est le seul mécanisme de ramassable de l'epic : un objet laissé par terre revient à la prochaine visite.
- [x] `Health.lose_max(half_hearts)` (borne à 2, ramène les PV courants, émet `changed`) et `Health.restore_max()` ; `Player` applique `max_half_hearts_delta` sur `Loadout.item_added/removed`.
- [x] `StatBlock` : nouvelles stats, `set_bounds`, signal `base_changed(stat)` ; `Player` recalcule le rétrécissement Lucide de `HURTBOX_SIZE` quand la base change (deferred-work 3.5, point a). Documenter dans l'architecture D9 que le code garde `StatBlock` / `Kind` / `Player.stats` (point d).
- [x] `BulletParams.pierce`, mémoire par tir dans `BulletManager` ; `Player._on_stat_changed` pousse `PIERCE` dans `_shot_params`.
- [x] `ui/hud/banner.gd`, `Events.banner_requested`, `Events.item_acquired`, clés `strings.csv` (`ITEM_FALLING_TOOTH_NAME/BONUS/COST`, `ITEM_LEAD_LEGS_*`, `UI_BANNER_*`).
- [x] Panneau F1 (`debug/debug_panel.gd`), télémétrie.
- [x] Tests (liste plus bas).

## État du code concerné

- `Player` (`player/player.gd`) crée `stats` dans `_setup_stats()` (bases DAMAGE, SHOT_SPEED, HURTBOX_SIZE, PIT_DAMAGE, CAN_FLY_OVER_PITS ; les paliers de lucidité posent leurs modificateurs avec `lucidity` comme source). `_on_stat_changed` pousse HURTBOX_SIZE, SHOT_SPEED, DAMAGE. Aucune stat de vitesse ni de cadence : `PlayerMotor` et `Shooter` calculent leurs valeurs une fois dans `_init`.
- `Health` (`combat/health.gd`) : `max_half_hearts`, `half_hearts`, `armor`, `heal`, `add_armor`, plafond `_cap_half_hearts`. Pas de moyen de baisser le max.
- `Events.room_cleared(room, lowest_tier)` est émis par `WaveRunner`, y compris pendant que `Enemies` est verrouillé : un écouteur ne doit pas appeler `spawn_enemy()` en synchrone (voir 5.4, 5.9).
- `BulletManager` : une balle touche au plus une cible (`_test_targets` retourne au premier contact) ; `clear_all()` sans garde de réentrance (deferred-work 2.x) : ne jamais l'appeler depuis un signal du manager.
- `Run._enter_cell()` construit `RoomOptions` ; `room.setup()` avant `add_child()`. Les salles du pool sont provisoires pour trésor et boutique.
- HUD : `_shards` statique à 0, emplacements actif et consommable vides (`HudSlot`).

## Pièges

- Le `Pickup` est une Area2D : `body_entered` part d'un callback de physique. Ne pas ajouter de nœud ni changer l'arbre dedans (« Can't change this state while flushing queries ») : le callback ne fait que mémoriser, la collecte se fait en `call_deferred`. Un joueur déjà sur le pickup à son apparition : vérifier `get_overlapping_bodies()` au premier tick.
- Une source libérée reste clé du dictionnaire de `StatBlock` : la source est un `OwnedItem` (RefCounted), jamais un nœud, et `clear_source` est appelé à chaque retrait.
- Un effet qui s'est abonné au `BuildCarrier` doit se désabonner dans `detach()` (D9) ; le carrier libère tous ses effets à sa sortie de l'arbre.
- Le joueur survit aux salles (4.8) : `Loadout` et `StatBlock` vivent sur le joueur, pas sur la salle ; seuls les `Pickup` meurent avec la salle.
- `stat_block.changed` ne s'émet que sur variation réelle : un pickup refusé ne doit pas changer d'état par ce biais.
- Pas de `class_name` redondant avec un autoload ; `OwnedItem` n'étend pas `Node`.

## Tests (GUT, `game/tests/`)

- `unit/items/test_loadout.gd` : ajout/retrait, deux Dents s'additionnent (+60 %), `clear_source` rend la stat, `OwnedItem` libéré sans fuite.
- `unit/items/test_tag_tracker.gd` : deux Dents comptent une fois pour Chute et Corps.
- `unit/items/test_item_catalog.gd` : toutes les `ItemDef` de `data/items/` valides, refus d'une définition sans clé de nom.
- `unit/core/test_stat_block.gd` (étendre) : `set_bounds`, `base_changed`.
- `unit/combat/test_health_max.gd` : `lose_max` borne à 2 et ramène les PV.
- `integration/items/test_pickup_item.gd` : le joueur sur un pickup reçoit l'objet, la bannière est demandée, une Dent est grisée à 1 cœur max, Jambes de plomb : `MOVE_SPEED` −20 % et un tir traverse deux cibles sans toucher deux fois la même.

## Sources

epics.md (Story 5.1) ; GDD « Objets du MVP » ; architecture D9, P5 ; deferred-work (revue 3.5, revue 2.7 `HeartRow`).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **`StatBlock` / `Player.stats` gardés** (le code), l'architecture est alignée sur eux plutôt que l'inverse (`StatModifier` → `StatBlock.Kind`).
2. **Source d'un modificateur d'objet = un `OwnedItem`** (pas le nœud, pas l'`ItemDef`), pour l'empilement de la Dent et pour `clear_source`.
3. **Description d'objet = deux clés** (`bonus_key`, `cost_key`) au lieu d'une seule, car la bannière montre bonus et coût séparément.
4. **`pierce` / `rear shot` / vol au-dessus des trous = stats booléennes** du `StatBlock` (comme `CAN_FLY_OVER_PITS`), pas des champs d'`ItemDef`.
5. **Tous les ramassables passent par `Offer` / `RoomStock`** par cellule : un objet non pris ou déposé survit à la sortie de la salle.
6. **`hit_incoming` ajouté** aux signaux du carrier (absent de l'architecture) : Chute libre (5.6) y ajoute son demi-cœur.
7. **HeartRow** : inchangé, aucun objet n'augmente le max ; le deferred-work reste ouvert pour le jour où le plafond monte.
8. **Touche F1 `I`** pour faire apparaître un objet (à décaler si prise).
9. **Bornes** : `SHOT_SPEED` borné à [0,5 ; 59] (le minimum n'est pas dans la story : une vitesse ≤ 0 ferait refuser chaque tir par `BulletManager`, avec erreur et `assert`).
10. **`Health.restore_max(n)` prend un argument** (la story le donnait sans) : retirer une seule Dent rend 2 demi-cœurs, pas tout ce qui a été perdu ; borné à ce que `lose_max` a pris.
11. **`ItemEffect.owned` est tenu en `WeakRef`** : `OwnedItem` tient l'effet, un lien fort en retour ferait un cycle `RefCounted` (fuite).
12. **Pas de clés `UI_BANNER_*`** : la bannière affiche les trois clés reçues telles quelles (titre, bonus, coût), sans préfixe ni libellé propre. La 5.7 réutilise la même forme.
13. **`ItemCatalog` sans cache statique** : un tableau statique de `Resource` est signalé comme fuite à la sortie du processus ; `all()` recharge (le cache de ressources de Godot fait le travail), usage rare (F1).
14. **`ItemCatalog` refuse aussi deux modificateurs sur la même stat** dans un objet : une source n'en porte qu'un par stat, le second écraserait le premier en silence.
15. **Un objet non empilable déjà possédé est refusé** (`BuildCarrier.refusal_of`), comme la Dent à un cœur : pickup grisé. Aucun objet de la 5.1 n'est concerné en pratique hormis les Jambes de plomb (une seule copie).
16. **Télémétrie** : la liste des objets prise d'une partie va dans l'événement `run_end` (`items`) et le résumé de session compte par `item_id` (`summary.items`) ; pas d'événement propre (l'ordre des événements reste celui que lisent les outils).
17. **Une `Offer` prise reste dans le `RoomStock`** avec `taken = true` (jamais retirée) ; le `Pickup` seul disparaît.
18. **Touche F1 `I`** : libre (aucune action de `project.godot` ni touche du panneau ne l'utilise).

## Dev Agent Record

### Completion Notes

- `items/` : `ModifierDef`, `ItemDef`, `ItemEffect`, `OwnedItem`, `Loadout`, `TagTracker`, `BuildCarrier`, `ItemCatalog`, `Pickup` ; `economy/room_stock.gd` (`RoomStock` + `Offer`). `Run.stocks` (un stock par cellule, `stock_of()`), `RoomOptions.stock`, `Room._setup_pickups()` / `add_offer()` / `pickups()` (nœud `Pickups` créé en code).
- `StatBlock` : 4 stats ajoutées à la fin, `set_bounds`, `base_changed`. `Player._setup_stats()` pose les bornes ; `_on_stat_base_changed` recalcule le rétrécissement de Lucide quand la base de `HURTBOX_SIZE` change (testé). `MOVE_SPEED` pousse `PlayerMotor.set_max_speed()` (les durées de rampe sont conservées). `FIRE_RATE` est une stat mais n'est branchée qu'en 5.3 (`Shooter.set_fire_rate`).
- Tir traversant : `BulletParams.pierce` ; `BulletManager` garde par balle (slot) les ids des cibles déjà touchées (`_pierced`, effacé à la libération du slot), un coup par cible, la balle continue jusqu'au mur ou à la fin de vie. Aucun code d'objet dans la boucle.
- Le joueur relaie `hit_incoming` (avant `apply_damage`), `hit_taken` (si `lost > 0`), `dash_ended`, `room_cleared` (joueur vivant) au carrier.
- Bannière (`ui/hud/banner.gd`, enfant du HUD, `Hud.banner()`), `Events.item_acquired`, `Events.banner_requested`. Textes dans `strings.csv` (`ITEM_*`).
- F1 `I` : `DebugPanel._drop_next_item()` pose l'objet suivant du catalogue à côté du joueur (`Room.add_offer`). Télémétrie : voir décision 16.
- Architecture D9 alignée sur le code (note ajoutée) ; points (a) à (d) du deferred-work « `StatBlock` face aux objets » marqués résolus.
- Tests GUT versionnés : `unit/items/` (loadout, tag tracker, catalogue), `unit/combat/test_health_max.gd`, `test_bullet_pierce.gd`, `unit/core/test_stat_block.gd` (étendu), `unit/telemetry/test_item_record.gd`, `integration/items/test_pickup_item.gd`. `tools/run_tests.sh` : 376 tests verts.
- NON ÉVALUÉ (humain) : lisibilité de la bannière (3 s, 3 lignes, position sous la bande), placeholder du pickup (losange doré), ressenti de −20 % de vitesse et de +30 % de dégâts pour −1 cœur.
- Aucun objet n'est posé automatiquement dans une salle (salle trésor : 5.2) : en jeu, seul F1 `I` en fait apparaître.

### File List

- `game/items/` (`modifier_def.gd`, `item_def.gd`, `item_effect.gd`, `owned_item.gd`, `loadout.gd`, `tag_tracker.gd`, `build_carrier.gd`, `item_catalog.gd`, `pickup.gd`), `game/economy/room_stock.gd`, `game/data/items/falling_tooth.tres`, `lead_legs.tres`
- `game/core/stat_block.gd`, `game/player/player.gd`, `game/player/player_motor.gd`, `game/combat/health.gd`, `game/combat/bullets/bullet_params.gd`, `game/combat/bullets/bullet_manager.gd`
- `game/rooms/room.gd`, `game/rooms/room_options.gd`, `game/run/run.gd`
- `game/autoloads/events.gd`, `game/ui/hud/banner.gd`, `game/ui/hud/hud.gd`, `game/localization/strings.csv`
- `game/debug/debug_panel.gd`, `game/telemetry/telemetry.gd`, `game/telemetry/telemetry_session.gd`
- `game/tests/unit/items/*`, `game/tests/unit/combat/test_health_max.gd`, `test_bullet_pierce.gd`, `game/tests/unit/core/test_stat_block.gd`, `game/tests/unit/telemetry/test_item_record.gd`, `game/tests/integration/items/test_pickup_item.gd`
- `_bmad-output/game-architecture.md`, `_bmad-output/implementation-artifacts/deferred-work.md`

### Change Log

- 2026-11-24 : socle des objets (BuildCarrier, Loadout, ItemDef, Pickup, RoomStock), Dent qui tombe et Jambes de plomb, bornes de stats, tirs traversants, bannière, F1 `I`, télémétrie.
