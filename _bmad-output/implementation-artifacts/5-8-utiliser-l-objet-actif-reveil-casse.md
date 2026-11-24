# Story 5.8 : Utiliser l'objet actif : Réveil cassé

Status: ready-for-dev

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

- [ ] `GameClock` : `_slows` (liste de `Slow` : token, groupes, facteur, secondes restantes), `_physics_process`, `apply_slow`, `clear_slow`, `reset_slows`, tests.
- [ ] `Loadout.active`, `Loadout.set_active()` qui renvoie l'ancien ; `OwnedItem.charge` / `charge_max` ; `Offer.charge` ; `BuildCarrier` recharge sur `room_cleared`.
- [ ] `items/effects/broken_alarm_effect.gd` : `activate(player) -> bool` (dépense, ralenti, vide la charge).
- [ ] `Player._try_use_active()`, action `use_active` dans `project.godot` (E et bouton X = 2), `ui/hud/hud.gd` : `active_item_changed`, barre de charge dans `HudSlot` (`set_charge`).
- [ ] `strings.csv` (nom, bonus, coût), pools (5.2), tests.

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
