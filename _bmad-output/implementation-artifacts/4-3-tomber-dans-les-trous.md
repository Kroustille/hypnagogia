# Story 4.3 : Tomber dans les trous

Status: ready-for-dev

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

- [ ] `DamageInfo.Source.PIT`, `CombatTuning.pit_damage_half_hearts`, `StatBlock.Stat.PIT_DAMAGE` et `CAN_FLY_OVER_PITS` (`Player._setup_stats` donne les bases), `Events` inchangé (le coup passe par `player_hit`).
- [ ] `PitGuard` pur ; `Room.is_pit_at(global_pos)`, `Room.is_floor_at(global_pos)` (lecture de cellule par `local_to_map`) ; `Player` : appel après `move_and_slide()` (marche), à `_on_dash_ended`, dans `_try_glide` après le déplacement.
- [ ] Fonction de chute unique `Player._fall(position)` (dégâts, repositionnement, invulnérabilité), jamais un second chemin.
- [ ] Mouton (`max_charge_distance`), Somnambule (pas de poussée), `onset_combat_004` via l'outil ASCII, `RoomValidator` (cellules interdites, accessibilité).
- [ ] Tests `tests/unit/player/test_pit_guard.gd`, `tests/integration/player/test_pit_fall.gd` (marche, dash au-dessus, dash qui finit dedans, Glissement dedans, stat active, invulnérable), `tests/unit/rooms/test_room_validator.gd` (nouvelles règles) ; `.scratch` : `run_all.sh` une fois.

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

## Dev Agent Record

### Agent Model Used

### Completion Notes

### File List
