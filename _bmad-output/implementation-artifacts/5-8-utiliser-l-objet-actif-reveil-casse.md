# Story 5.8 : Utiliser l'objet actif : Réveil cassé

Status: review

## Story

En tant que joueur,
je veux un objet actif qui ralentit le rêve autour de moi,
afin de reprendre la main dans un moment critique.

Exigences : FR45, FR51, AR13 (ralenti par groupe) (epics.md, Story 5.8). Architecture : `GameClock` par groupe, `Loadout` (objet actif avec charge), règle de dépense de lucidité (`try_spend`).

**Dépend de : 5.1** (`ItemDef.active`, `lucidity_cost`, `Loadout`), **5.3** (armement du pickup déposé, emplacement HUD, `HudSlot.set_content`), 3.3 (`Lucidity.try_spend`).

Hors périmètre : autres objets actifs (acte 1).

## Critères d'acceptation

1. **Objet actif** (`data/items/broken_alarm.tres`, tag Temps, `active = true`, `lucidity_cost = 15`, `params.charge_rooms = 3`, `params.slow_factor = 0.5`, `params.slow_seconds = 4`, `effect_script = BrokenAlarmEffect`) ramassé : il occupe l'emplacement `ActiveItemSlot` du HUD, **chargé**. `Loadout.active` est un `OwnedItem` avec `charge` et `charge_max`.
2. **Entrée** : nouvelle action `use_active` (clavier E, manette X ; réassignable), lue dans `Player._physics_process` comme les pouvoirs.
3. **Utilisation réussie** : l'objet est chargé et `lucidity.try_spend(15, &"broken_alarm")` réussit (jauge ≥ 15) : 15 de lucidité sont retirés, `GameClock` ralentit les groupes **ENEMIES, ENEMY_BULLETS et WORLD** à 50 % pendant 4 s puis revient à 1 tout seul ; `PLAYER`, `PLAYER_BULLETS` et `FX` ne changent pas ; la charge tombe à 0. Un son et un anneau signalent l'usage (placeholders).
4. **Refus** : jauge < 15, objet non chargé, joueur mort : `POWER_REFUSED_SOUND`, rien n'est consommé (ni lucidité ni charge). Même si le ralenti est déjà actif.
5. **Recharge** : chaque `room_cleared` (via `BuildCarrier.room_cleared`) ajoute 1 à la charge, plafonnée à `charge_max` (3 salles vidées = rechargé). Le HUD montre la progression (`ActiveItemSlot` : barre de 3 segments, ou remplissage, + `Events.active_item_changed(id, charge, charge_max)`). Un objet récupéré d'une cellule reste avec sa charge.
6. **Objet actif remplacé** : en ramasser un autre dépose l'ancien au sol (position du joueur, `Offer` du stock de la salle, armé à la sortie de la zone) **avec sa charge** (`Offer.charge`) ; le nouveau est chargé s'il est neuf.
7. **`GameClock`** (`autoloads/game_clock.gd`) : nouvelle API `apply_slow(token: Object, groups: Array[Group], factor: float, seconds: float)`, `clear_slow(token)` ; l'échelle d'un groupe est le produit des ralentis actifs (un seul actif par `token`, le même objet relance) ; la durée décroît à chaque tick physique réel, **gelée** quand `paused`, multipliée par `global_multiplier` (le ralenti debug F4 s'applique aussi). `scale(group)` garde sa signature.
8. **Remise à zéro** : `GameClock.reset_slows()` est appelé à `Events.run_started` et à `run_ended` : un ralenti ne survit ni à la mort ni à la relance.
9. **Débogage** : F1 donne l'objet actif (via la touche `I` du catalogue) et une touche `U` le recharge.

## Tâches

- [x] `GameClock` : `_slows` (liste de `Slow` : token, groupes, facteur, secondes restantes), `_physics_process`, `apply_slow`, `clear_slow`, `reset_slows`, tests.
- [x] `Loadout.active`, `Loadout.set_active()` qui renvoie l'ancien ; `OwnedItem.charge` / `charge_max` ; `Offer.charge` ; `BuildCarrier` recharge sur `room_cleared`.
- [x] `items/effects/broken_alarm_effect.gd` : `activate(player) -> bool` (dépense, ralenti, vide la charge).
- [x] `Player._try_use_active()`, action `use_active` dans `project.godot` (E et bouton X = 2), `ui/hud/hud.gd` : `active_item_changed`, barre de charge dans `HudSlot` (`set_charge`).
- [x] `strings.csv` (nom, bonus, coût), pools (5.2), tests.

## État du code concerné

- `GameClock` : `paused`, `global_multiplier` (borné à [0, 1]), `_scales` (toujours 1.0 aujourd'hui, personne ne les écrit) ; ne fait rien au tick. Les entités lisent `scale(group)` à chaque tick ; `BulletManager` lit le groupe de son camp (`PLAYER_BULLETS` / `ENEMY_BULLETS`), `Health` celui du joueur, `Room` ses renforts et les ennemis avec `ENEMIES`.
- `Lucidity.try_spend(cost, power)` refuse si `value < cost` (donc exactement 15 est accepté), émet `spent` qui devient `Events.lucidity_spent` (télémétrie).
- `Player._try_awakening()` : modèle d'un pouvoir dépensé avec refus sonore.
- 5.3 : `HudSlot.set_content`, armement de pickup déposé ; 5.1 : `Offer`, `Loadout`.
- `Main` redémarre le `Run` (mort, relance) : l'autoload `GameClock` survit, d'où le besoin de remise à zéro.

## Pièges

- **Un ralenti qui reste collé** (`GameClock` est un autoload) : remise à zéro sur `run_started` et `run_ended`, et `token` libérés (utiliser un `RefCounted` comme jeton, pas le nœud joueur).
- Le ralenti n'agit que sur les entités qui lisent `GameClock.scale()` : vérifier avec un ennemi tireur et une balle ennemie en vol (test d'intégration) que leur déplacement par tick est divisé par deux, et que le joueur ne l'est pas.
- `Timer` interdit (règle du projet) : la durée est comptée dans `GameClock._physics_process` sur le delta réel, gelée en pause (`paused`).
- Une charge qui augmente pendant le ralenti (vider une salle) fonctionne : `room_cleared` ne dépend pas de l'échelle.
- Le joueur en train de mourir : `_try_use_active` ne fait rien si `health.is_dead()` (comme `_try_awakening`).
- Téléportation du Glissement ou fondu de salle pendant le ralenti : le ralenti reste (les durées sont dans `GameClock`, indépendantes de la salle) ; c'est voulu.
- Ne pas modifier `GameClock.global_multiplier` pour ce ralenti (débogage F4).

## Tests

- `unit/autoloads/test_game_clock_slow.gd` : facteur 0,5 sur 3 groupes seulement, durée 4 s en ticks, retour à 1, gel en pause, deux ralentis se multiplient, `reset_slows`.
- `unit/items/test_active_item.gd` : charge, recharge sur 3 `room_cleared`, plafond, dépôt avec charge, refus sous 15 sans rien consommer (la charge reste), succès à exactement 15.
- `integration/items/test_broken_alarm.gd` : joueur avec l'objet, `use_active` simulé, lucidité −15, ennemi et balle ennemie ralentis, joueur et tirs du joueur non ralentis, tout revient à 1 après 4 s ; relance du `Run` pendant un ralenti : échelle à 1.

## Sources

epics.md (Story 5.8) ; GDD « Objet actif » (un seul, dépôt avec charge, règle de dépense) et ligne du Réveil cassé ; architecture AR13.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **ÉCART AU GDD / À L'EPIC** : « tout sauf le joueur » est lu comme ENEMIES, ENEMY_BULLETS et WORLD seulement ; **PLAYER_BULLETS et FX ne sont pas ralentis** (les tirs du joueur sont à lui ; un FX ralenti brouille le retour visuel). À valider à la main.
2. **La durée du ralenti est comptée en temps réel** (delta du tick × `global_multiplier`), pas dans le temps ralenti d'un groupe.
3. **API `apply_slow(token, ...)`** : le jeton permet de relancer sans empiler ; plusieurs sources se multiplient.
4. **Objet actif neuf = chargé** à la prise ; un objet déposé garde sa charge, un objet repris la retrouve.
5. **Touches** : E / X, `use_active` ; F1 `U` recharge.
6. **Barre de charge à segments** dans l'emplacement (graphisme final à l'epic 7).
7. **Écart à la lettre des tâches** : la dépense de lucidité, le test de charge et le vidage de la charge sont faits par `BuildCarrier.use_active()` (générique, réutilisable par les futurs actifs) ; `BrokenAlarmEffect.activate(player)` ne fait que le ralenti, le son et l'anneau (la signature de la base devient `activate(player: Player)`, sans valeur de retour : les refus sont décidés avant). Un `lucidity_cost` de 0 ne dépense rien.
8. **Objet actif aussi dans `Loadout.items()`** : ses tags (« time ») et son effet comptent comme ceux des autres objets ; `Loadout.active` le désigne. Remplacer retire l'ancien (effet détaché) et ajoute le nouveau.
9. **Jeton du ralenti = l'instance de l'effet** (un `RefCounted` propre à l'exemplaire). Un objet lâché pendant le ralenti ne l'annule pas (il s'éteint seul ou à `run_started` / `run_ended`).
10. **Pas de ligne dans l'aide des touches** (`controls_tutorial`) : hors périmètre de la story. Objet ajouté aux deux pools (trésor et boutique, test existant qui exige le catalogue entier).
11. **Son** `sfx_broken_alarm.wav` : provisoire, généré par script (epic 7). Anneau : `Room.add_ring` (public, rayon 6 tuiles, groupe FX donc non ralenti).

## Dev Agent Record

### Notes de complétion

- `GameClock` : `Slow`, `apply_slow` / `clear_slow` / `reset_slows` / `slow_count`, `_scales` recalculé à chaque changement (le produit des ralentis), durée décomptée dans `_physics_process` (delta × `global_multiplier`, gelée en pause) ; `reset_slows` sur `run_started` et `run_ended`.
- `OwnedItem.charge/charge_max`, `Loadout.active/set_active/add_charge/set_charge/active_changed`, `RoomStock.Offer.charge` (-1 = neuf), `BuildCarrier.use_active` + recharge sur `room_cleared` + relais `Events.active_item_changed`, `Pickup.active_replaced` → `Room._on_active_replaced` (dépose l'ancien, non armé, avec sa charge ; achat en boutique inclus).
- `Player._update_active_input` (action `use_active`, E / bouton X = 2, libres vérifiés dans `project.godot` et `debug_panel.gd`), refus sonore. HUD : `ActiveItemSlot` icône + barre de segments (`HudSlot.set_charge`), vidé à `run_started`. F1 : `I` donne l'objet (catalogue), `U` le recharge.
- Chaînes `ITEM_BROKEN_ALARM_{NAME,BONUS,COST}` ; `data/items/broken_alarm.tres` dans les deux pools.
- Checks : GUT 571/571 (`unit/autoloads/test_game_clock_slow`, `unit/items/test_active_item`, `integration/items/test_broken_alarm`) ; `run_all.sh` et `--quit-after 120` : voir le rapport.

### Liste des fichiers

`autoloads/{game_clock,events}.gd`, `items/{loadout,owned_item,item_effect,build_carrier,pickup}.gd`, `items/effects/broken_alarm_effect.gd`, `economy/room_stock.gd`, `rooms/room.gd`, `player/player.gd`, `ui/hud/{hud,hud_slot}.gd`, `debug/debug_panel.gd`, `project.godot`, `data/items/broken_alarm.tres`, `data/pools/{treasure,shop}_pool.tres`, `localization/strings.csv`, `audio/sfx/sfx_broken_alarm.wav`, tests GUT listés ci-dessus.

### Non évalué (humain)

- Ressenti du ralenti à 50 % pendant 4 s (lisibilité, coût de 15, recharge en 3 salles), son et anneau provisoires, barre de charge du HUD, manette X non testée.
