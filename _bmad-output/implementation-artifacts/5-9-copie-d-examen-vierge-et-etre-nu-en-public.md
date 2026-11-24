# Story 5.9 : Copie d'examen vierge et Être nu en public

Status: done

## Story

En tant que joueur,
je veux des objets qui changent le rythme des salles,
afin de prendre des risques calculés.

Exigences : FR50, FR53 (epics.md, Story 5.9). Architecture : `DangerProfile` (état de danger de la salle, 3.6), `ItemEffect` sur les signaux du porteur.

**Dépend de : 5.1** (`BuildCarrier`, effets), **5.4** (`Loot.roll(..., extra_drops)`, armure ramassable), **5.5** (boutique : article armure). Prépare 5.10 (réutilise `room_fight_started`). Bannière et pools : 5.1, 5.2.

Hors périmètre : la salle du cauchemar (epic 6) ; le chrono n'y tourne pas, mais la salle n'existe pas encore : la règle est posée sur `Room.is_nightmare()`.

## Critères d'acceptation

### Copie d'examen vierge (`data/items/blank_exam.tres`, tag Temps, `effect_script = BlankExamEffect`)

1. **Signaux nécessaires** (posés ici, réutilisés par 5.10) : `Player.enter_room(room)` fait émettre au carrier `room_entered(room)` ; la salle émet `fight_started` (une seule fois, au premier `begin_room()` qui prépare une vague non vide) que le joueur relaie par `BuildCarrier.room_fight_started(room)`. Les deux sont débranchés dans `leave_room`.
2. **Chrono** : en entrant dans une salle de combat **non vidée** (`room.room_type == COMBAT`, `not room.is_cleared()`, `room.has_fight()`), un chrono de 45 s (`params.seconds`) s'affiche (`Events.exam_timer_changed(seconds_left: float)`, −1 = masqué ; texte `UI_EXAM_TIMER` dans la bande du HUD) et défile avec `GameClock.scale(PLAYER)`. Il ne tourne ni dans une salle déjà vidée, ni dans la salle du cauchemar (`is_nightmare()`), ni dans le départ, le trésor, la boutique. Il s'arrête et se masque à `room_cleared`, à la sortie de la salle, à la mort.
3. **Le chrono atteint 0** : les ennemis restants **se déplacent et tirent 30 % plus vite** (`params.pace_bonus` = 0,3), y compris ceux qui ne tirent pas (Somnambule, Mouton). Mécanisme : `DangerProfile.pace_mult` (1,0 par défaut, jamais touché par `apply_tier`) fixé par `Room.set_pace_mult(1.3)` ; les ennemis le lisent pour leur vitesse (`Enemy._move_in_direction`) et leur cycle de tir (`ShooterEnemy._tick_cycle` avance de `clock_scale × pace_mult`). Les télégraphes ne raccourcissent pas (minimum 0,4 s respecté). Les renforts qui arrivent ensuite en profitent. Ni les balles en vol, ni le joueur ne changent de vitesse.
4. **Drop garanti** : à `room_cleared` d'une salle de combat, `Loot.roll(..., extra_drops = 1)` : un drop de plus, type tiré dans le même flux `drops` **après** la séquence normale (la séquence normale n'est pas décalée), sans jet de chance. Les deux drops apparaissent côte à côte (cellules libres voisines). Le nombre `extra_drops` vient de `Loadout.sum_param(&"guaranteed_drops")` (1 par Copie, l'objet n'est pas cumulable).

### Être nu en public (`data/items/naked_in_public.tres`, tags Regard et Corps, `effect_script = NakedEffect`)

5. **À la prise** : toute l'armure est perdue (`Health.clear_armor()`, émet `changed`) ; ensuite le joueur ne peut plus en gagner : `Health.armor_blocked = true` (posé par l'effet, retiré à `detach`), `add_armor` renvoie `false`. Les ½ armures du sol restent au sol (cas « refusé » de 5.4), l'armure de la boutique est refusée au contact.
6. **La gêne** : pendant 1,5 s (`params.hold_seconds`) à partir de `room_fight_started` de chaque salle, les ennemis **ne tirent pas** : `DangerProfile.fire_hold` vrai, `ShooterEnemy._tick_cycle` n'avance pas pendant ce temps (son premier tir est donc retardé de 1,5 s) ; la durée se compte en ticks du groupe `ENEMIES`. Les ennemis qui apparaissent plus tard (renforts) pendant cette fenêtre en profitent aussi.
7. **Boutique** : si le joueur porte l'objet (`Loadout.has_flag(&"blocks_armor")` lu depuis `params`), `ShopStock.draw` remplace l'armure par un **second cœur** au prix d'un cœur (`heart_price`). Test sur l'étal tiré (cas du joueur qui prend l'objet après avoir déjà vu la boutique : l'étal mémorisé est corrigé à l'entrée suivante, voir pièges).
8. **Objets** ajoutés aux pools trésor et boutique ; clés `strings.csv` des deux objets.

## Tâches

- [x] `Room.fight_started`, `Room.set_pace_mult()`, `Room.set_fire_hold(ticks)` ; `DangerProfile.pace_mult`, `fire_hold` (hors `apply_tier`).
- [x] `Enemy` / `ShooterEnemy` / tous les déplacements (`Enemy._move_in_direction`, charge du Mouton si elle a sa propre vitesse) : lire `danger.pace_mult` ; inventorier chaque ennemi à la main (`enemies/*`) avant de conclure.
- [x] `BuildCarrier.room_entered`, `room_fight_started` ; `Player.enter_room/leave_room` les câblent.
- [x] `items/effects/blank_exam_effect.gd`, `naked_effect.gd`, `data/items/*.tres`, `Health.clear_armor()` / `armor_blocked`, `Loadout.sum_param`, `has_flag`.
- [x] `Run` : passe `extra_drops` au loot ; `ShopStock` : variante sans armure.
- [x] HUD : chrono (`Hud` écoute `exam_timer_changed`), `strings.csv`.
- [x] Tests.

## État du code concerné

- `DangerProfile` : `enemy_bullet_speed_mult`, `telegraph_mult`, `reinforcement`, `boss_extra_pattern` ; muté en place par `Room.begin_room` / `_on_room_danger_raised` ; les ennemis le lisent à chaque tir ou télégraphe.
- `Enemy` : `_move_in_direction(direction, speed_px, clock_scale)` ; `ShooterEnemy._tick_cycle(clock_scale)` décrémente `_cycle_ticks_left`. `Telegraph` a son minimum de `Tuning.COMBAT.min_telegraph`.
- `Room.begin_room(wave_defs)` est appelé par le `WaveRunner` au début de chaque vague ; `start_delay` de la première vague : `Tuning.ROOM.first_wave_delay` (1 s).
- `Player.enter_room(room)` est appelé par `Room._ready()` ; `Run` fournit `RoomOptions.already_cleared`.
- `Health.add_armor` plafonne aux cœurs max ; pas de moyen de vider l'armure ; `ShopStock` (5.5) tire l'étal.
- 5.4 : `Loot.roll(..., extra_drops)` déjà prévu, sans effet jusqu'ici.

## Pièges

- **Les 1,5 s** : la salle entre, la première vague apparaît après 1 s (`first_wave_delay`) : une fenêtre comptée depuis l'**entrée** ne protégerait presque rien. Elle est donc comptée depuis `fight_started` (voir décisions).
- `room_cleared` pendant que `Enemies` est verrouillé : le drop garanti passe par `Drops.spawn` différé (5.4), pas de `spawn_enemy`.
- Mutation de `DangerProfile.pace_mult` : `Room._on_room_danger_raised` ne doit pas le réinitialiser ; remettre à 1,0 à `end_room` et à chaque nouvelle salle (une salle = un `DangerProfile`).
- Le chrono vit sur le carrier (effet), pas dans la salle : il doit se couper si le joueur quitte la salle (`leave_room`) ou meurt, et ne pas redémarrer en sortant d'un fondu (4.8) dans une salle vidée.
- Le Mouton qui charge a-t-il une vitesse propre hors `_move_in_direction` ? À vérifier ; sinon l'ennemi se déplace à vitesse normale en charge, ce que le test d'intégration (distance parcourue par tick) détecte.
- Boutique déjà tirée avant la prise de l'objet : l'étal mémorisé contient l'armure ; remplacer l'offre armure non prise par un cœur à l'entrée suivante (méthode `RoomStock.apply_flags`), sinon l'armure est de toute façon refusée (« impossible à prendre », 5.5).
- `Health.clear_armor()` : émet `changed` mais **pas** `player_hit` (ce n'est pas un coup).

## Tests

- `unit/items/test_blank_exam_effect.gd` : chrono 45 s en ticks, pas de chrono salle vidée / cauchemar / départ, arrêt à `room_cleared`, `pace_mult` 1,3 à 0, `Loot.roll` avec un drop de plus sans décaler la séquence normale.
- `unit/items/test_naked_effect.gd` : armure à 0 à la prise, `add_armor` refusé, `armor_blocked` retiré à `detach`, `fire_hold` 90 ticks.
- `unit/economy/test_shop_stock.gd` (étendre) : sans armure, 2 cœurs au prix du cœur.
- `integration/items/test_pace_and_hold.gd` : tireur et Somnambule à 130 % de vitesse après le chrono ; sous Être nu en public, aucun tir avant 1,5 s après `fight_started`, un tir ensuite.

## Sources

epics.md (Story 5.9) ; GDD lignes Copie d'examen vierge et Être nu en public, notes de design ; architecture D9.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **ÉCART AU GDD (lecture)** : « 1,5 premières secondes de chaque salle » est compté depuis l'**apparition de la première vague** (`fight_started`), pas depuis l'entrée du joueur, sinon la première vague (1 s après l'entrée) n'aurait que 0,5 s de gêne.
2. **Les ennemis ne tirent pas = leur cycle de tir ne progresse pas** : le premier tir arrive 1,5 s plus tard que sans l'objet, plutôt qu'un tir avorté (pas de télégraphe vide).
3. **« Plus vite » = vitesse de déplacement et vitesse du cycle de tir × 1,3**, télégraphes et balles en vol inchangés.
4. **Chrono et gêne en temps du groupe visé** : chrono sur `PLAYER`, gêne sur `ENEMIES` (le Réveil cassé ralentit la gêne, c'est voulu).
5. **Armure vidée à la prise sans événement de coup** ; l'armure déjà au sol et celle de la boutique sont simplement refusées.
6. **Boutique : le cœur remplaçant l'armure coûte le prix d'un cœur** (4), pas celui de l'armure.

### Décisions prises sans Kroustille (suite, dev)

7. **`room_entered` est émis en fin de `Room._ready()` (via `Player.room_ready(room)`), pas dans `Player.enter_room`** : `enter_room` est appelé au milieu de `_ready`, avant que la salle sache si elle a un combat (`has_fight()`) ou si elle est vidée (`is_cleared()`). `enter_room` branche seulement `fight_started` ; l'effet lit les deux états au bon moment. Même signal côté carrier, 5.10 peut le réutiliser.
8. **Flux `drops` à nombre de tirages fixe** (item différé 5.9) : 6 tirages par salle quoi qu'il arrive (forme, chance, type, consommable, puis un emplacement garanti de type + consommable toujours payé), `Loot.EXTRA_SLOTS = 1`, le surplus demandé est coupé. Les graines existantes changent de séquence de drops une fois (nouveau découpage), pas de sauvegarde concernée.
9. **Deux drops côte à côte** : `Room._free_spot` écarte maintenant toute offre qui tombe dans la cellule d'une offre déjà posée (cellule libre la plus proche). Vaut aussi pour les consommables lâchés par le joueur.
10. **Le Mouton et le Somnambule ne gagnent que la vitesse de déplacement** : leurs minuteurs (repos, charge, ruée) restent ceux de la définition, la distance de ruée augmente donc de 30 %. Le cycle de tir n'existe que chez les tireurs.
11. **Boutique** : seul l'étal d'armure payant est remplacé (`RoomStock.apply_no_armor`) ; le second cœur occupe l'emplacement ARMOR (aucun emplacement cœur libre). Tags de l'objet : `gaze` (Regard) et `body` (Corps).
12. **Pas de signal au passage à zéro** (ni son ni anneau) : hors périmètre, à l'epic 7.
13. **Commit croisé** : le fixer de 5.8 a commité par erreur mes hunks de `build_carrier.gd` (signaux `room_entered`, `room_fight_started`), `hud.gd` (étiquette du chrono) et `strings.csv` (clés 5.9) dans `94a020a` : ils étaient dans le même arbre.

### Décisions prises sans Kroustille (suite, revue)

14. **Revue — décision 10 maintenue (ruée du Somnambule +30 % de distance)** : le GDD dit « se déplacent 30 % plus vite » ; le télégraphe ne change pas et la ruée reste droite, donc l'esquive latérale marche toujours. C'est la pénalité voulue de l'objet, ressenti NON ÉVALUÉ (déjà dans `deferred-work.md`).
15. **Revue — changement unique des drops des graines existantes accepté** (décision 8) : pas de sauvegarde, avant le playtest du jalon A ; le flux reste par étage et son nombre de tirages ne dépend plus ni de l'issue ni des objets portés.

### Review Findings

Revue de code (2026-11-24, Opus, trois couches en passes isolées : Blind Hunter, Edge Case Hunter, Acceptance Auditor) sur `9e6edb7..1c8408d` plus les hunks 5.9 de `94a020a` (`build_carrier.gd`, `hud.gd`, `strings.csv`). GUT `integration/items/` 65/65 sur un arbre propre à `1c8408d`. Vérifiés sans défaut : `room_entered` en fin de `Room._ready` (seul `BlankExamEffect` l'écoute ; `Events.room_entered` de `Run` inchangé, une émission par instance de salle), `fight_started` une fois au premier `begin_room` après `first_wave_delay`, gêne en ticks `ENEMIES` (Réveil cassé compris), `pace_mult` / `fire_hold` hors `apply_tier`, remis à `end_room`, tous les déplacements ennemis passent par `_move_in_direction`, chrono coupé à `room_cleared` / mort / détachement (le HUD persistant reçoit −1 au démontage du run), `Loot.roll` à tirages fixes, `_free_spot` (l'offre prise est marquée avant l'émission du remplacement), boutique sans armure.

- [x] [Review][Patch] Bonus d'Être nu en public tronqué à « Les ennemis ne tirent pas pendant 1 » [`game/localization/strings.csv:84`] — la virgule de « 1,5 s » coupe le champ CSV (vérifié avec `tr()`) : mettre la valeur entre guillemets, `ITEM_NAKED_IN_PUBLIC_BONUS,"Les ennemis ne tirent pas pendant 1,5 s au début de chaque salle"`.
- [x] [Review][Patch] Variable morte et commentaire confus [`game/items/effects/blank_exam_effect.gd:10`, `:50`, `:72`, `game/economy/shop_stock.gd:9`] — supprimer `_expired` (écrit, jamais lu) ; réécrire le commentaire de `ShopStock.draw` : « item, item, consumable, heart, armor (a second heart when blocks_armor); an item or the consumable is missing when nothing is left to offer », coupé sous 120 colonnes.
- [x] [Review][Defer] Étiquette du chrono : « Copie d'examen : 45 s » mesure 131 px pour 130 px de large ; alignée à droite, elle commence à x = 104 et chevauche la 12e icône de la rangée de cœurs (x 105–113). Voir `deferred-work.md`.
- [x] [Review][Defer] Copie d'examen + Être nu en public : le drop garanti peut être une ½ armure, toujours refusée. Voir `deferred-work.md`.
- [x] [Review][Defer] Arène en boucle : le chrono s'arrête au premier `room_cleared` de vague, le rythme ×1,3 posé avant reste jusqu'à la fin (pas d'`end_room`). Voir `deferred-work.md`.

Correctifs de revue appliqués et vérifiés : bonus entre guillemets (`tr()` rend « 1,5 s », test GUT ajouté) et nettoyages (`_expired`, commentaire de `ShopStock.draw`).

## Dev Agent Record

### Notes de complétion

- `DangerProfile.pace_mult` / `fire_hold` hors `apply_tier` ; `Room.fight_started`, `set_pace_mult`, `set_fire_hold` (compté en ticks du groupe ENEMIES), remise à zéro à `end_room`. `Enemy._move_in_direction` / `_presses_target` et `ShooterEnemy._tick_cycle` lisent le profil ; télégraphes et balles en vol inchangés.
- `BlankExamEffect` (chrono sur le carrier, ticks du groupe PLAYER, arrêt à `room_cleared`, sortie de salle, mort) et `NakedEffect` ; `Health.clear_armor` / `armor_blocked` ; `Loadout.sum_param` / `has_flag` ; `Events.exam_timer_changed` ; HUD `ExamLabel`.
- `Loot` à tirages fixes (voir décision 8), `Run` passe `guaranteed_drops` ; `ShopStock.draw(..., blocks_armor)` et `RoomStock.apply_no_armor` ; deux items dans les deux pools ; chaînes `ITEM_BLANK_EXAM_*`, `ITEM_NAKED_IN_PUBLIC_*`, `UI_EXAM_TIMER`.
- Checks : `tools/run_tests.sh` 604/604 vert (dont `unit/items/test_naked_effect`, `integration/items/test_blank_exam`, `integration/items/test_pace_and_hold`, extensions de `test_loot`, `test_shop_stock`, `test_loadout`, `test_loot_flow`) ; `run_all.sh` ALL PASS ; `--quit-after 120` propre.

### Liste des fichiers

`combat/{danger_profile,health}.gd`, `enemies/{enemy,shooter_enemy}.gd`, `rooms/room.gd`, `player/player.gd`, `items/{loadout,build_carrier}.gd`, `items/effects/{blank_exam,naked}_effect.gd`, `data/items/{blank_exam,naked_in_public}.tres`, `data/pools/*.tres`, `economy/{loot,shop_stock,room_stock}.gd`, `run/run.gd`, `autoloads/events.gd`, `ui/hud/hud.gd`, `localization/strings.csv`, tests GUT associés.

### Non évalué (humain)

- Voir `deferred-work.md` (story 5.9).

### Change Log

- 2026-11-24 : implémentation de 5.9, statut review.
- 2026-11-24 : revue de code, 2 patchs, 3 reports, statut in-progress.
