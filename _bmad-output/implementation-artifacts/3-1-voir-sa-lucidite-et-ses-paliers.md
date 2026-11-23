# Story 3.1 : Voir sa lucidité et ses paliers

Status: done

## Story

En tant que joueur,
je veux une jauge de lucidité lisible qui annonce chaque changement de palier,
afin de savoir à tout moment où j'en suis.

Exigences : FR16, FR17, FR25 (jauge et son), AR10, NFR12 (temps par palier) (epics.md, Story 3.1). Architecture : D5 (`Lucidity`, `RefCounted` porté par le joueur), ADR-002 (deux lectures : `live_tier` ici, `room_tier` en 3.6), `LucidityTuning` dans `Tuning`, F1 appelle les mêmes méthodes publiques que le jeu (`lucidity.set_value()`).

Hors périmètre (stories suivantes) : gains graze/dash parfait/salle vidée (3.2), `try_spend` et Éveil (3.3), Glissement (3.4), bonus de dégâts et de précision (3.5), `room_tier`/`begin_room`/danger (3.6+), distorsions visuelles et passe-bas (3.8). Aucun bonus n'est appliqué en 3.1 : la lucidité est affichée, pas encore jouée.

## Critères d'acceptation

1. **Objet `Lucidity`** (`player/lucidity.gd`, `RefCounted`, sans dépendance aux scènes) : `value: int` à 100 à la création, `live_tier`, signaux `value_changed(value)` et `tier_changed(tier)`. Paliers lus dans `LucidityTuning.tres` (via `Tuning.LUCIDITY`) : Lucide 100 à 76, Flottant 75 à 51, Dérive 50 à 26, Abandon 25 à 1, Abandon total 0. Le joueur le crée à son apparition (une nouvelle partie = un nouveau joueur = 100).
2. **Bornes** : `gain(amount)` plafonne à 100 (le surplus est perdu) ; `set_value(v)` borne dans 0..100 ; la valeur ne descend jamais sous 0. Pas de signal si la valeur ne change pas ; `tier_changed` seulement si le palier change (dans un sens comme dans l'autre, y compris en sautant plusieurs paliers).
3. **Bus et son** : un changement de palier émet `Events.lucidity_tier_changed(tier, previous_tier)` (entiers) et joue un son de palier (un son pour descendre, un autre pour remonter, provisoires, pas de son à la création). Le changement de valeur émet `Events.lucidity_value_changed(value)` (état initial compris, comme la santé).
4. **HUD** : la jauge (`ui/hud/lucidity_gauge.gd`) occupe la place réservée de 160×8 px (le cadre `HudSlot` reste), se remplit proportionnellement à la valeur, change de couleur par palier, montre les limites des paliers (3 repères à 75, 50 et 25) et se met à jour par l'événement de valeur. Le nom du palier s'affiche à droite de la jauge (clés `strings.csv`). Le HUD ne lit jamais l'état du jeu : il n'écoute que `Events`. Rien ne dépasse la bande de 24 px.
5. **Debug** : F1 fixe la lucidité par `player.lucidity.set_value()` (touche `L`, cycle 100, 75, 50, 25, 0) ; F3 affiche valeur et palier en direct.
6. **Télémétrie (NFR12)** : à chaque fin de partie, le journal (`Log.info("lucidity", …)` et le JSON de session) donne le temps passé dans chaque palier ; `summary` cumule `tier_seconds` sur la session. Écoute `Events` seulement.
7. Textes par `tr()` et `strings.csv`, aucune valeur de palier en dur dans le code (tout vient de `LucidityTuning`).

## Tâches

- [x] `core/lucidity_tuning.gd` + `data/tuning/lucidity_tuning.tres` (valeurs max et plancher de chaque palier), `Tuning.LUCIDITY`.
- [x] `player/lucidity.gd` : `Tier` (LUCID, FLOATING, DRIFT, ABANDON, TOTAL_ABANDON), `value`, `live_tier`, `gain()`, `set_value()`, `tier_for()`, signaux.
- [x] `Events.lucidity_value_changed`, `Events.lucidity_tier_changed` ; `Player` crée `lucidity`, relaie sur le bus et joue le son ; deux sons `sfx_lucidity_tier_down.wav` / `sfx_lucidity_tier_up.wav` (générés par script, placeholders).
- [x] `ui/hud/lucidity_gauge.gd` dans le HUD, étiquette de palier, clés `UI_LUCIDITY_*` dans `strings.csv`.
- [x] F1 touche `L` ; ligne F3 ; télémétrie par palier (`TelemetrySession` pur + `Telemetry`).
- [x] Vérifications headless (`.scratch/t_lucidity.gd`, ajoutée à `run_all.sh`), `run_all.sh` complet une fois, `--quit-after 120` propre.

### Review Findings

Revue de code du 2026-11-23 (mode complet : Blind Hunter, Edge Case Hunter, Acceptance Auditor). 0 décision en attente (3 tranchées, voir les décisions 9 à 11), 5 corrections, 6 reports, 10 écartées.

- [x] [Review][Patch] Flash de la jauge au début d'une nouvelle partie si la précédente a fini hors de Lucide [game/ui/hud/hud.gd:134] — `_tier` du HUD survit au joueur, donc l'état initial `(100, LUCID)` du nouveau joueur passe pour un changement de palier. Correction : ne plus déduire l'annonce de l'événement de valeur. Dans `hud.gd:134`, appeler `set_state(value, tier)` sans annonce (retirer le paramètre `announce` de `LucidityGauge.set_state`, `lucidity_gauge.gd:32-37`) ; ajouter `LucidityGauge.flash()` (`_flash_left = FLASH_SECONDS` puis `set_process(true)`) ; dans `Hud._ready` (`hud.gd:59`), brancher `Events.lucidity_tier_changed` sur un gestionnaire qui appelle `_lucidity_gauge.flash()`. Le bus n'émet jamais ce signal pour l'état initial, et il arrive après l'événement de valeur.
- [x] [Review][Patch] `set_value()` réentrant : un `tier_changed` périmé est émis après un appel imbriqué [game/player/lucidity.gd:42] — si un auditeur de `value_changed` rappelle `set_value()`/`gain()` (Éveil 3.3, Glissement 3.4), l'appel externe émet ensuite l'ancien palier : deux sons, télémétrie et `Player._announced_tier` faux. Correction : `if tier_moved and live_tier == tier:` à la place de `if tier_moved:`.
- [x] [Review][Patch] `LucidityTuning` non validé [game/player/lucidity.gd:21-24] — 6 planchers donnent un `Tier` hors de l'enum (pinces silencieuses dans le HUD et la télémétrie, `<null>` en F1/F3), un ordre faux donne un mauvais palier. Correction : dans `_init`, `assert(tuning.tier_floors.size() == Tier.size())`, `assert(tuning.tier_floors[-1] == 0)`, `assert(tuning.tier_floors[0] <= tuning.max_value)` et une boucle `assert(tuning.tier_floors[i] < tuning.tier_floors[i - 1])`.
- [x] [Review][Patch] `run_ended()` hors partie renvoie les secondes de la partie précédente [game/telemetry/telemetry_session.gd:56-58] — mort sans `run_started` (arène non chargée, `run.gd:22-26`, puis F1 `3`) : la ligne INFO « time per tier » donne les chiffres d'une ancienne partie. Correction : `if _tier == -1: return []` avant `_close_tiers`, et dans `telemetry.gd:97-98` ne journaliser que si le tableau rendu n'est pas vide.
- [x] [Review][Patch] Préréglages F1 `L` écrits en dur et premier appui sans effet [game/debug/debug_panel.gd:16, 26, 171, 255] — `[100, 75, 50, 25, 0]` répète le tuning (CA7) ; l'index part de -1, donc le premier appui pose 100 sur une jauge pleine (aucun signal, mais « lucidity set to 100 » au journal). Correction : construire les préréglages depuis `Tuning.LUCIDITY` (`max_value`, puis `floor - 1` pour chaque plancher `> 0`), démarrer `_lucidity_preset` à 0 pour que le premier appui donne 75, et construire la ligne d'aide depuis ce tableau.
- [x] [Review][Defer] Télémétrie : palier de départ supposé Lucide [game/telemetry/telemetry_session.gd:39] — reporté à 3.6 (début de salle, `begin_room`).
- [x] [Review][Defer] Jauge : repères au pixel près (76 identique à 75, 26 à 25, 51 déborde d'un pixel) et règle `floor_value > 1` [game/ui/hud/lucidity_gauge.gd:44, 52-53] — reporté à 7.2 (aspect final du HUD).
- [x] [Review][Defer] Abandon total invisible sur la jauge (remplissage nul, flash sur une largeur de 0) [game/ui/hud/lucidity_gauge.gd:76-78] — reporté à 3.8 (distorsions par palier).
- [x] [Review][Defer] Événement `run_end` ambigu (mort, relance F1, sortie) et ligne INFO seulement à la mort [game/telemetry/telemetry_session.gd:37, 57, 84 ; game/telemetry/telemetry.gd:97-98] — reporté à 6.4 (issue de partie dans la télémétrie).
- [x] [Review][Defer] `summary.tier_seconds` sans la partie en cours (crash) [game/telemetry/telemetry_session.gd:109] — reporté à 1.8 (préparation du playtest).
- [x] [Review][Defer] `gain()` accepte un montant négatif [game/player/lucidity.gd:28-29] — reporté à 3.3 (`try_spend`).

Les 5 corrections ont été appliquées et vérifiées le 2026-11-23 (`run_all.sh` : ALL PASS, `t_lucidity` complété : pas de flash au démarrage, `set_value` imbriqué, `run_ended` hors partie, préréglages F1).

## État du code concerné

- `Player._setup_health()` crée `Health` et émet `player_health_changed` en initial ; même schéma pour la lucidité. `Run` émet `run_started` en fin de `_ready`, après le joueur prêt.
- `Hud` (2.7) : `_make_slot("LucidityGaugeSlot", 160×8, centré)` ; `t_hud` exige que ce slot n'ait aucun enfant : la jauge est donc un `Control` frère posé sur le cadre, pas un enfant. Cœurs à gauche (≤ 114 px), Éclats dès x = 524 : la place à droite de la jauge (x 406 à 520) accueille l'étiquette.
- `Telemetry` / `TelemetrySession` (2.8) : horloge réelle, fichier réécrit à chaque événement, `to_dict()` pur. Report de 2.8 : « la télémétrie devra écouter `Events.lucidity_tier_changed` ».
- `DebugPanel` : touches 1 à 9, 0, `-`. `PerfOverlay` : 2 lignes (FPS, balles). `Log.CATEGORIES` contient déjà `lucidity`.
- `Tuning` : `const X: XTuning = preload(...)`, Resources en lecture seule.

## Pièges

- `.tres` partagé : ne jamais l'écrire ; `Lucidity` garde sa valeur à elle.
- `Lucidity` est un `RefCounted` : le joueur le tient dans une variable (sinon libéré) ; pas de `Node` donc aucun `_ready`.
- Signal d'initialisation : le HUD est ajouté avant la première partie, donc il reçoit l'état initial ; après un redémarrage, le nouveau joueur ré-émet 100.
- Les repères des paliers viennent de `LucidityTuning` (pas de 75/50/25 dans l'UI) ; la jauge dessinée en `_draw()` à la résolution 640×360, entiers seulement (pas de flou).
- Télémétrie : un changement de palier peut précéder `run_started` (le joueur émet avant `Run`) : le suivi des paliers ne démarre qu'à `run_started`, avec le palier Lucide (joueur neuf).
- Typage strict : pas de `Variant` implicite, `@warning_ignore` interdit sans raison.

## Vérifications prévues (`.scratch/t_lucidity.gd`)

- `Lucidity` pur : départ 100 Lucide ; bornes de chaque palier (100, 76, 75, 51, 50, 26, 25, 1, 0) ; `gain(+10)` depuis 95 donne 100 ; `set_value(-5)` donne 0 ; pas de signal sans changement ; `tier_changed` une fois par franchissement, saut de plusieurs paliers inclus.
- Dans le jeu (`main.tscn`) : joueur à 100 ; `set_value` émet `Events.lucidity_tier_changed` et joue le son (voix du son de descente = 1) ; la jauge se remplit en proportion, change de couleur, le texte de palier suit ; les repères tiennent dans la bande ; une partie relancée repart à 100.
- Télémétrie pure : temps cumulés par palier d'une partie de plusieurs changements, total = durée, `summary.tier_seconds` ; événement `run_end` dans le JSON.
- F1 `L` : la valeur suit le cycle ; F3 : la ligne contient le palier.

## Fichiers prévus

`game/core/lucidity_tuning.gd`, `game/data/tuning/lucidity_tuning.tres`, `game/core/tuning.gd`, `game/player/lucidity.gd`, `game/player/player.gd`, `game/autoloads/events.gd`, `game/audio/sfx/sfx_lucidity_tier_{down,up}.wav`, `game/ui/hud/lucidity_gauge.gd`, `game/ui/hud/hud.gd`, `game/localization/strings.csv`, `game/debug/{debug_panel,perf_overlay}.gd`, `game/telemetry/{telemetry,telemetry_session}.gd`, `game/.scratch/t_lucidity.*` (non versionné).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Aucun bonus de lucidité appliqué en 3.1** (dégâts, précision) — Raison : le CA ne porte que sur la jauge, les paliers et leur annonce ; les effets sont 3.5.
2. **`LucidityTuning` donne le plancher de chaque palier** (76, 51, 26, 1, 0) et le maximum (100) — Raison : les limites du GDD restent des données ; le palier d'une valeur se déduit d'un parcours.
3. **Relais sur le bus : `lucidity_value_changed(value)` en plus de `lucidity_tier_changed`** — Raison : le HUD n'écoute que `Events` (règle 2.7) et ne peut pas se brancher sur l'objet `Lucidity` ; l'AC « `value_changed` » est tenu par le signal de l'objet, relayé tel quel.
4. **Deux sons de palier (descente, montée)**, sons provisoires générés par script ; pas de son à la création — Raison : le GDD dit « un son marque chaque changement de palier » ; deux timbres rendent le sens lisible, remplacés par 7.7.
5. **Étiquette du nom du palier à droite de la jauge** — Raison : « annonce chaque changement de palier » ; la couleur seule ne suffit pas (accessibilité, FR67) ; pas d'effet plein écran (photosensibilité).
6. **Touche F1 `L` : cycle de 5 valeurs (100, 75, 50, 25, 0)** — Raison : touches 1 à 9, 0 et `-` prises ; une valeur par palier suffit au debug, les bords sont vérifiés en scène.
7. **Temps par palier en temps réel de session, pauses comptées** — Raison : cohérent avec la durée de jeu de 2.8 (décision 5) ; la précision d'une pause n'altère pas l'indicateur « temps sous Lucide » à l'échelle d'un playtest.
8. **`gain(amount)` sans paramètre `source` ni plafond de graze** — Raison : ils arrivent en 3.2 ; ajouter la source maintenant serait une signature spéculative.
9. **(Revue de code) Signature `Events.lucidity_value_changed(value, tier)` gardée, le CA3 est à lire ainsi** — Question : le CA3 dit `(value)`, le code envoie `(value, tier)`. Choix : garder le code. Raison : le HUD n'écoute que `Events` et a besoin du palier sans lire le jeu ; l'architecture ne fixe pas cette signature.
10. **(Revue de code) « Fin de partie » du CA6 = la mort** — Question : la ligne INFO « time per tier » n'est écrite qu'à la mort ; une relance F1 ou une sortie en pleine partie ne laisse que l'événement `run_end` dans le JSON. Choix : accepté pour 3.1, l'issue de partie est reportée à 6.4. Raison : la mort est aujourd'hui la seule vraie fin de partie ; relance F1 et sortie sont des cas de debug ou d'abandon.
11. **(Revue de code) Palier de départ de la télémétrie : Lucide** — Question : la télémétrie suppose le palier 0 au début de chaque partie au lieu de lire le palier réel. Choix : reporté à 3.6. Raison : c'est voulu par la spec (« joueur neuf ») et vrai avec le tuning actuel ; le début de salle (3.6) revoit le début de partie.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Completion Notes

- `Lucidity` (pur, `player/lucidity.gd`) : valeur 0..100, `live_tier`, `gain()`, `set_value()`, signaux `value_changed` / `tier_changed` émis après mise à jour des deux champs. Paliers dans `LucidityTuning` (`max_value`, `tier_floors`). Le joueur le crée et relaie : `Events.lucidity_value_changed(value, tier)` (état initial compris) et `Events.lucidity_tier_changed(tier, previous)` avec un son (descente ou montée) et une ligne INFO `lucidity`.
- HUD : `LucidityGauge` (dessin en code) posée sur le cadre réservé, remplissage proportionnel, couleur par palier, 3 repères, flash de 0,3 s au changement de palier ; nom du palier à droite (`UI_LUCIDITY_*`). Le slot reste vide, le HUD n'écoute que `Events`.
- F1 `L` cycle 100/75/50/25/0 par `lucidity.set_value()` ; F3 ligne « Lucidity n (TIER) » (zone du libellé agrandie).
- Télémétrie : `TelemetrySession.tier_changed/run_ended`, événement `run_end` avec les secondes par palier, `summary.tier_seconds` ; ligne INFO `lucidity` à chaque fin de partie. `t_telemetry` adaptée : son helper ignore les événements `run_end`.
- Vérifié : `t_lucidity` 30 contrôles (bornes des 9 valeurs limites, plafond et plancher, signaux, relais bus, son, HUD, F1, F3, télémétrie pure et dans le jeu, nouvelle partie à 100) ; `run_all.sh` normal : 789 contrôles, toutes les scènes PASS (seul `t_lucidity` avait un avertissement de fuite à la sortie, corrigé en laissant finir le son) ; `--quit-after 120` propre.
- **NON ÉVALUÉ** (humain) : lisibilité de la jauge de 160×8 px et des couleurs de palier à l'échelle réelle, audibilité et distinction des deux sons de palier, utilité de l'étiquette. Voir `deferred-work.md`.

### File List

- `game/core/lucidity_tuning.gd` (+ `.uid`), `game/data/tuning/lucidity_tuning.tres`, `game/player/lucidity.gd` (+ `.uid`), `game/ui/hud/lucidity_gauge.gd` (+ `.uid`), `game/audio/sfx/sfx_lucidity_tier_{down,up}.wav` (+ `.import`) (NEW)
- `game/core/tuning.gd`, `game/autoloads/events.gd`, `game/player/player.gd`, `game/ui/hud/hud.gd`, `game/localization/strings.csv`, `game/debug/debug_panel.gd`, `game/debug/perf_overlay.{gd,tscn}`, `game/telemetry/telemetry.gd`, `game/telemetry/telemetry_session.gd` (UPDATE)
- ce fichier, `sprint-status.yaml`, `deferred-work.md` (UPDATE) ; `game/.scratch/t_lucidity.*`, `t_telemetry.gd`, `run_all.sh` (non versionnés)
