# Story 5.7 : Déclencher les synergies de la Chute

Status: done

## Story

En tant que joueur,
je veux qu'en réunissant des objets Chute, une synergie s'annonce et change ma façon de jouer,
afin que les combinaisons se devinent et récompensent.

Exigences : FR54 (epics.md, Story 5.7). Architecture : D9 (`TagTracker`, `synergy_activated`), `SynergyDef` en `.tres`.

**Dépend de : 5.1** (`TagTracker`, bannière, `BuildCarrier.dash_ended`), **5.6** (les quatre objets Chute doivent exister pour atteindre 3 ; les tests de 2 objets n'ont besoin que de 5.1 : Dent et Jambes de plomb). Le dash vient de 1.4 ; les dégâts de zone d'`Room`.

Hors périmètre : synergies des autres tags (Temps, Regard, Corps : après le MVP).

## Critères d'acceptation

1. **`TagTracker`** compte les objets **distincts** (par `ItemDef.id`) par tag ; deux Dents qui tombent comptent une fois (déjà vrai depuis 5.1, vérifié ici avec les seuils). Les tags sont des `StringName` (`&"fall"`, `&"time"`, `&"gaze"`, `&"body"`) ; `strings.csv` ne les affiche pas (la synergie a son nom).
2. **`SynergyDef`** (`items/synergy_def.gd`) : `id`, `tag`, `threshold`, `name_key`, `description_key`, `params: Dictionary[StringName, float]` ; `data/synergies/fall_2.tres` (« Piqué », seuil 2 : `shock_damage` 15, `shock_radius_tiles` 1,5) et `fall_3.tres` (« Chute sans fin », seuil 3 : `shock_damage` 30, `shock_radius_tiles` 2,5, `pit_damage` 0). Toute valeur du GDD est dans ces fichiers.
3. **Annonce** : quand le compte d'un tag atteint le seuil, `TagTracker` émet `synergy_activated(def)` (une seule fois par synergie et par porteur), `Events.banner_requested(name_key, description_key, "")` annonce le nom et l'effet en clair, avec un son (`Audio`, placeholder `sfx_synergy.wav` généré comme les autres sons provisoires). Obtenir un 4e objet Chute ne réannonce rien.
4. **Piqué** (2 objets Chute distincts) : à chaque `dash_ended`, une onde de choc au point d'arrivée du joueur, rayon et dégâts du niveau actif. Elle touche **les ennemis** (`Room.enemies_within`) **et les meubles** (`Furniture` destructibles et leurs `Hurtbox`) dans le rayon, centre à centre ; les dégâts passent par `Hurtbox.receive(DamageInfo)` (nouvelle valeur `DamageInfo.Source.SHOCKWAVE`, ajoutée à la fin de l'enum). Elle ne touche jamais le joueur.
5. **Chute sans fin** (3 objets distincts) : l'onde passe à 30 dégâts et 2,5 tuiles (le niveau 3 **remplace** le niveau 2, pas d'addition), et le coup de chute ne retire plus de cœur (`PIT_DAMAGE` : modificateur `MULTIPLY 0`, source la synergie). La chute ramène toujours au dernier point sûr.
6. **Niveau actif = le plus haut seuil atteint** ; les modificateurs et l'onde se calculent à partir de lui. Un objet retiré qui fait repasser sous un seuil désactive le niveau (`TagTracker` émet `synergy_deactivated(def)`, l'effet est détaché, `clear_source`) : pas d'annonce.
7. **Feedback** : l'onde utilise `RingPulse` (anneau placeholder), au rayon réel ; secousse d'écran non demandée. Un son court de l'onde (placeholder).
8. **Débogage** : F1 donne les 4 objets Chute d'un coup (touche `Y`), pour tester le seuil 3.

## Tâches

- [x] `items/synergy_def.gd`, `data/synergies/fall_2.tres`, `fall_3.tres`, liste des synergies dans `ItemCatalog` (`SynergyCatalog.all()` trié par seuil).
- [x] `TagTracker` : seuils, `synergy_activated` / `synergy_deactivated`.
- [x] `items/synergy_effect.gd` (`RefCounted`, comme `ItemEffect` : `attach(carrier, def)`, `detach()`), `items/effects/dive_effect.gd` (Piqué et Chute sans fin partagent la classe : le niveau change les `params`).
- [x] `Room.shockwave(center_global, radius_px, damage, source)` : enemis (`enemies_within`) et meubles (`furnitures()`, test de distance au centre du meuble), renvoie le nombre de cibles touchées (journal).
- [x] `DamageInfo.Source.SHOCKWAVE`, `Player` : le carrier connaît la salle courante (`carrier.current_room`, posé par `Player.enter_room/leave_room`).
- [x] `strings.csv` (« Piqué », « Chute sans fin » et descriptions), son placeholder, tests.

## État du code concerné

- `Player.dash_ended` (signal) et `_on_dash_ended` : émis après le dernier déplacement du dash (`finish_tick` après `move_and_slide`). 5.1 le relaie sur `BuildCarrier.dash_ended`.
- `Room.enemies_within(point, radius_px)` renvoie les ennemis vivants ; `furnitures()` renvoie tous les meubles, détruits compris ; `Room._on_player_awakening_used` pousse les ennemis (modèle d'une action de zone du joueur).
- `RingPulse` (`vfx/ring_pulse.gd`) existe, utilisé par l'Éveil et le Glissement.
- `Player.stats` : `PIT_DAMAGE` base 1 (demi-cœur) ; `_fall()` lit `stats.value_of(PIT_DAMAGE)` arrondi.
- 5.6 : Ailes de papier et Chute libre existent ; 5.1 : Dent (Corps, Chute), Jambes (Chute).

## Pièges

- **Hors de la physique** : l'onde est lancée depuis `dash_ended`, émis dans `_physics_process` du joueur (pas dans un callback d'Area2D), donc sûre ; mais `Hurtbox.receive` d'un ennemi qui meurt libère l'ennemi : parcourir une **copie** de la liste d'ennemis (`enemies_within` en renvoie une), vérifier `is_instance_valid` à chaque cible.
- Un meuble détruit par l'onde, déjà détruit : tester l'état avant de `receive` (voir `Furniture`) ; une onde sur un meuble indestructible n'a pas d'effet, sans erreur.
- Une onde déclenchée **par un dash qui finit dans un trou** ou qui se termine par un coup de mur : `dash_ended` n'est émis que sur fin normale ; ne pas ajouter de cas.
- Le dash annulé par `Player.stop_motion()` (changement de salle, 4.8) ne doit pas émettre `dash_ended` : vérifier que `Dash.cancel()` n'émet pas `ended`, sinon une onde partirait dans le noir.
- `TagTracker` reste pur (pas de nœud) ; `BuildCarrier` y branche l'ajout à `Loadout.item_added`. Retirer un objet en double (Dent ×2) ne baisse pas le compte tant qu'une copie reste.
- Au-delà de 3 objets Chute distincts (le 4e), aucun seuil de plus n'est défini : le niveau reste 3.

## Tests

- `unit/items/test_tag_tracker.gd` (étendre) : seuils 2 et 3, une seule annonce par seuil, Dent ×2 ne double pas, `synergy_deactivated` au retrait.
- `unit/items/test_synergy_defs.gd` : `fall_2.tres` et `fall_3.tres` valides, valeurs 15/1,5 et 30/2,5, `pit_damage` 0 au seuil 3.
- `integration/items/test_dive_synergy.gd` : joueur avec Dent + Jambes, dash, un ennemi à 1 tuile perd 15 PV, un à 3 tuiles rien, un meuble à 1 tuile est touché ; ajout d'un 3e objet Chute : onde 30 / 2,5 tuiles et chute dans un trou sans perte de cœur ; la bannière est demandée une fois par seuil.

## Sources

epics.md (Story 5.7) ; GDD « Tags thématiques » et « Synergie du MVP » ; architecture D9.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Le niveau le plus haut remplace le précédent** (30 dégâts, pas 15 + 30), conformément au texte du GDD (« l'onde double »).
2. **Synergie = `SynergyEffect` séparé d'`ItemEffect`** (pas d'`ItemDef` fictive) : même contrat attach / detach.
3. **Dégâts de l'onde via une nouvelle source `SHOCKWAVE`** pour la télémétrie et le recul éventuel.
4. **Chute sans fin n'annule pas la chute** (retour au point sûr) : seul le coût en cœur disparaît.
5. **Le son et l'anneau de l'onde sont des placeholders** (epic 7).
6. **Touche F1 `Y`** : donne les objets Chute ; le test par scène reste la référence.

7. **Le niveau qui devient actif émet `synergy_activated` à chaque fois** (retour après un retrait compris) : c'est ce qui attache l'effet. L'annonce (bannière + son) est faite **une seule fois par synergie et par porteur** par `BuildCarrier`. Un changement de niveau émet `synergy_deactivated(ancien)` puis `synergy_activated(nouveau)`.
8. **La bannière de synergie suit celle de l'objet** (`acquire` la retient jusqu'après sa propre bannière, sinon l'objet remplacerait la synergie à l'écran).
9. **`SynergyDef.effect_script`** ajouté aux champs de la story (même rôle que `ItemDef.effect_script`) ; `SynergyCatalog` (`all()`, `problem_of`, `make_effect`) dans son propre fichier, pas dans `ItemCatalog`.
10. **`Room.shockwave(center, radius_px, damage, color, duration)`** crée l'anneau (`RingPulse`) elle-même et utilise toujours `SHOCKWAVE` (pas de paramètre `source`). Le son de l'onde (`sfx_shockwave.wav`) est joué par `DiveEffect`.
11. **Le modificateur de coût de chute** vient du paramètre `pit_damage` (MULTIPLY) présent seulement dans `fall_3.tres`, source = l'effet.

Décisions de la revue de code (2026-11-24) :

12. **La bannière de synergie est mise en file, pas en remplacement** (voir patch) : avec la décision 8, la bannière de l'objet est remplacée dans la même image et n'est jamais lue (nom, bonus, **coût**) quand l'objet ramassé au sol atteint un seuil. File d'attente plutôt qu'inversion de l'ordre : l'objet reste lisible 3 s, puis la synergie 3 s. Le son de synergie reste joué au moment du seuil.
13. **Un dash qui finit au-dessus d'un trou lance l'onde** (le piège « `dash_ended` n'est émis que sur fin normale » est faux : `finish_tick` émet avant `_check_pits`) : gardé, l'onde part au bord du trou puis le joueur tombe ; c'est un « piqué », sans coût de plus, pas de cas particulier.
14. **L'onde ne touche ni les lampes (`Trigger`) ni les cibles d'entraînement de l'arène** : conforme au CA 4 (ennemis + meubles) ; à revoir au playtest si la lampe doit s'allumer à l'onde.
15. **Cycle de chargement `EnemyDef` → … → `Pickup` → `Run` → `arena.tscn` → `arena_waves.tres` → `EnemyDef`** : reporté (antérieur à 5.7, sans effet quand `Main` est le point d'entrée), voir `deferred-work.md`.

## Dev Agent Record

### Notes de complétion

- `SynergyDef`, `SynergyCatalog`, `SynergyEffect`, `DiveEffect`, `data/synergies/fall_{2,3}.tres` ; `TagTracker` calcule le niveau actif (`active_synergy`, `synergy_activated/deactivated`) ; `BuildCarrier` attache/détache les effets (cycle de vie : rattachés à `_enter_tree`, détachés à `_exit_tree`), annonce une fois, `current_room` posé par `Player.enter_room/leave_room`.
- `Room.shockwave` : ennemis (`enemies_within`, copie) et meubles debout (centre de l'empreinte), via `Hurtbox.receive` ; `DamageInfo.Source.SHOCKWAVE = 5`. Touche F1 `Y` : les objets Chute.
- Sons provisoires `sfx_synergy.wav`, `sfx_shockwave.wav` (générés par script, epic 7). Chaînes `SYNERGY_FALL_{2,3}_{NAME,DESC}`.
- Les tests d'intégration chargent l'ennemi avec `load()` : un `preload` d'un `EnemyDef` dans un test GUT isolé provoque un cycle de chargement via `arena_waves` (même effet existant avec `test_sheep_and_sleepwalker_pits`, hors périmètre).
- Checks : GUT 547/547 ; `--quit-after 120` propre ; `run_all.sh` : voir le rapport de l'agent.

### Liste des fichiers

`items/{synergy_def,synergy_catalog,synergy_effect,tag_tracker,build_carrier}.gd`, `items/effects/dive_effect.gd`, `data/synergies/*.tres`, `rooms/room.gd`, `combat/damage_info.gd`, `player/player.gd`, `debug/debug_panel.gd`, `localization/strings.csv`, `audio/sfx/sfx_{synergy,shockwave}.wav`, tests GUT `unit/items/test_{tag_tracker,synergy_defs}.gd`, `integration/items/test_dive_synergy.gd`.

### Non évalué (humain)

- Lisibilité et ressenti de l'onde (rayon, anneau, sons provisoires) et de la bannière de synergie : playtest du jalon A.

### Review Findings

Revue de code (2026-11-24, 3 couches : Blind Hunter, Edge Case Hunter, Acceptance Auditor, passes isolées), diff `83848c1..8acaa74`. Lignes à `8acaa74` (l'arbre de travail contient le travail en cours de 5.8). GUT des trois fichiers de la story : 17/17, 66 asserts. 1 patch, 1 report, 9 rejets.

- [x] [Review][Patch] La bannière de l'objet qui atteint un seuil n'est jamais lue [`game/items/build_carrier.gd:173-178`, `game/ui/hud/banner.gd:42`, `game/autoloads/events.gd:95`] — `acquire` émet la bannière de l'objet puis, dans la même image, `_announce_pending` émet celle de la synergie ; `Banner.show_banner` remplace la bannière affichée, donc le nom, le bonus et le coût de l'objet (ex. Ailes de papier) disparaissent sans être vus pour un objet gratuit (seuls les objets en vente ont la bannière d'approche). Même chose avec la touche F1 `Y` : la bannière du 4e objet efface les deux synergies. Correctif : nouveau signal `Events.banner_queued(title_key, bonus_key, cost_key)` ; `Banner` le branche sur `queue_banner()` qui affiche tout de suite si rien n'est affiché, sinon ajoute à une file (`Array` de triplets) lue par `hide_banner()` (la suivante s'affiche pour `DURATION`) ; `banner_requested` garde son comportement (remplace l'affichée, ne vide pas la file). `_announce_pending` émet `Events.banner_queued` au lieu de `banner_requested`. Test GUT (`test_dive_synergy.gd` ou un test de `Banner`) : objet qui atteint le seuil 2 → `lines()` montre l'objet, après `DURATION` s la synergie ; adapter l'assertion « bannière demandée une fois par seuil » au nouveau signal.

Correctifs de la revue appliqués et vérifiés (2026-11-24) : file de bannières (`Events.banner_queued`, `Banner.queue_banner`, `hide_banner` affiche la suivante), `_announce_pending` émet `banner_queued` ; GUT vert (`test_banner_queue.gd`, `test_dive_synergy.gd` adapté).
- [x] [Review][Defer] Cycle de chargement quand un `EnemyDef` est le premier chargé — reporté, voir `deferred-work.md` (antérieur à 5.7).

Rejetés (9) : l'onde frappe le joueur (non : seulement `enemies_within` et `furnitures()`) ; ennemi tué pendant la boucle (copie + `is_instance_valid`, `_die` libère en différé) ; meuble détruit ou détruit par l'onde (`is_destroyed()` puis filtre `_can_be_hit`, coupure physique différée) ; onde pendant une transition (`stop_motion` → `Dash.cancel()` n'émet pas `ended` ; `current_room` nul entre deux salles ; une onde dans l'ancienne salle pendant le fondu est sans conséquence) ; pause et mort (pas de `_physics_process` du joueur, donc pas de `dash_ended`) ; rayon dans les grandes salles (en tuiles, indépendant de la taille) ; `clear_source` exact (une source par instance de `DiveEffect`, nouvelle instance par niveau) ; Chute libre avec Chute sans fin (une chute à 0 ne passe pas par la hurtbox, pas de ½ cœur de plus : conforme au CA 5) ; touche `Y` libre (seule dans `debug_panel.gd`, absente de `project.godot`).
