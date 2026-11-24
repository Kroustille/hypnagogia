# Story 6.7 : Garder la trace de ses victoires

Status: ready-for-dev

## Story

En tant que joueur,
je veux que mes premières victoires et mes succès soient enregistrés,
afin que les déblocages de l'acte 1 puissent s'y brancher.

Exigences : FR65, AR18 (`profile.json`), AR29 (`seeded`) (epics.md, Story 6.7). Architecture : D12 (`profile.json` versionné, écriture atomique), « Persistance des données » (migration par version, fichier illisible renommé en `.corrupt`), `progression/` (`profile.gd`, `achievements.gd`, `unlocks.gd`), pas de `.tres`/`.res` pour la sauvegarde.

**Dépend de : 6.4** (`boss_defeated`, issues), **6.6** (`wake_time_set`, `last_wake_minute`), 5.7 (synergies), 3.5 (paliers), 4.11 (`run_seeded`, `RunState.seeded`). **Prépare 6.8** : `SaveService` (lecture/écriture JSON atomique, quarantaine `.corrupt`) est créé ici et réutilisé tel quel par `run.json`.

Hors périmètre : déblocages réels (rien n'est débloqué au MVP), couches de mystère, journal de rêves (jalon C), `run.json` (6.8).

## Critères d'acceptation

1. **`SaveService`** (autoload `autoloads/save_service.gd`, aujourd'hui vide) : `write_json(path, dict) -> bool` (écrit `<path>.tmp` puis renomme, comme `Settings._save`), `read_json(path) -> Variant` (`Dictionary` ou `null`), quarantaine d'un fichier illisible (`<path>.corrupt`), dossier de données **injectable** (`SaveService.set_directory(dir)`, défaut `user://`) pour les tests. Aucun `.tres` ni `.res` sauvegardé.
2. **`profile.json`** porte `schema_version` (entier, 1 aujourd'hui) ; `Profile.from_dict()` passe par `migrate(data)` : **une fonction de migration par version** (`_migrate_1_to_2`, … table de `Callable`, vide aujourd'hui, testée avec une version factice) ; une version **plus récente** que le jeu est illisible (renommée, jamais écrasée en silence).
3. **Fichier illisible** (JSON invalide, racine non dictionnaire, `schema_version` absent ou non entier, version future) : `profile.json` est renommé en `profile.json.corrupt` (un `.corrupt` plus ancien est remplacé), le jeu démarre avec un profil neuf, et un **message localisé** (`UI_PROFILE_CORRUPT`) prévient le joueur au démarrage (étiquette `Notice` dans la couche UI de `Main`, quelques secondes). Fichier absent : profil neuf sans message.
4. **Contenu du profil** : `stats` (`runs`, `victories`, `deaths`, `last_wake_minute`), `first_victories` (id de cauchemar → statistiques de la run : seed, durée, objets, heure du réveil, date) et `achievements` (id de succès → mêmes champs), `unlocks: Array[StringName]` (**vide au MVP**).
5. **`progression/achievements.gd`**, nœud ajouté par `Main` (pas un autoload), écoute `Events` seulement : `boss_defeated(&"professor")` pour la première fois → `first_victories[professor]` ; une salle vidée avec `lowest_tier == TOTAL_ABANDON` pour la première fois → succès `total_abandon_room` ; une synergie à 3 objets (`Events.synergy_activated(id, threshold)` avec seuil ≥ 3, nouveauté de cette story : émise par `BuildCarrier` pour le joueur seulement) pour la première fois → succès `synergy_three`. Chaque obtention écrit `profile.json` aussitôt ; une obtention déjà enregistrée ne change rien (« une seule couche à la première fois »). **Rien n'est débloqué** : `unlocks` reste vide.
6. **Seed saisie** : une run `seeded` (`Events.run_seeded(code, true)`) n'enregistre **aucune** victoire, aucun succès et ni les statistiques du profil ni `last_wake_minute` (AR29) ; l'heure du réveil reste gardée en mémoire par `Main` pour la chambre.
7. **Fin de run** (non seedée) : `stats.runs` +1 ; `deaths` ou `victories` +1 selon l'issue ; `last_wake_minute` mis à jour avec `Events.wake_time_set` ; écriture du profil (une fois, après `run_ended`). Une run perdue ne conserve rien d'autre (objets, Éclats, état de la run) : seul le profil persiste.
8. **Reprise de l'heure** : au lancement, `Main` lit `last_wake_minute` du profil et le donne à la chambre (6.6) ; sans profil, le réveil marque 23:00.
9. **Déblocages dans le pool de salles** : `Run.ensure_floor()` passe `RunOptions.unlocks` (copie de `profile.unlocks`, rempli par `Main`) à `RoomCatalog.pool(dir, unlocks)` (le filtre `requires_unlock` existe, appelé sans liste jusqu'ici). Vide au MVP, donc sans effet visible.

## Tâches

- [ ] `autoloads/save_service.gd` ; `progression/profile.gd` (`RefCounted`, `to_dict()`, `static from_dict()`, `migrate()`), `achievements.gd`, `unlocks.gd` (liste vide + `is_unlocked(id)`).
- [ ] `ui/notice.gd` (`Control` simple, libellé qui s'efface, texte par `tr()`), ajouté par `Main` ; `strings.csv` : `UI_PROFILE_CORRUPT`.
- [ ] `autoloads/events.gd` : `synergy_activated(synergy_id: StringName, threshold: int)` ; `items/build_carrier.gd` : l'émet dans `_on_synergy_activated` **si l'hôte est le joueur** (le reflet du Miroir n'en émet jamais).
- [ ] `main/main.gd` : charge le profil à `_ready()`, instancie `Achievements`, lit `last_wake_minute`, `unlocks` dans `RunOptions` ; écrit le profil à `run_ended`.
- [ ] `run/run_options.gd` : `unlocks: Array[StringName]` ; `run/run.gd` : `RoomCatalog.pool(def.pool_dir, _options.unlocks)`.
- [ ] Tests.

## État du code concerné

- `SaveService` : `extends Node` et un commentaire, aucune fonction ; déjà déclaré en autoload.
- `Settings._save()` : écriture atomique `ConfigFile` (`.tmp` puis `DirAccess.rename_absolute`), commentaire « Private until story 6.8 needs the same » ; `Settings.load_from()` renomme un fichier illisible en `.corrupt` mais **n'écrase pas** un `.corrupt` existant (à copier le comportement, pas à partager le code ; `Settings` n'est pas refactoré ici).
- `Telemetry._write()` écrit un `.tmp` via `FileAccess` : même patron.
- Événements disponibles : `boss_defeated` (6.4), `room_cleared(room, lowest_tier)` (`Lucidity.Tier.TOTAL_ABANDON = 4`), `run_seeded`, `run_started`, `item_acquired`, `run_ended`, `wake_time_set` (6.6). Aucun événement de synergie sur le bus avant cette story (`TagTracker.synergy_activated` est local au porteur).
- `RoomCatalog.pool(dir, unlocks)` filtre `requires_unlock` ; `FloorGenerator` ne filtre pas (deferred) ; `Run.ensure_floor()` appelle `pool(def.pool_dir)`.
- 6.8 réutilise `SaveService.write_json/read_json` et ajoute `write_run`, `read_run`, `delete_run`, `has_run`.

## Pièges

- **JSON et entiers** : `JSON.parse_string` rend les nombres en `float` ; convertir avec `int()` à la lecture (`schema_version`, compteurs, minutes). `JSON.stringify` ne gère ni `StringName` en clé de dictionnaire typé ni `Vector2i` : tout passe en `String`/tableaux avant l'écriture.
- Écriture : ouvrir avec `FileAccess.open(tmp, WRITE)`, tester `null` (`FileAccess.get_open_error()`), `store_string`, **`close()`** puis `DirAccess.rename_absolute` ; sous Windows le renommage supprime la cible d'abord (fenêtre non atomique, signalée dans `Settings`).
- Une lecture impossible parce que le fichier est verrouillé (antivirus, synchro) n'est **pas** une corruption : ne pas renommer, profil neuf pour la session, ne pas écraser le fichier existant à la fin de la run (`_loaded_ok = false` : n'écrire qu'après une lecture réussie ou un fichier absent).
- Un test qui écrit dans le vrai `user://` salirait le profil du joueur : toujours `SaveService.set_directory()` vers un dossier temporaire ; `tools/run_tests.sh` isole déjà `XDG_DATA_HOME`.
- `Achievements` reçoit des événements d'une run **détruite** ou d'une scène de test : il remet son état (seeded, objets, début) à `run_started`.
- `boss_defeated` arrive avant `run_ended` (délai de victoire de 6.4) : l'enregistrement de la première victoire se fait à `boss_defeated`, l'heure du réveil est ajoutée à `wake_time_set` pour la même run (mise à jour de l'entrée, pas un second enregistrement).
- Les clés de succès sont des identifiants (`StringName`), pas du texte du joueur ; les noms affichés viendraient de `strings.csv` quand un journal existera.

## Tests (GUT)

- `unit/save/test_save_service` : écriture puis relecture identiques ; pas de `.tmp` restant ; fichier illisible renommé, un ancien `.corrupt` remplacé ; fichier absent = `null` sans quarantaine ; dossier injecté.
- `unit/progression/test_profile` : aller-retour `to_dict`/`from_dict` après `JSON.stringify` + `parse_string` (entiers, minutes, tableaux) ; migration factice 1→2 ; version future refusée ; `schema_version` absent refusé.
- `integration/progression/test_achievements` : premier boss battu : `profile.json` écrit avec seed et objets ; un second ne change rien ; salle vidée à Abandon total, synergie à 3 objets (reflet exclu), une seule fois chacun ; run seedée : aucun fichier modifié ; mort : `runs`/`deaths`/`last_wake_minute` mis à jour, pas d'autre contenu ; `unlocks` reste vide.
- `integration/progression/test_corrupt_profile` : fichier cassé au démarrage : `.corrupt` présent, profil neuf, message affiché, jeu jouable.
- `unit/generation/test_pool_unlocks` : `RoomCatalog.pool(dir, [&"x"])` inclut une salle `requires_unlock = &"x"`, `pool(dir, [])` l'exclut (déjà couvert ? sinon compléter).

## Sources

epics.md (Story 6.7) ; GDD, Ce qui persiste, Déblocages, Le mystère (chaque première victoire, une seule couche) ; architecture D12, « Persistance des données », `progression/` ; deferred-work (`requires_unlock`, `SaveService`).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **`SaveService` créé ici (6.7), pas en 6.8** : `profile.json` vient avant `run.json` dans l'ordre des stories, et les deux ont besoin de la même écriture atomique.
2. **`Settings` n'est pas refactoré** pour utiliser `SaveService` (format `ConfigFile` différent, déjà testé). Deux écrivains atomiques coexistent.
3. **Les succès du MVP** : `professor` (première victoire), `total_abandon_room`, `synergy_three`. Les deux derniers sont les exemples de l'epic et du GDD ; la liste complète est ouverte pour l'acte 1.
4. **Une run seedée n'écrit rien dans le profil**, statistiques comprises (l'AC parle de victoire et de succès ; lire plus largement évite qu'une seed partagée gonfle `victories`/`runs`). Le joueur voit tout de même l'heure en mémoire.
5. **Écriture à chaque obtention et à chaque fin de run** (GDD/architecture), pas seulement à la fermeture.
6. **Fichier verrouillé ≠ corrompu** : pas de quarantaine, pas d'écrasement.
7. **`Events.synergy_activated(id, threshold)` ajouté**, émis par `BuildCarrier` du joueur seulement. L'AC dit « une synergie à 3 objets » : seuil ≥ 3 (`fall_3`).
8. **Message de corruption = `Notice` de quelques secondes**, pas une fenêtre modale (le jeu ne s'arrête jamais sur une erreur, architecture).

## Dev Agent Record

### Notes de complétion

### Liste des fichiers

### Journal des modifications
