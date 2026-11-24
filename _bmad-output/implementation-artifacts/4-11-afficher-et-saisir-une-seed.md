# Story 4.11 : Afficher et saisir une seed

Status: ready-for-dev

## Story

En tant que joueur,
je veux voir la seed de ma run et pouvoir en saisir une,
afin de rejouer ou de partager une run.

Exigences : FR43 (affichage et saisie), AR24 (F1), AR27 (seed journalisée), AR29 (`seeded`) (epics.md, Story 4.11). GDD : seed affichée à la mort et dans le menu pause, saisissable avant une run ; une run avec seed saisie ne débloque rien et ne fait pas avancer le mystère. Architecture : `ui/menus/seed_entry`, `RunState.seeded`.

**Dépend de : 4.7** (`RunRng` 8 caractères, `RunState`, `RunOptions` avec seed), **4.8** (étage jouable, `Main` relance par `RunOptions`) ; indépendante de 4.9 et 4.10 (mais le test de bout en bout suppose le pool réel de 4.10 ou le pool minimal de 4.7).

Hors périmètre : écran-titre (il n'y en a pas : la chambre est à l'epic 8), déblocages réels (`progression/`, epic 8 : seul l'indicateur `seeded` est posé), saisie à la manette (voir décisions), partage par QR ou presse-papiers automatique.

## Critères d'acceptation

1. **Affichage** : le code de seed de 8 caractères (`RunRng.seed_code()`, majuscules Crockford, sans séparateur) s'affiche dans le **menu de pause** et sur l'**écran de réveil** (mort), sous le titre, avec un libellé localisé (`UI_PAUSE_SEED` / `UI_WAKE_SEED`, « Seed : %s »). La valeur affichée est celle de la `Run` en cours ou qui vient de finir.
2. **Saisie** : un bouton « Nouvelle partie avec une seed » (`UI_SEED_NEW_GAME`) dans le menu de pause **et** sur l'écran de réveil ouvre une fenêtre de saisie (`ui/menus/seed_entry.tscn`) : un champ de texte (`LineEdit`, 8 caractères utiles, focus automatique), Entrée valide, Échap annule. L'entrée est **normalisée** : majuscules, espaces et tirets ignorés, `I`/`L` lus comme `1`, `O` comme `0` (déjà le cas de `RunRng.code_to_seed`, qui apprend à ignorer espaces et tirets).
3. **Code valide** : fermeture de la fenêtre, de la pause ou du réveil, et une nouvelle `Run` démarre sur cette seed (même étage qu'à la première fois pour les mêmes déblocages, à pool égal) avec `RunState.seeded = true`. Une run lancée sans saisie a `seeded = false`.
4. **Code invalide** (longueur ≠ 8, caractère hors alphabet) : refusé avec un message localisé (`UI_SEED_INVALID`), la fenêtre reste ouverte, le champ reste sélectionné, **aucune run lancée**, aucun changement d'état de la partie en cours (pause et réveil intacts).
5. **Journal** : à chaque départ de run, `Log.info("run", "run started seed=XXXXXXXX seeded=<bool>")` (remplace les deux lignes `seed ...` puis `run started` ; le contrôle `run_all.sh` reconnaît toujours `run started`). **Télémétrie** : l'enregistrement de la run contient la seed et `seeded` (nouveau signal de bus `Events.run_seeded(seed_code, seeded)`, émis juste après `run_started`, sans changer la signature de `run_started`) ; la télémétrie existante (`t_telemetry`) passe sans modification.
6. **`seeded` coupe les déblocages** : `RunState.seeded` est lisible par `Run.state`, jamais remis à faux dans la run ; `progression/` n'existe pas encore : un test d'intégration vérifie le drapeau ; l'epic 8 s'y branche. Les récompenses de run (objets, éclats, drops) ne changent pas.
7. **Panneau F1** (debug) : une commande « relancer avec la seed courante » et une commande « relancer avec le code du presse-papiers » (`DisplayServer.clipboard_get()` passé à `RunRng.code_to_seed`), toutes deux par `Events.run_requested(FLOOR, seed, true, "")` ; le message du panneau dit si le code est invalide. Les commandes appellent les mêmes méthodes publiques que le jeu.
8. **Reproductibilité de bout en bout** (test versionné) : deux `Run` créées avec le même code ont le même `FloorLayout.signature()` et la même salle de départ ; deux seeds différentes ont des signatures différentes.

## Tâches

- [ ] `RunRng.code_to_seed` : ignorer espaces et tirets ; test de non-régression des codes de la 4.1.
- [ ] `ui/menus/seed_entry.gd/.tscn` : `Control` plein écran sous les menus, champ, bouton valider/annuler, message d'erreur (`Label`), signaux `seed_submitted(seed_value)` et `cancelled`. Textes dans `strings.csv` : `UI_PAUSE_SEED`, `UI_WAKE_SEED`, `UI_SEED_NEW_GAME`, `UI_SEED_PROMPT`, `UI_SEED_INVALID`, `UI_SEED_CONFIRM`, `UI_SEED_CANCEL`.
- [ ] `PauseMenu` et `WakeScreen` : libellé de seed + bouton ; `Main` lui donne le code (`open(seed_code)`), relaie `seed_submitted` en `Events.run_requested(FLOOR, seed, true, "")`, dégèle (`_freeze(false)`) avant `_start_run(options)` (le seul endroit qui gèle ou dégèle).
- [ ] `Run` : un seul journal de départ (`run started seed=... seeded=...`), `Events.run_seeded`, `Telemetry` enregistre `seed` et `seeded` dans le bloc de la run.
- [ ] F1 : deux commandes ; pas de nouvelle touche conflictuelle (voir la liste des touches du panneau).
- [ ] Tests GUT : `tests/unit/core/test_run_rng.gd` (normalisation étendue), `tests/unit/ui/test_seed_entry.gd` (code valide émet, invalide refuse sans émettre, message), `tests/integration/run/test_seed_flow.gd` (pause affiche le code ; mort affiche le code ; saisie valide relance et `seeded` ; invalide ne relance pas ; même seed même étage), `tests/integration/telemetry/test_run_seed_record.gd`.
- [ ] Mettre à jour `deferred-work.md` ? **Non** : ce fichier est à la charge de la revue ; noter dans « Pièges rencontrés » ce que cette story laisse (saisie à la manette).
- [ ] `run_all.sh` du `.scratch` ; `--quit-after 120` propre.

## État du code concerné

- `Run._ready` : `rng = RunRng.new(RunRng.draw_seed())`, journal `seed %s` puis `run started`, `Events.run_started`. Après 4.7 : `Run.setup(options)` reçoit la seed (−1 = tirage) ; `RunState` porte `run_seed`, `seeded`, `floor_index`.
- `Main._on_wake_screen_restart_requested()` → `_start_run()` ; `_set_paused()` ouvre `PauseMenu` ; les menus sont des `Control` ajoutés en fin de `UI` (réveil, pause, réglages) ; `PauseMenu._unhandled_input` ferme sur `ui_cancel`. `WakeScreen` garde le focus sur le bouton « Se rendormir » et désactive les réponses après un verdict.
- `Events.run_requested(mode, seed_value, seeded, room_path)` (4.2) : déjà le seul chemin de relance, F1 compris.
- `Telemetry` (autoload) écoute `Events` seulement ; `telemetry_session.gd` écrit un journal JSON par session avec un bloc par run.
- Le code de seed est affiché brut : 8 caractères base32 sans séparateur (décision de la 3.7).

## Pièges

- Le champ de texte consomme les frappes : tant qu'il a le focus, les actions de jeu (`restart`, `pause`, `dash`) ne doivent pas se déclencher ; une fenêtre ajoutée **après** les menus dans `UI` reçoit l'entrée avant eux, et doit appeler `set_input_as_handled()` sur Échap pour que `PauseMenu` ne ferme pas la pause en dessous.
- `restart` (clavier) à l'écran de réveil : si sa touche est une lettre, elle ne doit pas relancer pendant la saisie (le `LineEdit` capte avant `_unhandled_input`, à vérifier avec un test d'entrée simulée).
- `Input.parse_input_event()` s'applique au tick suivant : attendre un tick après une frappe simulée.
- La seed saisie est un entier de 40 bits : `RunRng._init` masque à 40 bits ; `code_to_seed` renvoie −1 pour invalide, jamais 0 par défaut (0 est une seed valide `00000000`).
- Dégeler avant de créer la nouvelle `Run` (`_start_run` le fait) ; ne pas laisser la fenêtre de saisie vivre dans la `Run` détruite : elle est dans `UI`, persistante.
- Le mode ARENA ou ROOM (F1) n'a pas de seed d'étage : afficher tout de même la seed de la `Run` ; `seeded` y est vrai seulement si demandé.
- Lecture du presse-papiers en headless : vide ; les tests passent le code par la méthode publique, pas par le presse-papiers.

## Fichiers prévus

`core/run_rng.gd`, `run/run.gd`, `run/run_state.gd`, `autoloads/events.gd`, `main/main.gd`, `ui/menus/{pause_menu,wake_screen}.gd/.tscn`, `ui/menus/seed_entry.gd/.tscn`, `localization/strings.csv`, `telemetry/{telemetry,telemetry_session}.gd`, `debug/debug_panel.gd`, `tests/**`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Saisie au clavier seulement** (champ de texte, collage possible) : la sélection caractère par caractère à la manette viendra avec les menus manette de l'epic 7 ; un joueur manette peut relancer sur la seed courante mais pas en saisir une. NON VÉRIFIÉ, à noter dans `deferred-work.md` par la revue.
2. **Pas de séparateur dans l'affichage** (« XXXXXXXX ») ; tirets et espaces tolérés en saisie.
3. **Un seul journal de départ** `run started seed=… seeded=…` (fusionne les deux lignes actuelles) ; clôt la remarque de `deferred-work.md` sur la seed absente de « run started ».
4. **`Events.run_seeded`** séparé de `run_started` pour ne pas casser les écouteurs existants.
5. **« Nouvelle partie avec une seed » aussi à l'écran de réveil**, comme le GDD (« saisissable avant une run », « affichée à la mort ») ; pas d'écran-titre.
6. **`seeded` ne bloque que les déblocages** (indicateur pour l'epic 8) ; une seed saisie reste rejouable à l'identique à déblocages égaux.
7. **Commandes F1 : seed courante et presse-papiers**, pas de champ de saisie dans le panneau (le panneau n'a que des touches).

## Dev Agent Record

### Agent Model Used

### Completion Notes

### File List
