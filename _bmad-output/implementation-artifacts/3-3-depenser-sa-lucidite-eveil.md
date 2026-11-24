# Story 3.3 : Dépenser sa lucidité : Éveil

Status: review

## Story

En tant que joueur,
je veux effacer tous les projectiles d'un sursaut de lucidité,
afin de me sortir d'une situation perdue au prix de ma jauge.

Exigences : FR21, FR23 (epics.md, Story 3.3). Architecture : D5 (`try_spend`), D6 (action `power_1`), D13 si présent, `player/powers/`.

**Dépend de : 3.1** (`Lucidity`, relais `Events`, télémétrie) et **3.2** (`Source`, `begin_room`, câblage `Arena` -> `Player` par signaux locaux, `Hurtbox` / `BulletManager` étendus). **Prépare 3.4** (Glissement réutilise `PowerCooldown`, le son de refus, `ring_pulse`, l'action `power_2` et le motif « entrée -> `try_spend` -> effet »).

Hors périmètre : bonus de palier (3.5), danger (3.6), distorsions et tremblement d'écran (3.8, qui ajoutera un léger tremblement à Éveil), indicateur de recharge dans le HUD (les emplacements d'objets arrivent en epic 5 ; voir décision 6).

## Critères d'acceptation

1. **Dépense** : `Lucidity.try_spend(cost: int, power: StringName = &"") -> bool` refuse (renvoie `false`, aucun changement, aucun signal de valeur) si `value < cost` ou `cost <= 0` ; sinon retire `cost`, émet `value_changed` / `tier_changed` comme `set_value` et le signal `spent(power, cost, tier_before)`. À 0, toute dépense est refusée.
2. **Éveil** : avec la jauge à 30 ou plus et Éveil prêt, clic droit ou LT (`power_1`) appelle `try_spend(30, &"awakening")` ; en cas de succès : tous les projectiles du manager ennemi disparaissent (sans toucher personne, sans graze ni dash parfait) ; les ennemis à moins de 3 tuiles du joueur (centre à centre) sont repoussés de 2 tuiles, sans traverser les murs ; Éveil est en recharge 1 s. Les tirs du joueur ne sont pas effacés.
3. **Refus** : jauge sous 30, ou Éveil en recharge, ou jeu en pause (échelle d'horloge 0) : rien n'est consommé, un son de refus se joue (pas pendant la pause). Le refus ne relance pas la recharge.
4. **Coups** : un coup reçu ne touche jamais la lucidité (aucun code ne l'écoute ; test explicite).
5. **Données** : coût (30), recharge (1 s), rayon d'effet (3 tuiles), distance de recul (2 tuiles) viennent de `AwakeningTuning` (`Tuning.AWAKENING`).
6. **Télémétrie** : chaque dépense réussie est journalisée (`Log.info("lucidity", "spend awakening cost=30 tier=…")`) et comptée dans le JSON de session avec le palier **avant** la dépense (`run_end.spends`, `summary` cumulé), via `Events.lucidity_spent(power, cost, tier)`.
7. **Retour visuel et sonore minimal** : un anneau qui se dilate (placeholder `ring_pulse`) autour du joueur, sans flash plein écran ; un son d'Éveil ; un son de refus partagé.

## Tâches

- [x] `core/awakening_tuning.gd` + `data/tuning/awakening_tuning.tres` (`cost`, `cooldown`, `effect_radius`, `knockback_distance`), `Tuning.AWAKENING`.
- [x] `Lucidity.try_spend()` + signal `spent` ; `Player` relaie sur `Events.lucidity_spent(power, cost, tier)` (entiers et `StringName`).
- [x] `player/powers/power_cooldown.gd` (`RefCounted`, ticks de jeu comme `Dash`) : `start(seconds)`, `tick(clock_scale)`, `is_ready()`, `progress()`.
- [x] `project.godot` : `power_1` = clic droit (`MOUSE_BUTTON_RIGHT`) + manette axe `4` (LT, `JOY_AXIS_TRIGGER_LEFT`), zone morte 0,5 comme `shoot`. `power_2` est ajoutée par 3.4.
- [x] `Player` : lecture de `power_1` dans `_physics_process` (`is_action_just_pressed`, après le dash), cooldown, signal local `awakening_used(origin: Vector2)`, son de refus.
- [x] `BulletManager.clear_all() -> int` : libère tous les projectiles actifs (compte renvoyé), sans signal de touche ni de graze ; restitue les emplacements au pool.
- [x] `Enemy.knock_back(direction: Vector2, distance_px: float)` : déplacement par `move_and_collide` (masque murs et ennemis déjà en place), jamais à travers un mur.
- [x] `Arena` : `_on_awakening_used(origin)` branché sur le joueur (même câblage que le graze de 3.2) : `_enemy_bullets.clear_all()`, recul des ennemis du rayon, anneau.
- [x] `vfx/ring_pulse.gd` (`Node2D`, dessin d'un cercle qui grandit et s'estompe, rayon, couleur, durée en ticks du groupe `FX`) ; sons `sfx_awakening.wav`, `sfx_power_refused.wav` (générés, provisoires).
- [x] Télémétrie : `TelemetrySession` compte les dépenses ; F3 affiche la recharge d'Éveil ; vérifications `t_awakening` ; `run_all.sh` une fois à la fin.

## État du code concerné

- `Lucidity` (3.1, complété par 3.2) : `value`, `live_tier`, `gain(amount, source)`, `set_value`, `begin_room`, signaux `value_changed`, `tier_changed`. Pas de `try_spend` : on l'ajoute ici et il ne passe jamais par `gain`.
- `Player._physics_process` : lit le dash (`Dash.tick` avec `clock_scale`), puis tir, puis mouvement. L'horloge du joueur : `GameClock.scale(GameClock.Group.PLAYER)` (0 en pause : une pression ne démarre rien, comme pour le dash). Le joueur relaie déjà la lucidité sur `Events` (3.1).
- `BulletManager` : tableaux parallèles, `_free(i)` remet l'emplacement dans la pile ; `active_count` est tenu à jour par `_free`. Le manager ennemi est `Arena._enemy_bullets`.
- `Enemy` : `CharacterBody2D`, `collision_mask = WALLS | PLAYER | ENEMIES`, déplacements par `_move_toward` / `_move_in_direction`. Aucune API de recul ; le Mouton en charge, la Berceuse en inspiration, etc. ne sont pas interrompus par un recul (voir décision 3).
- `Telemetry` / `TelemetrySession` (3.1) : `run_end` porte déjà `tier_seconds`.
- 3.4 ajoute `power_2`, `GlideTuning`, des obstacles bas et hauts : `Player` aura donc deux pouvoirs côte à côte ; écrire ici `_update_powers()` extensible plutôt que du code inline dans `_physics_process`.
- 3.8 appelle depuis `Arena._on_awakening_used` un tremblement d'écran de faible intensité (`Arena.shake()`), sans changer le contrat.

## Pièges

- **Ordre de lecture** : lire `power_1` après `Dash.tick` et avant `move_and_slide()` ; ne pas écrire `velocity` ici (le recul des ennemis, lui, déplace les autres corps).
- **`is_action_just_pressed` sur LT** : l'axe de la gâchette est une action analogique ; la zone morte 0,5 évite les déclenchements. Dans Godot, `just_pressed` ne part qu'au franchissement du seuil.
- **`clear_all` pendant une itération** : l'Éveil est déclenché depuis `Player._physics_process` (priorité 0), le manager tourne à la priorité 100 : jamais pendant sa boucle. Ne pas l'appeler depuis un signal émis par le manager (`grazed`, `dodged`).
- **Recul et murs** : `move_and_collide(direction * distance)` s'arrête au premier obstacle ; il ne tue pas l'ennemi ni ne le coince (le corps part d'une position libre). Pour un ennemi tout juste au contact d'un mur, la distance réelle est plus courte : c'est le comportement voulu. Les ennemis qui se bloquent entre eux (masque `ENEMIES`) s'arrêtent aussi.
- **Direction du recul** : du joueur vers l'ennemi ; si les centres coïncident (< 1e-3), une direction par défaut (droite) évite un vecteur nul. Pas de `randf()`.
- **Interpolation physique** : un déplacement instantané de 32 px est interpolé sur un tick (glissement très court) ; acceptable, ne pas appeler `reset_physics_interpolation()` (ce serait un saut sec, et la téléportation de 3.4 est ce cas).
- **Cooldown** : compté en ticks de jeu du groupe `PLAYER` comme le dash (jamais `Timer`) ; il se fige en pause et ralentit sous F4.
- **`StringName` sur le bus** : `Events.lucidity_spent(power: StringName, cost: int, tier: int)` ; le tier est un entier (`Lucidity.Tier`), les autoloads ne connaissent pas les classes de fonctionnalité.
- `ring_pulse` ne doit pas lire `GameClock` du groupe `PLAYER` ; groupe `FX`.

## Vérifications prévues (`.scratch/t_awakening.gd`)

- `Lucidity` pur : `try_spend(30)` depuis 100 -> 70 et `spent(awakening, 30, LUCID)` ; depuis 29 -> `false`, rien ne bouge ; depuis 30 -> 0, palier Abandon total, `tier_changed` une fois ; `try_spend(0)` et négatif refusés.
- `PowerCooldown` : prêt au départ, 60 ticks après `start(1.0)`, figé à l'échelle 0, ralenti à 0,25.
- Dans le jeu : projectiles ennemis à l'écran -> 0 après Éveil (comptes `active_count`), projectiles du joueur intacts, jauge -30, anneau créé ; second appui avant 1 s refusé (son de refus, jauge inchangée) ; après 60 ticks accepté ; sous 30, refusé.
- Recul : un ennemi à 2 tuiles recule de 2 tuiles ; à 4 tuiles ne bouge pas ; adossé à un mur, il ne traverse pas ; deux ennemis alignés ne se superposent pas.
- Un coup reçu laisse `lucidity.value` inchangé ; pause : aucun Éveil, aucun son de refus.
- Télémétrie : une dépense journalisée avec le palier d'avant ; `summary` cumule.

## Fichiers prévus

`game/core/awakening_tuning.gd`, `game/data/tuning/awakening_tuning.tres`, `game/core/tuning.gd`, `game/player/lucidity.gd`, `game/player/powers/power_cooldown.gd`, `game/player/player.gd`, `game/combat/bullets/bullet_manager.gd`, `game/enemies/enemy.gd`, `game/rooms/arena/arena.gd`, `game/vfx/ring_pulse.gd`, `game/autoloads/events.gd`, `game/project.godot`, `game/telemetry/*.gd`, `game/debug/perf_overlay.gd`, `game/audio/sfx/sfx_{awakening,power_refused}.wav`, `game/.scratch/t_awakening.*`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **`try_spend(cost, power)` : le nom du pouvoir est un second argument facultatif** — Raison : la télémétrie doit savoir quel pouvoir a dépensé ; l'AC de l'epic ne donne que le coût.
2. **Palier journalisé = palier d'avant la dépense** — Raison : « le palier au moment de la dépense » ; c'est le palier dans lequel le joueur a décidé. Le palier d'après se lit dans `lucidity_tier_changed`.
3. **Le recul ne coupe aucune attaque en cours** (charge du Mouton, télégraphe, grattage) — Raison : le GDD ne le dit pas ; interrompre créerait des états à tester dans 4 ennemis. À revoir au playtest.
4. **Recul instantané (`move_and_collide`), pas d'animation** — Raison : lisible, sans état supplémentaire ; l'anneau signale l'effet.
5. **Les projectiles du joueur ne sont pas effacés** — Raison : « tous les projectiles ennemis » (GDD).
6. **Pas d'indicateur de recharge dans le HUD ; le son de refus est le seul retour** — Raison : le HUD n'a pas d'emplacement de pouvoir avant l'epic 5 ; ligne F3 pour le debug. Marqué `NON ÉVALUÉ` : à juger au playtest du jalon A.
7. **`power_1` : clic droit et LT (axe 4)** — Raison : AC de l'epic ; `power_2` suivra en 3.4 (Maj, LB).
8. **Éveil utilisable pendant un dash** — Raison : aucune règle contraire ; c'est une sortie de secours.

## Dev Agent Record

### Agent Model Used

Agent : Claude Sonnet 5.5 (dev-story, mode lean).

### Completion Notes

- Toutes les tâches faites. `Lucidity.try_spend(cost, power)` + signal `spent` ; `Player` relaie sur `Events.lucidity_spent` et journalise (`spend awakening cost=30 tier=… value=…`). `PowerCooldown` (ticks de jeu), `power_1` (clic droit + LT axe 4, zone morte 0,5), `Player._update_powers()` extensible pour 3.4, signal `awakening_used(origin)`.
- `Arena._on_awakening_used` : `clear_all()` du manager ennemi, recul des ennemis à moins de 3 tuiles (`Enemy.knock_back`, `move_and_collide`, direction par défaut à droite si centres confondus), `RingPulse` (groupe FX). Sons `sfx_awakening.wav` et `sfx_power_refused.wav` générés (provisoires, 7.7).
- Télémétrie : `TelemetrySession.spent()` ; `run_end.spends` et `summary.spends` = `{pouvoir: {palier_avant: nombre}}`. F3 : « Awakening n% » (recharge).
- Aucune chaîne joueur ajoutée (pas de texte à localiser).
- Vérifications : `t_awakening` (39 ok), ajoutée à `run_all.sh` ; `run_all.sh` en mode normal : ALL PASS (868 ok) ; `--quit-after 120` propre. `t_hud` a échoué une fois sous charge (fuite d'objets à la sortie, flaky, sans lien : reproduit sans mes changements), repassé ensuite.
- Décisions du spec respectées sans écart. Précision : une pression est ignorée (sans son de refus) si l'horloge du joueur est à 0 ; un joueur mort entend le son de refus et ne dépense rien.
- NON ÉVALUÉ (humain) : sensation d'Éveil (recul de 2 tuiles, anneau, sons provisoires, recharge 1 s), absence d'indicateur de recharge dans le HUD (décision 6), recul qui n'interrompt pas les attaques (décision 3), LT sur manette réelle.

### File List

Nouveaux : `game/core/awakening_tuning.gd`, `game/data/tuning/awakening_tuning.tres`, `game/player/powers/power_cooldown.gd`, `game/vfx/ring_pulse.gd`, `game/audio/sfx/sfx_awakening.wav`, `game/audio/sfx/sfx_power_refused.wav` (+ `.import`, `.uid`).
Modifiés : `game/core/tuning.gd`, `game/player/lucidity.gd`, `game/player/player.gd`, `game/autoloads/events.gd`, `game/project.godot`, `game/combat/bullets/bullet_manager.gd`, `game/enemies/enemy.gd`, `game/rooms/arena/arena.gd`, `game/telemetry/telemetry.gd`, `game/telemetry/telemetry_session.gd`, `game/debug/perf_overlay.gd`.

### Change Log

- 2026-11-24 : implémentation de la story 3.3 (Éveil), passée en review.
