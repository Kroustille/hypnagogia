# Story 4.1 : Tester la logique du jeu sans le lancer

Status: ready-for-dev

## Story

En tant que développeur,
je veux un framework de test et des tests sur les classes de logique pure,
afin que le jalon B s'appuie sur une base vérifiée, et que le test des 10 seeds soit possible.

Exigences : AR26 (epics.md, Story 4.1). Architecture : « Tests » des compléments (D8, classes `RefCounted` sans scène), arborescence `game/tests/{unit,integration}`, `game/addons/`, `tools/`.

**Dépend de : rien** (jalon A validé). Toutes les stories 4.2 à 4.11 ajoutent leurs tests versionnés dans ce framework (voir « Contrat de test de l'epic »).

Hors périmètre : réécrire les scènes jetables de `game/.scratch` (elles restent, non versionnées, et continuent de passer via `run_all.sh`) ; tests d'intégration lourds (ils arrivent avec 4.2) ; CI.

## Critères d'acceptation

1. **Choix** : le framework est **GUT** (version compatible Godot 4.7, vérifier la dernière release sur GitHub `bitwes/Gut`), installé dans `game/addons/gut/` et versionné. Repli documenté dans la story si GUT ne tourne pas en 4.7 : GdUnit4. Le choix et la version sont notés dans le Dev Agent Record (c'est le résultat de `gds-test-framework`).
2. **Dossiers** : `game/tests/unit/` et `game/tests/integration/`, en miroir des dossiers de code (`tests/unit/player/test_lucidity.gd` pour `player/lucidity.gd`) ; `game/tests/support/` pour les aides communes. Config `game/.gutconfig.json` (dossiers, sous-dossiers inclus, préfixe `test_`, sortie en code d'erreur).
3. **Commande** : `tools/run_tests.sh [chemin ou filtre]` importe le projet, lance toute la suite en headless depuis WSL avec `godot` 4.7.2 du PATH, affiche un résumé, et rend un code de sortie non nul au moindre échec ou à une erreur de script (`SCRIPT ERROR`, `Parse Error`). Sans argument : tout. Elle ne dépend d'aucun fichier de `game/.scratch`.
4. **Lucidity** (`tests/unit/player/test_lucidity.gd`) : bornes (jamais sous 0, jamais au-dessus du maximum), paliers (`tier_for` aux seuils exacts et un point de part et d'autre), plafond de graze par salle (+20, remis à zéro par `begin_room()`), `try_spend` (refus si valeur insuffisante, valeur inchangée au refus, signal émis à l'acceptation), `room_tier` (le plus bas atteint depuis `begin_room()`, ne remonte pas dans la salle).
5. **StatBlock** (`tests/unit/core/test_stat_block.gd`) : cumul additif des `ADD_PERCENT` (deux sources à +30 % donnent ×1,6, pas ×1,69), ordre `ADD_FLAT` puis pourcentage puis `MULTIPLY`, un modificateur par source et par stat, `clear_source`, signal `changed` seulement sur variation réelle.
6. **RunRng** (`tests/unit/core/test_run_rng.gd`) : même seed et même flux donnent la même suite ; deux flux d'une même seed diffèrent ; l'étage change la suite ; `seed_code()` fait 8 caractères et `code_to_seed()` l'inverse (aller-retour sur au moins 50 seeds ; I, L, O tolérés ; code invalide refusé avec -1).
7. **Aucun test creux** : chaque test affirme quelque chose qui peut échouer ; aucun `assert_true(true)`.
8. **Propreté** : zéro `SCRIPT ERROR`, zéro `Parse Error`, aucun avertissement nouveau au lancement normal (`--quit-after 120`) ; `run_all.sh` du `.scratch` passe toujours (rien n'y est touché).

## Tâches

- [ ] **Spike d'abord** (15 min) : GUT installé, un test trivial, lancé en ligne de commande. Le brief du pipeline indique que `--script` ne résout pas les autoloads : essayer `godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit`. Si `Log` ou `Events` ne se résolvent pas dans les classes testées, lancer GUT depuis une scène (`game/tests/runner.tscn` qui instancie le lanceur de GUT, `--scene res://tests/runner.tscn`), comme les scènes `.scratch`. Garder la voie qui marche, noter l'autre dans « Pièges rencontrés ».
- [ ] Récupérer GUT (archive de release, dans un dossier vide hors du dépôt, décompresser, copier seulement `addons/gut/`). Ne pas activer le plugin dans `project.godot` si la ligne de commande n'en a pas besoin (moins de diff dans la config du projet).
- [ ] `game/.gutconfig.json`, `tools/run_tests.sh` (bash, `set -u`, code de sortie propagé, filtre optionnel `-gselect=`), lisible depuis la racine du dépôt (`cd "$(dirname "$0")/.."`).
- [ ] `tests/support/` : rien d'obligatoire ici ; ne créer l'aide `room_harness.gd` (instancie `Run`, attend des ticks physiques) qu'avec la 4.2, qui en a besoin.
- [ ] Écrire les trois fichiers de test (critères 4 à 6). Lire `player/lucidity.gd`, `core/stat_block.gd`, `core/run_rng.gd` et `core/lucidity_tuning.gd` pour viser les vraies bornes ; construire `Lucidity.new(Tuning.LUCIDITY)` ou une `LucidityTuning` locale (jamais de valeur du GDD recopiée en dur : lire le tuning).
- [ ] Relier au code : `.gitignore` n'ignore pas `game/addons/` ni `game/tests/` ; `CLAUDE.md` n'est pas modifié (le fichier est à la racine, hors périmètre de la story).
- [ ] Documenter dans la story (Pièges rencontrés) la commande exacte, le temps de la suite, et quels contrôles de `.scratch` couvrent encore ce que les tests ne couvrent pas.

## Rapport entre `.scratch` et le framework

`game/.scratch` reste le terrain des vérifications jetables (non versionné, `run_all.sh`). **On ne porte pas ces scènes** : on écrit, par story, les tests versionnés de ce que la story ajoute. Les seules reprises, dans les stories suivantes, sont (a) l'idée du harnais à ticks `th.gd` (`await ticks(n)`) refaite proprement en `tests/support/` à la 4.2, (b) les règles de lisibilité du code (`Timer`, RNG global, `print`) : à réécrire en test versionné `tests/unit/test_code_rules.gd` par la 4.7 (qui interdit le RNG global dans `generation/`). Le reste (`t_sleepwalker`, `t_waves`...) vit et meurt dans `.scratch`.

## État du code concerné

- Aucun framework : `game/addons/` n'existe pas, `tools/` est vide (la 4.2 y met `validate_rooms.sh`).
- Les classes pures déjà testables : `Lucidity` (`RefCounted`, `_init(tuning)`, `gain`, `try_spend(cost, power)`, `begin_room`, `set_value`, `tier_for`, `live_tier`, `room_tier`), `StatBlock`, `RunRng`, `PlayerMotor`, `Glide.distance_for`. `Lucidity` peut émettre des signaux : les connecter dans le test.
- `run_rng.gd` : graine de 40 bits, 8 caractères base32 Crockford ; la story 4.7 ajoute `FloorGenerator` qui ne se testera que par ce framework.
- Avertissements en erreur (`untyped_declaration`, `unsafe_*`) : les tests sont typés comme le reste du code.

## Pièges

- GUT et les avertissements du projet : `debug/gdscript/warnings/exclude_addons` (vrai par défaut) doit rester actif, sinon le code de GUT, non typé, devient une erreur. Vérifier après l'import.
- Importer avant de lancer (`godot --headless --path game --import`) : un `class_name` ajouté n'est connu qu'après import, un nouveau test ne se trouve pas sinon.
- `Log.error` + `assert(false)` : un test qui provoque volontairement une entrée invalide (non prévu ici) afficherait des `SCRIPT ERROR` : ne pas en écrire sans plan (le script de sortie traite `SCRIPT ERROR` comme un échec).
- Le code de sortie de GUT en headless : vérifier à la main avec un test qui échoue volontairement une fois (puis le retirer) que `run_tests.sh` rend bien un code non nul.
- WSL : pas de `python3` ; le script reste en bash.

## Vérifications prévues

- La suite passe (`tools/run_tests.sh`), et un échec volontaire passager fait échouer la commande (une fois, non versionné).
- Chaque test de `Lucidity`, `StatBlock`, `RunRng` échoue si on casse la règle correspondante (contrôle à la main sur deux règles de son choix).
- `godot --headless --path game --quit-after 120` propre ; `bash game/.scratch/run_all.sh` passe encore.

## Fichiers prévus

`game/addons/gut/**`, `game/.gutconfig.json`, `game/tests/unit/player/test_lucidity.gd`, `game/tests/unit/core/test_stat_block.gd`, `game/tests/unit/core/test_run_rng.gd`, `tools/run_tests.sh` (+ éventuellement `game/tests/runner.tscn`/`.gd`).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **GUT plutôt que GdUnit4.** Un seul dossier d'addon, tests en simples scripts `GutTest`, pas de dépendance à l'éditeur ; GdUnit4 n'est qu'un repli. Choix réversible tant que les tests sont peu nombreux.
2. **Contrat de test de l'epic.** Chaque story 4.x livre ses tests versionnés (`tests/unit` pour la logique pure, `tests/integration` pour ce qui demande des nœuds) en plus de ses éventuelles vérifications `.scratch`. Les anciennes scènes `.scratch` ne sont pas portées.
3. **Test de `RunRng` ajouté** (le texte de l'epic ne cite que `Lucidity` et `StatBlock`) : AR26 liste `RunRng` et la 4.7 repose dessus.
4. **Plugin non activé** dans `project.godot` si la ligne de commande suffit : le diff de config du projet reste minimal.

## Dev Agent Record

### Agent Model Used

### Completion Notes

### File List
