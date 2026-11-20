# Journal de décisions : GDD Hypnagogia

## 2026-11-20 — Ouverture

- **Intention** : création (Create) du GDD.
- **Sources** : brief final (`briefs/brief-hypnagogia-2026-11-20/brief.md`, `addendum.md`, `.decision-log.md`), brainstorm, stress test.
- **Langue du document** : français (CLAUDE.md et config résolue ; `_bmad/gds/config.yaml` indique encore English, ignoré).
- **Type de jeu proposé** : roguelike (complexité élevée), avec les sous-sections du guide shooter pour le combat twin-stick (armes, ennemis, arènes). En attente de confirmation.

## 2026-11-20 — Pré-remplissage depuis le brief

Repris tels quels du brief final : résumé et vision, public, arguments uniques, objectifs et jalons A à D, contexte et références, 4 piliers avec leurs interdits et les règles non négociables, direction artistique et audio, plateforme, hors périmètre.

**Trous identifiés à traiter dans le GDD** :
- Chiffres absents : jauge de lucidité (taille, coûts, gains, bornes à 0 et au maximum), dash, cadence, santé de départ et plafond.
- Victoire de run, nombre d'étages par run, place du choix de porte.
- Seeds : jamais mentionnées. C'est une convention du genre qui doit être tranchée.
- Économie (monnaie, clés, bombes, boutiques), types de salles spéciales.
- Pactes : coût en lucidité et malédiction, ou l'un des deux ; refuser tous les pactes.
- Liste d'ennemis, lien entre étages et boss.
- Sauvegarde en pleine run, résolution et taille des sprites.

**Abandons silencieux possibles à soumettre au designer** : fragments de souvenirs, réveil qui affiche l'heure de la mort, mécaniques propres à chaque phase (dont une gravité plus forte en Sommeil profond, à confronter à « tirs sans gravité »), sens de la lucidité aux actes 2 et 3, chambre clinique, les 4 fins nommées, armure.

## 2026-11-20 — Type de jeu et mode

- **Type** : roguelike, avec les sous-sections armes, ennemis et arènes du guide shooter. Confirmé.
- **Mode** : express. Les trous critiques sont tranchés en deux séries de questions ; tout le reste (les chiffres) est proposé à la rédaction comme valeurs de départ, à régler au jalon A.

## 2026-11-20 — Arbitrages express

| Sujet | Décision |
|---|---|
| Victoire de run | La run se termine quand on bat le cauchemar le plus profond débloqué. Au départ, Le Professeur suffit. Chaque cauchemar battu ajoute un étage. |
| Seeds | Seed affichée à la mort et saisissable. Une run avec seed saisie ne débloque rien. |
| Pactes | Malédiction seule, contre un pouvoir. La lucidité reste réservée aux pouvoirs (et aux objets ou consommables qui l'annoncent). |
| Économie | Une seule monnaie. Pas de clés ni de bombes. |
| Lucidité à 0 | Pouvoirs bloqués, danger et récompenses au maximum. On n'en sort que par le skill. |
| Récompense de l'abandon | Plus de loot et plus de dégâts. Pas d'objets de meilleure qualité, pas de graze plus rentable. |
| Idées du brainstorm | **Gardées** : l'heure de la mort sur le réveil, une mécanique par phase, l'armure. **Écartée** : les fragments de souvenirs débloqués par des synergies. |
| Quitter en pleine run | Sauvegarder et quitter, au début de la salle en cours. La sauvegarde est effacée à la reprise. |

## 2026-11-20 — Premier brouillon complet

`gdd.md` et `epics.md` sont rédigés en entier. Les chiffres sont des valeurs de départ proposées par le facilitateur, à régler au jalon A.

**Propositions posées à la rédaction, à valider par le designer** :
- Un cauchemar fixe par étage : Professeur, Poursuite, Vague, Silhouette (REM), Toi (secret).
- Choix de porte à la fin des étages 3 et 4 ; l'étage secret s'ouvre une fois La Silhouette battue.
- Heure du réveil : de 23:00 à 4:12, 78 min par phase ; l'horloge reste bloquée sur 4:12 dans l'étage secret.
- Pouvoirs du MVP : Éveil (blank, 30) et Glissement (téléportation visée, 20).
- Un seul objet actif, pas de rareté affichée, pas de doublon d'objet sauf la Dent qui tombe.
- Coûts des 8 objets revus pour éviter les coûts fondés sur un aggro inexistant (constat 8 du stress test) : Réveil cassé coûte de la lucidité, Être nu en public retire l'armure.
- Ennemis du MVP : Somnambule, Veilleuse, Mouton, Berceuse.
- Nom de la monnaie : les Éclats.
- Gravité plus forte en Sommeil profond (brainstorm) : écartée, car elle contredit « tirs sans gravité ». La mécanique de la phase devient les salles sombres.
- Danger de l'abandon figé à l'entrée de la salle, bonus de dégâts en direct.

**Statut** : brouillon. La finalisation (audit du journal, rapprochement avec les sources, passe de validation, revue des points ouverts, polish) reste à faire.

## 2026-11-20 — Finalisation : audit du journal

| Entrée | Où elle est reprise |
|---|---|
| Type de jeu et mode | En-tête et frontmatter du GDD |
| Arbitrages express (8) | Conditions de victoire, Génération procédurale, Pactes, Économie, Lucidité, Hors périmètre, Structure de run |
| Trous du pré-remplissage : chiffres, victoire, seeds, économie, salles spéciales, pactes, ennemis, lien étages-boss, sauvegarde, résolution | Tous traités dans le GDD |
| Propositions du premier brouillon | Dans le GDD, en attente de validation |
| Abandons silencieux : sens de la lucidité aux actes 2 et 3, chambre clinique, les 4 fins nommées, déclencheur « cachets recrachés » | **Mis de côté** : ils relèvent de la conception narrative (`gds-create-narrative`) et des actes 2 et 3, hors du GDD de l'acte 1 |

## 2026-11-20 — Finalisation : rapprochement des sources et validation

Trois revues en parallèle : rapprochement avec le brief (10 constats), rapprochement avec le brainstorm et le stress test (22 constats), validation selon la checklist (26 constats).

**Corrections appliquées sans décision de design** :
- Ajout d'un lexique, d'une section Risques, d'une section Questions ouvertes et d'un index des points [À VALIDER] et [NOTE POUR LE DESIGNER].
- Restauré depuis le brief : la fissure du réel, les références à éviter (Yume Nikki, Omori, Little Nightmares), « jouer avec la salle » (Gungeon), la référence diable et ange et les Faiths, les mêmes types de cœurs qu'Isaac, « veulent que leur précision paie », la musique qui se densifie, la lucidité complète au jalon B, la porte du jalon B.
- Restauré depuis le brainstorm : les lieux de chaque phase, les trous comme sursauts hypnagogiques (désormais dans toutes les phases), les indices de la chambre, l'horloge bloquée sur 4:12, le journal comme encyclopédie, les idées de combat des cauchemars de l'acte 1, les pactes comme « s'enfoncer plus profond ».
- Vocabulaire harmonisé (cauchemar, paliers, invulnérabilité, étage secret, drop), termes vagues chiffrés, tags de piliers ajoutés, route reformulée (pas de carte à la Slay the Spire, ajoutée aux refus), méthode de mesure de la latence.
- Argument unique 4 reformulé pour le joueur (la musique qui suit la plongée).
- Hors périmètre : « charges des objets actifs à la manière d'Isaac » retiré (Réveil cassé se recharge par salles) et remplacé par « plusieurs objets actifs portés à la fois ».

**Recalages des valeurs de départ** :
- Durées : salle de combat ≈ 45 s, cauchemar ≈ 75 s, étage standard de 12 salles (8 de combat) ≈ 9 min. L'étage MVP passe à 16 salles (12 de combat) pour tenir la run de 15 min du brief.
- Salle standard : 36×19 tuiles jouables (l'écran fait 40×22,5 tuiles).
- Économie : 1 à 3 Éclats par salle de combat, drops à 30 %, boutique à 2 objets (15), consommable 5, cœur 4, armure 5 ; cauchemar à 10 Éclats ; coffres retirés.
- Le Professeur : 2 500 PV pour ≈ 75 s avec un build de référence défini ; ses 3 épreuves et le pattern d'Abandon total sont décrits.
- Ajout de bandes d'équilibrage par étage. Cumul additif des bonus de dégâts. Vitesses des projectiles ennemis chiffrées.

**Cas limites réglés par une proposition** :
- Graze : plafond de +20 par salle, pas pendant l'invulnérabilité, le dash parfait le remplace.
- Dépense refusée si la jauge ne la couvre pas ; jauge jamais sous 0.
- Destination de Glissement ; distance au stick à la manette.
- Abandon : renfort = copie du type le plus présent, jamais en salle de cauchemar. Les « élites » sont retirées.
- Dent qui tombe : compte une fois pour les tags ; la salle trésor tire autre chose si elle est grisée.
- Chute libre : ½ cœur de plus au lieu de « 1 cœur au lieu de ½ ».
- Copie d'examen : pas de chrono en salle de cauchemar ; son coût touche aussi les ennemis sans projectiles.
- Une chute compte comme un coup ; Ailes de papier ne fait pas payer deux fois.
- Reflet du Miroir : projectiles de couleur ennemie, PV multipliés par l'étage, jamais en salle de cauchemar.
- Se pincer : jamais l'armure, impossible à ½ cœur. Armure au plafond : reste au sol. Être nu en public : la boutique propose un cœur.
- Somnambule : télégraphe de 0,4 s avant une accélération ; le contact est exclu de la règle de télégraphe.
- Salles sombres : les ennemis de contact restent visibles. Duplication limitée à une fois.
- Seeds : disposition indépendante des choix, tirages indépendants, reproductibles à déblocages égaux.
- Heure du réveil : prorata des salles de combat, heure de fin de phase en cas de victoire.
- Mystère : seule la première victoire révèle une couche.
- Choix de porte : seulement à la fin de l'étage 3 (la porte de l'étage 4 n'avait pas de destination).
- Pactes : On te regarde et Portes mouvantes reformulés pour coller aux règles du GDD.
- Pools : 8 objets dans les pools trésor et boutique au MVP ; le pool cauchemar arrive avec l'acte 1.

**Décisions de fond renvoyées au designer** : (1) faille de la lucidité, (2) identité du pôle Lucide, (3) sacrifice et échange d'objets, (4) étage secret, (5) save-scum, (6) coop.

## 2026-11-20 — Finalisation : décisions de fond

| N° | Sujet | Décision |
|---|---|---|
| 1 | Faille de la lucidité | Le danger suit la descente : passer sous un palier en pleine salle applique aussitôt son danger (signalé) ; remonter ne l'allège qu'à la salle suivante. Le loot se calcule au palier le plus bas atteint dans la salle. |
| 2 | Identité du pôle Lucide | Précision : tirs 30 % plus rapides, hitbox de 4×4 px au palier Lucide. |
| 3 | Sacrifice et échange | Salle d'oubli (acte 1) : on oublie un objet passif porté, puis on choisit l'un de 2 objets tirés pour le remplacer. |
| 4 | Étage secret | Optionnel. Battre La Silhouette gagne la run ; une troisième porte propose ensuite de replonger vers Toi et la fin de l'acte 1. |
| 5 | Save-scum | Accepté et documenté comme une limite. |
| 6 | Coop locale | Plus tard (piste après l'acte 1). |

## 2026-11-20 — Finalisation : revue des points ouverts

- Les 9 propositions marquées [À VALIDER] sont validées en bloc par le designer : heure du réveil, Éveil et Glissement, les 8 objets, les 4 ennemis, Le Professeur, un cauchemar par étage, le choix de porte, les meubles du rêve, le nom des Éclats.
- Aucun point ne bloque la phase suivante. Les questions ouvertes du GDD (pactes, La Silhouette, doubles, consommables de l'acte 1, étage secret, narration) sont reportées avant le jalon C.

## 2026-11-20 — Finalisation

- **Polish** : aucun standard de document configuré (`doc_standards` vide). Le style a été harmonisé pendant les corrections (lexique, vocabulaire, termes vagues chiffrés).
- **Narration** : le guide roguelike ne porte pas de drapeau narratif, mais le pilier 4 et le mystère rendent `gds-create-narrative` utile avant le jalon C. Il est proposé au designer.
- **Statut : final.** Fichiers : `gdd.md`, `epics.md`, `decision-log.md`.

## 2026-11-20 — Plateformes et résolutions (retour de l'architecture)

- **macOS remplace Linux** comme plateforme souhaitée, Windows reste prioritaire. Décidé pendant le workflow d'architecture.
- **Résolutions de 720p à 4K** : rendu interne 640×360 inchangé, facteur d'échelle entier (×2, ×3, ×4, ×6), bandes noires hors 16:9, HiDPI pris en charge.
- Section modifiée : Spécifications techniques › Plateforme.
