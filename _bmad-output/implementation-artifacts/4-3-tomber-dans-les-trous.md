# Story 4.3 : Tomber dans les trous

Status: done

## Story

En tant que joueur,
je veux que les trous du rêve me fassent chuter si je m'y laisse aller,
afin de sentir les sursauts hypnagogiques de l'Endormissement.

Exigences : FR4 (trous), FR24 (trou comme destination), FR40, AR29 (trous) (epics.md, Story 4.3). Architecture : « Trous » et « Glissement » des compléments, `DamageInfo` source `PIT`.

**Dépend de : 4.2** (couche `Pits`, `Room`, `RoomValidator`, outil de construction) et **4.1** (tests).

Hors périmètre : Ailes de papier et Chute sans fin (epic 5, qui poseront les modificateurs ; ici seulement la stat), chute des ennemis (les ennemis ne tombent pas, voir décisions), art définitif des trous.

## Critères d'acceptation

1. **Dernière position sûre** : à chaque tick de marche (hors dash en cours), le joueur mémorise sa position si elle est sur une cellule de sol : cellule de `Floor` présente et cellule de `Pits` vide. Classe pure `PitGuard` (`player/pit_guard.gd`, `RefCounted`) : `observe(position, is_safe)`, `last_safe`, `should_fall(position, is_pit)`.
2. **Chute à la marche** : quand le centre du corps du joueur entre dans une cellule de `Pits`, il chute : coup de source `DamageInfo.Source.PIT = 4` (valeur ajoutée en fin d'enum), montant = stat `PIT_DAMAGE` du `StatBlock` (base : `Tuning.COMBAT.pit_damage_half_hearts` = 1, soit ½ cœur), invulnérabilité 1 s (celle du coup, `Health`), retour immédiat à `last_safe`, vélocité remise à zéro, `reset_physics_interpolation()`.
3. **Dash** : un dash qui commence avant un trou le survole si sa position **finale** est hors du trou (aucun test de cellule pendant le dash) ; si elle est dans le trou, le joueur chute à la fin du dash (`dash.ended`), au tick même.
4. **Glissement** : un Glissement dont la destination est dans un trou (destination valide, `Glide.resolve_destination` ne change pas) fait chuter à l'arrivée, dans le tick du Glissement : le coût en lucidité est payé et le recharge démarre ; l'invulnérabilité d'arrivée (0,1 s) ne s'arme pas si le joueur tombe (elle ne doit pas annuler le coup de chute).
5. **Stat `can_fly_over_pits`** : `StatBlock.Stat.CAN_FLY_OVER_PITS` (booléen porté par un flottant : actif si > 0, base 0) ; actif, aucune chute (marche, dash, Glissement) et la position sûre se met à jour partout. `StatBlock.Stat.PIT_DAMAGE` alimente le montant (les objets de l'epic 5 y branchent leurs modificateurs). Aucun objet ne les modifie encore.
6. **Invulnérable au moment de la chute** (coup précédent, dash, arrivée) : le joueur est tout de même renvoyé à la dernière position sûre, sans dégâts (le coup passe par `hurtbox.receive`, qui le refuse) : on ne campe jamais dans un trou.
7. **Mort par chute** : si ce coup est le dernier, `Events.player_hit(damage, PIT)` précède `run_ended` comme les autres sources, la cause de mort est « trou » (clé de localisation du télémétrie / écran de réveil si elle affiche la source ; sinon seulement le journal).
8. **Liaison salle/joueur** : `Player.enter_room(room: Room)` et `leave_room()` (nouveaux) donnent au joueur la source des trous (`room.is_pit_at(global_position)`, `room.is_floor_at(...)`) ; `Room._ready` l'appelle. La 4.8 y rattachera les `BulletManager` (`equip_bullets`) ; ici rien d'autre n'y est déplacé.
9. **Le Mouton ne charge pas sans fin** (deferred-work 2.5) : `SheepDef.max_charge_distance` (tuiles, dans `sheep.tres`, valeur supérieure à la diagonale d'une salle d'un écran) ; au-delà, la charge s'arrête sans étourdissement, retour au repos, une ligne `Log.debug("combat", "sheep_1 charge exhausted ...")`.
10. **Le Somnambule ne pousse plus le joueur immobile** (deferred-work 2.3, ressenti NON ÉVALUÉ) : pendant l'accélération, au contact du joueur, le Somnambule ne force pas le déplacement du joueur (écart du joueur inférieur à 1 px par accélération en test) ; la poussée au bord d'un trou ne doit pas faire chuter un joueur qui ne bouge pas.
11. **Salle de test** `onset_combat_004` : trous en îlots et en couloir au centre, 1 vague ; le validateur (4.2) refuse un `EnemySpawn` ou un `ReinforcementSpawn` sur un trou, et une salle dont une porte ou un spawn est coupé du reste du sol par des trous (flood fill sur `Floor` sans `Pits` ni murs ni obstacles hauts depuis la porte : tout `EnemySpawn` et toutes les autres portes doivent être atteints).

## Tâches

- [x] `DamageInfo.Source.PIT`, `CombatTuning.pit_damage_half_hearts`, `StatBlock.Stat.PIT_DAMAGE` et `CAN_FLY_OVER_PITS` (`Player._setup_stats` donne les bases), `Events` inchangé (le coup passe par `player_hit`).
- [x] `PitGuard` pur ; `Room.is_pit_at(global_pos)`, `Room.is_floor_at(global_pos)` (lecture de cellule par `local_to_map`) ; `Player` : appel après `move_and_slide()` (marche), à `_on_dash_ended`, dans `_try_glide` après le déplacement.
- [x] Fonction de chute unique `Player._fall(position)` (dégâts, repositionnement, invulnérabilité), jamais un second chemin.
- [x] Mouton (`max_charge_distance`), Somnambule (pas de poussée), `onset_combat_004` via l'outil ASCII, `RoomValidator` (cellules interdites, accessibilité).
- [x] Tests `tests/unit/player/test_pit_guard.gd`, `tests/integration/player/test_pit_fall.gd` (marche, dash au-dessus, dash qui finit dedans, Glissement dedans, stat active, invulnérable), `tests/unit/rooms/test_room_validator.gd` (nouvelles règles) ; `.scratch` : `run_all.sh` une fois.

### Review Findings

Revue de code 2026-11-24 (Opus, trois couches : Blind Hunter, Edge Case Hunter, Acceptance Auditor), sur `cf6a433..b94e7fc`. Lignes = HEAD `b94e7fc`. 6 correctifs, 6 reports, 2 décisions, 10 rejets. Conformes : chute à la marche et en fin de dash, Glissement (coût, recharge, pas d'invulnérabilité d'arrivée), invulnérable renvoyé sans dégâts, mort `player_hit(PIT)` avant `run_ended` et cause télémétrie `pit` (l'écran de réveil n'affiche pas la source), montant < 1 sans coup, Mouton (repos sans étourdissement, `0` = sans limite, distance réelle en px remise à zéro à chaque charge), Somnambule (le contact blesse toujours : `contact_size` 0,875 > `body_size` 0,625 ; il n'est pas bloqué, CHASE → TELEGRAPH → RUSH → CHASE), l'Éveil ne pousse que les ennemis. Les renforts `reinforce 36 …` hors grille et l'apparition du joueur dans le couloir de trous de `onset_combat_004` (à `b94e7fc`, la case du centre était un trou) sont corrigés par le correctif de la 4.2 (`4541cc6`) ; `room.gd` et le validateur ont bougé depuis : lignes `HEAD 23f9cd5` indiquées quand elles diffèrent.

- [x] [Review][Patch] **La chute ne remet pas l'élan à zéro** [`game/player/player.gd:301`, `:206`] : `velocity = Vector2.ZERO` est réécrit au tick suivant depuis `PlayerMotor.velocity`, qui garde sa vitesse ; touche maintenue, le joueur repart à pleine vitesse depuis `last_safe` (8 px du bord) et retombe (coup refusé, tremblement visible). Au Glissement c'est pire : `_fall()` passe dans `_update_powers()` avant `velocity = motor_velocity * clock_scale` et `move_and_slide()` du même tick. Ajouter `PlayerMotor.reset()` (`velocity = Vector2.ZERO`), l'appeler dans `_fall()`, et à la ligne 206 écrire `velocity = _motor.velocity * clock_scale` (au lieu de la variable locale lue avant les pouvoirs). Test : après une chute touche maintenue, `_motor.velocity == Vector2.ZERO` au tick de la chute.
- [x] [Review][Patch] **En vol, une cellule de trou devient la position sûre** [`game/player/player.gd:290`] : avec `CAN_FLY_OVER_PITS`, `last_safe` peut être le centre d'un trou ; si le vol cesse au-dessus d'un trou (objet de l'epic 5), le joueur est renvoyé dans le trou à chaque tick, un demi-cœur par seconde jusqu'à la mort. `var safe: bool = on_floor and not _room.is_pit_at(global_position)` (le vol ne fait que supprimer la chute, dans `_is_over_pit`). Compléter `test_flying_over_pits_never_falls` : après la traversée, `_room.is_pit_at(_player._pit_guard.last_safe)` est faux. Décision R1.
- [x] [Review][Patch] **Aucune chute tant qu'aucune cellule sûre n'est vue** [`game/player/player.gd:179-181`] : `enter_room` recrée le `PitGuard` vide et `should_fall` exige `_has_safe` ; un joueur dont le premier tick finit sur un trou traverse les trous librement jusqu'au premier sol (et un Glissement dans un trou à ce moment garde l'invulnérabilité d'arrivée). Dans `enter_room`, après `PitGuard.new()` : `var spawn: Vector2 = room.player_spawn_position()` puis `_pit_guard.observe(room.cell_center_at(spawn), room.is_floor_at(spawn) and not room.is_pit_at(spawn))` (`Run` place le joueur à cette position juste après ; la 4.8 y passera la case d'entrée de la porte).
- [x] [Review][Patch] **Le joueur naît au bord exact du couloir de trous** [`art_source/rooms/onset_combat_004.txt`, `game/rooms/pool/onset/onset_combat_004.tscn`] : après `4541cc6` (couloir déplacé sur les colonnes 14..17 du texte, tuiles 15..18), l'apparition (304, 168) = x 19,0 tuiles tombe sur la frontière exacte entre le trou de la tuile 18 et le sol de la tuile 19 ; 1 px à gauche au premier tick suffit à tomber (ou à traverser, finding précédent). Éloigner le couloir d'au moins deux tuiles du centre, par exemple couloir sur les colonnes 11..14 du texte (tuiles 12..15) et l'îlot `PP` des colonnes 10-11 (lignes 8-9) déplacé en 7-8 ; reconstruire avec `tools/build_room.sh`. Décision R2.
- [x] [Review][Patch] **`leave_room()` ne vérifie pas quelle salle part** [`game/player/player.gd:185-186`, `game/rooms/room.gd:266` (HEAD)] : une salle qui sort de l'arbre après le `_ready` de la suivante (4.8) coupe les trous de la nouvelle. `func leave_room(room: Room) -> void: if _room == room: _room = null`, appelé `_player.leave_room(self)`.
- [x] [Review][Patch] **Accessibilité : la case du joueur et les renforts ne sont pas exigés** [`game/rooms/validator/room_validator.gd:214-217` (HEAD)] : report de la revue 4.2 adressé à la 4.3 (« atteindre aussi les `ReinforcementSpawn` et la case du joueur ») ; le flood fill n'exige que les portes et les `EnemySpawn`. Après la boucle des `EnemySpawn`, même contrôle pour la cellule de `room.to_local(room.player_spawn_position())` (« player spawn is cut off from the doors ») et pour chaque `ReinforcementSpawn` (« … is cut off from the doors »), seulement si la cellule est `walkable` (sinon déjà signalée par `_check_marker_cell`, `4541cc6`). Fixture : une poche fermée par `P` autour d'un renfort.

Correctifs appliqués et vérifiés (2026-11-24) : 6 patchs (commits `024543b`, `e3a73b2`, `8e9ec1b`) ; `tools/run_tests.sh` 133/133, `tools/validate_rooms.sh` 5 salles valides, `run_all.sh` ALL PASS (1146 contrôles). Fixtures `pits_cut_door` et `furniture_cuts_door` ajustées pour ne signaler qu'un seul problème.

## État du code concerné

- `PlayerMotor` ne gère que la vitesse (RefCounted pur) : on **n'y met pas** la position sûre (écart avec l'architecture, qui la nomme) ; `PitGuard` la porte, testable seul.
- `Player._physics_process` : `move_and_slide()` puis `_dash.finish_tick()` ; le signal `dash_ended` part dans `finish_tick()` après le mouvement. `_try_glide()` pose `global_position = destination` puis arme `_arrival_ticks_left`. `Health` porte l'invulnérabilité du coup (`hit_invulnerability_duration` = 1 s).
- `Player._on_hurtbox_damage_received(info)` convertit un `DamageInfo` en coup et appelle `_die(source)` ; la source `int` voyage sur `Events.player_hit`.
- `Sheep.STUNNING_LAYERS = LAYER_WALLS` ; `Sheep._process_charge` ne sort que sur collision (ligne 130) : c'est là que la distance s'ajoute (compteur de distance parcourue en px).
- La 4.5 ajoutera les trous comme cellules bloquées d'`AStarGrid2D` (les ennemis les évitent mais ne tombent pas) ; la 4.8 déséquipera tout à la sortie de salle.

## Pièges

- Le test de cellule se fait dans le repère de la salle : `Pits.local_to_map(Pits.to_local(global_pos))`. La salle est à l'origine du monde aujourd'hui, mais pas la peine de s'y fier.
- Une chute pendant la tolérance de `move_and_slide()` (collision au bord) : tester la position **après** le mouvement du tick, pas la vitesse.
- Ne pas téléporter le joueur depuis un callback de physique (`body_entered`) : tout se fait dans `_physics_process`.
- `reset_physics_interpolation()` après le retour, sinon le sprite traverse l'écran ; la caméra de la 4.6 suit : même précaution.
- Position sûre « sur une cellule de sol » : le centre du joueur peut être sur une cellule de sol collée à un trou ; le retour ne doit pas replacer sur le bord exact : rester au centre de la cellule sûre mémorisée.
- Les dégâts viennent d'un `DamageInfo` normal (`hurtbox.receive`) : le filtre de `Hurtbox` (arrivée, dash) s'applique, c'est voulu (critère 6) ; la position est rendue même si refusé.

## Fichiers prévus

`player/pit_guard.gd`, `player/player.gd`, `combat/damage_info.gd`, `core/{stat_block,combat_tuning}.gd`, `data/tuning/combat_tuning.tres`, `rooms/room.gd`, `rooms/validator/room_validator.gd`, `enemies/sheep/{sheep,sheep_def}.gd`, `data/enemies/sheep.tres`, `enemies/sleepwalker/sleepwalker.gd`, `rooms/pool/onset/onset_combat_004.tscn`, `art_source/rooms/onset_combat_004.txt`, `tests/**`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Position testée = centre du corps** (pas un coin) : la chute se lit simplement, un bord de trou est un peu indulgent.
2. **Chute sans dégâts si invulnérable, mais retour quand même** : évite de camper dans un trou pendant l'invulnérabilité.
3. **`PitGuard` à la place de `PlayerMotor`** pour la position sûre (testabilité, `PlayerMotor` reste de la vitesse pure).
4. **Les ennemis ne tombent pas** : le GDD ne parle que du joueur. Ils évitent les trous par le chemin (4.5) mais le corps ne les voit pas physiquement.
5. **Chute au Glissement : pas d'invulnérabilité d'arrivée** : sinon le coup de chute serait refusé par la fenêtre de 0,1 s.
6. **Mouton : distance maximale de charge** (au lieu de « portes fermées en combat » seul) : filet de sécurité, indépendant de la 4.8.
7. **Poussée du Somnambule supprimée** (la décision 33 de la 2.3 est reprise ici) ; à juger au jeu avec Kroustille, NON ÉVALUÉ.
8. **Stat booléenne en flottant** (`CAN_FLY_OVER_PITS` > 0) : `StatBlock` ne connaît que des flottants.
9. **Accessibilité des salles vérifiée par le validateur** : un trou ne doit jamais isoler une porte ou un ennemi.

Décisions prises en développement :

10. **Flood fill : les obstacles bas bloquent aussi** (la spec ne citait que les hauts) : les corps du joueur et des ennemis les heurtent, une porte « accessible » derrière un obstacle bas ne l'est pas à pied. Voisinage à 4 cellules. Le test est sauté si la salle n'a pas la bonne taille (déjà signalé).
11. **`PitGuard.observe(position, is_safe)` reçoit le centre de la cellule** (calculé par `Room.cell_center_at`), pas la position du corps : le retour ne tombe jamais sur le bord (piège de la spec). `should_fall` exige une position sûre connue (sinon un joueur né dans un trou resterait coincé).
12. **Test de chute après `finish_tick()`** pour couvrir marche et fin de dash dans le même appel (`not _dash.is_active()`), au lieu d'un branchement dans `_on_dash_ended` ; même tick, mêmes résultats.
13. **Un coup de chute de montant < 1 demi-cœur (stat réduite à 0) repositionne sans coup** : `Health` refuse sous 0,5 avec une erreur.
14. **`max_charge_distance = 0` veut dire « sans limite »** (pas d'erreur) : les `SheepDef` construits sans valeur (scènes de contrôle) restent valides.
15. **Somnambule : `test_move()` avant d'avancer** ; s'il touche le joueur, il ne bouge pas (ni marche ni ruée) ; le contact (zone `Hitbox`) blesse toujours.
16. **Fixtures de test** : `pit_band` (bande de trous, salle de départ sans ennemi), `pits_cut_door`, `enemy_cut_off`, `reinforcement_on_pit` (sources `.txt` à côté des `.tscn`, construits par `tools/build_room.sh`).

Décisions de la revue de code :

R1. **En vol, la position sûre reste une cellule sans trou** : le critère 5 (« la position sûre se met à jour partout ») est lu comme « sur tout sol sûr traversé » ; sinon la fin du vol au-dessus d'un trou enferme le joueur dans une boucle de chutes (contraire au critère 6).
R2. **Couloir de `onset_combat_004` décalé du centre** : le critère 11 dit « au centre », mais le joueur paraît au centre de la salle jusqu'à la 4.8 ; deux tuiles de marge comptent plus que la position exacte du couloir.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Completion Notes

- Chute unique `Player._fall()` ; `_check_pits()` après le mouvement (marche, fin de dash) et dans `_try_glide()` (sans invulnérabilité d'arrivée si le point d'arrivée est un trou). Source `DamageInfo.Source.PIT = 4`, montant = stat `PIT_DAMAGE` (base 1), cause de mort télémétrie `pit`.
- `Room.is_pit_at`, `is_floor_at`, `cell_center_at` ; `Room._ready` appelle `Player.enter_room(self)`, `_exit_tree` appelle `leave_room()`.
- Mouton : `max_charge_distance = 45` tuiles dans `sheep.tres`, ligne `charge exhausted`. Somnambule : plus de poussée.
- `onset_combat_004` (couloir de 4 colonnes et îlots) valide ; `RoomValidator` : marqueur de renfort sur un trou, portes et ennemis coupés par les trous.
- Vérifications : GUT 83/83 (nouveaux : `test_pit_guard`, `test_pit_fall`, `test_sheep_and_sleepwalker_pits`, règles du validateur) ; `run_all.sh` en mode normal et `--quit-after 120` : voir le rapport. Le test du Somnambule échoue sans le correctif (vérifié).
- NON ÉVALUÉ : ressenti de la chute, de l'absence de poussée, lisibilité des trous (voir `deferred-work.md`).

### File List

`game/player/pit_guard.gd`, `game/player/player.gd`, `game/combat/damage_info.gd`, `game/core/{stat_block,combat_tuning}.gd`, `game/data/tuning/combat_tuning.tres`, `game/rooms/room.gd`, `game/rooms/validator/room_validator.gd`, `game/enemies/sheep/{sheep,sheep_def}.gd`, `game/data/enemies/sheep.tres`, `game/enemies/sleepwalker/sleepwalker.gd`, `game/rooms/pool/onset/onset_combat_004.tscn`, `art_source/rooms/onset_combat_004.txt`, `game/tests/**` (unit/player/test_pit_guard, integration/player/test_pit_fall, integration/rooms/test_sheep_and_sleepwalker_pits, unit/rooms/test_room_validator, fixtures/rooms/{pit_band,pits_cut_door,enemy_cut_off,reinforcement_on_pit}).

### Change Log

- 2026-11-24 : implémentation de la story 4.3 (trous, chute, Mouton, Somnambule, salle 004, validateur).
- 2026-11-24 : revue de code (Opus, trois couches) : 6 correctifs à faire, 6 reports, 2 décisions ; retour en `in-progress`.
