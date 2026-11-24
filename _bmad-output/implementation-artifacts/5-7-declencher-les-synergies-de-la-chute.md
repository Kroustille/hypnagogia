# Story 5.7 : Déclencher les synergies de la Chute

Status: ready-for-dev

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

- [ ] `items/synergy_def.gd`, `data/synergies/fall_2.tres`, `fall_3.tres`, liste des synergies dans `ItemCatalog` (`SynergyCatalog.all()` trié par seuil).
- [ ] `TagTracker` : seuils, `synergy_activated` / `synergy_deactivated`.
- [ ] `items/synergy_effect.gd` (`RefCounted`, comme `ItemEffect` : `attach(carrier, def)`, `detach()`), `items/effects/dive_effect.gd` (Piqué et Chute sans fin partagent la classe : le niveau change les `params`).
- [ ] `Room.shockwave(center_global, radius_px, damage, source)` : enemis (`enemies_within`) et meubles (`furnitures()`, test de distance au centre du meuble), renvoie le nombre de cibles touchées (journal).
- [ ] `DamageInfo.Source.SHOCKWAVE`, `Player` : le carrier connaît la salle courante (`carrier.current_room`, posé par `Player.enter_room/leave_room`).
- [ ] `strings.csv` (« Piqué », « Chute sans fin » et descriptions), son placeholder, tests.

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
