# Story 5.9 : Copie d'examen vierge et Être nu en public

Status: ready-for-dev

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

- [ ] `Room.fight_started`, `Room.set_pace_mult()`, `Room.set_fire_hold(ticks)` ; `DangerProfile.pace_mult`, `fire_hold` (hors `apply_tier`).
- [ ] `Enemy` / `ShooterEnemy` / tous les déplacements (`Enemy._move_in_direction`, charge du Mouton si elle a sa propre vitesse) : lire `danger.pace_mult` ; inventorier chaque ennemi à la main (`enemies/*`) avant de conclure.
- [ ] `BuildCarrier.room_entered`, `room_fight_started` ; `Player.enter_room/leave_room` les câblent.
- [ ] `items/effects/blank_exam_effect.gd`, `naked_effect.gd`, `data/items/*.tres`, `Health.clear_armor()` / `armor_blocked`, `Loadout.sum_param`, `has_flag`.
- [ ] `Run` : passe `extra_drops` au loot ; `ShopStock` : variante sans armure.
- [ ] HUD : chrono (`Hud` écoute `exam_timer_changed`), `strings.csv`.
- [ ] Tests.

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
