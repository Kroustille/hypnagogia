## Deferred from: code review of story 1-1 (2026-11-20)

- ~~`GameClock.paused` est indépendant de `SceneTree.paused` : deux sources de vérité possibles, à trancher à la story 1.6 (pause).~~ **Résolu par la story 1.6** : seul `Main` met en pause, en écrivant ensemble `GameClock.paused` et `ActiveScene.process_mode` ; `SceneTree.paused` n'est jamais utilisé (règle ajoutée à `game-architecture.md`, « Temps (D7) »).
- CA 9 et CA 11 : plein écran à ×2/×3/×4, HiDPI et build release non couverts par les mesures, à traiter à la story 1.8 (export et mesures).
- `GameClock` n'expose aucune API pour modifier les échelles (hitstop, ralenti) : à créer quand une story en aura besoin.

## Deferred from: story 1-2 (2026-11-20)

- **Mesure de 10 minutes à 400 projectiles sur la machine de référence (CA 7 et 8, NFR1, AR31 point 1) : NON FAITE.** Protocole dans la story 1.2 (« Mesure sur la machine de référence ») : F5, F3 visible, 10 minutes, FPS ≥ 60 et 1 % low ≥ 55, `refused` à 0. À faire avant de bâtir le combat ennemi (epic 2) et au plus tard avec l'export de la story 1.8. En cas d'échec : repli GDExtension ou Forward+, à décider et consigner dans la story et dans `game-architecture.md`. Décision de Kroustille du 2026-11-20 : « plus tard ».
- **Fluidité à 144 Hz (CA 9, AR31 point 3) : NON VÉRIFIÉE.** Aucune interpolation des positions de rendu n'est codée ; à ajouter dans `BulletManager` seulement si les projectiles saccadent sur un écran 144 Hz.

## Deferred from: code review of story 1-2 (2026-11-20)

- ~~Traversée de mur si l'échelle de temps d'un groupe dépasse 1 : un seul échantillon de cellule par tick. À traiter (sous-pas ou plafond de pas) à la story 1.4, quand `GameClock` aura une API d'écriture.~~ **Résolu par la story 1.4 (plafond d'échelle)** : `GameClock.global_multiplier` est borné à [0, 1] et aucune échelle de groupe n'est modifiable, donc `scale() ≤ 1` reste un invariant. Si une story future veut une échelle > 1 (aucune dans le GDD), elle devra rouvrir le sujet (sous-pas ou plafond de pas).
- Projectile qui sort de la zone tuilée (ouverture dans `Walls`) ou qui apparaît dans une cellule solide : il vit jusqu'à la fin de sa durée de vie. **Partiellement résolu par la story 1.3** : le cadre de murs de l'arène est fermé, donc aucun projectile ne sort de la zone. Reste le cas d'une apparition dans une cellule solide, à reprendre avec les motifs ennemis (epic 2).
- Couches solides libérées ou remplacées pendant la vie du manager (changement de salle), et F5 qui vide tous les enfants d'`ActiveScene` : **résolu par la story 1.3** pour F5 (l'arène est recréée à chaque retour, `ActiveScene` garde un seul enfant). Le remplacement des couches solides en cours de vie reste sans objet tant que l'arène ne porte pas de `BulletManager` (story 1.5, epic 4). **Mis à jour par la story 1.5** : l'arène porte désormais le `BulletManager` du joueur, mais elle le recrée avec ses `Walls` à chaque retour de F5 ; le remplacement des couches en cours de vie reste à traiter avec les changements de salle (epic 4).

## Deferred from: story 1-3 (2026-11-20)

- **Stick de manette réel : NON VÉRIFIÉ.** Pas de manette sous WSL. Vérifié seulement par `InputEventJoypadMotion` simulés (zone morte à 0,1, déplacement à 1,0, stick incliné de 10° contre les quatre murs sans accrochage). À valider sous Windows avec une vraie manette, au plus tard avec la story 1.7.
- **Ressenti du déplacement et latence : NON ÉVALUÉS** (étapes humaines). Valeurs de départ à juger au jeu : demi-tour = 2× le temps d'accélération (il passe par `accel_px`), `wall_min_slide_angle` laissé au défaut de 15° (aucun accrochage mesuré, voir story 1.3). Latence mesurée : story 1.8.
- **F2 : le contour suit la position physique, pas la position interpolée.** `get_global_transform_interpolated()` n'existe pas en Godot 4.7.2. Le cadre peut devancer le sprite de moins d'un tick (≈1,6 px à pleine vitesse). Acceptable pour du debug ; à reprendre seulement si cela gêne le réglage des hitbox.
- **Mire de netteté (`scale_test_pattern`) conservée mais plus instanciée** : à supprimer ou à rebrancher (touche de debug) selon le besoin de la story 1.8.

## Deferred from: code review of story 1-3 (2026-11-20)

- Valeurs de réglage non validées (`NaN` dans une durée, `move_speed` ≤ 0, `hitbox_size` ≤ 0) : un point de validation unique viendra avec le premier outil d'édition des réglages. La spec ne validait que les deux durées de rampe.
- Pas de flèches directionnelles ni de croix directionnelle de manette sur `move_*` : la réassignation et les alternatives de touches sont la story 1.7.
- `CollisionDrawer` ignore les formes autres que `RectangleShape2D` et `CircleShape2D`, ainsi que les `CollisionShape2D` désactivées : à traiter avec les `Hurtbox` et `Hitbox` de la story 1.5. **Partiellement résolu par la story 1.5** : les `Hurtbox` portent un `RectangleShape2D` et rejoignent le groupe F2, qui les affiche sans modification de `CollisionDrawer`. Restent les autres formes et les formes désactivées, avec la `Hitbox` (epic 2).
- `main.gd` référence `CollisionDrawer` (`debug/`) à la compilation même en release (instanciation gardée par `OS.is_debug_build()`) : à vérifier à l'export, story 1.8.

## Deferred from: story 1-4 (2026-11-21)

- **RB sur une vraie manette : NON VÉRIFIÉ.** Pas de manette sous WSL. L'action `dash` porte bien un `InputEventJoypadButton` d'indice 10 (vérifié par `InputMap`), mais aucun appui réel n'a été fait. À valider sous Windows avec une vraie manette, au plus tard avec la story 1.7.
- **Ressenti du dash : NON ÉVALUÉ** (étapes humaines) : sensation des 3 tuiles en 0,18 s, du tampon de 0,1 s, du dash contre un mur oblique (glissement), du demi-tour juste après un dash. Latence mesurée : story 1.8.
- **Questions ouvertes de la story** (à juger au jeu) : invulnérabilité qui continue pendant que le joueur est coincé contre un mur ; le dash n'interrompt pas la marche (le moteur continue d'avancer vers l'entrée tenue).
- **Netteté du sprite pendant le dash non jugée à l'œil** : WSLg tourne sous llvmpipe, FPS non représentatifs. À regarder sous Windows.
- **Contour F2 devant le sprite pendant le dash** (jusqu'à ~4,4 px, position physique non interpolée) : attendu, voir le report de 1.3.

## Deferred from: code review of story 1-4 (2026-11-21)

- ~~Lecture de l'invulnérabilité par un tiers dépendante de l'ordre dans l'arbre : l'état du dash avance dans le `_physics_process` du joueur ; un ennemi ou un `BulletManager` qui passe avant lit l'état du tick précédent (trou d'un tick au départ). La story 2.1 doit fixer une convention de lecture (par exemple depuis `Hurtbox`, après le joueur).~~ (**résolu en story 2.1** : priorité de tick des `BulletManager`, voir `Const.PHYSICS_PRIORITY_BULLETS`)
- Pas de marge d'arrondi (`TICK_EPSILON`) sur les comparaisons d'invulnérabilité et de tampon dans `Dash` : les valeurs actuelles (0,15 s et 0,1 s à 60 Hz) tombent juste, mais un réglage futur peut gagner ou perdre un tick.

## Deferred from: story 1-5 (2026-11-21)

- **Stick droit et RT sur une vraie manette : NON VÉRIFIÉS.** Pas de manette sous WSL. Vérifié seulement par `InputEventJoypadMotion` simulés (stick à 0,5 : visée et tir automatique ; stick à 0,1 : rien ; RT simulé par l'action `shoot` : tir dans la dernière direction). Zone morte de la gâchette (0,5) et réticule au stick (4 tuiles) à juger sur une vraie manette, au plus tard avec la story 1.7.
- **Ressenti du tir : NON ÉVALUÉ** (étapes humaines) : cadence de 4 tirs/s, recul de 1 px, flash et recul de 2 px de la cible, lisibilité du tir à côté des projectiles ennemis. Les captures fenêtrées montrent le tir, le réticule et le flash au bon tick, mais WSLg tourne sous llvmpipe : netteté et fluidité à regarder sous Windows. Latence mesurée : story 1.8.
- **Son provisoire** (`sfx_player_shot.wav`, 0,06 s, généré par script) : ~~jamais écouté~~ **écouté le 2026-11-21 par Kroustille sous WSLg** : il fonctionne, mais il est **un peu trop aigu** (900 → 400 Hz) ; à baisser plus tard (régénérer le `.wav` avec des fréquences plus graves), au plus tard avec la story 7.7 qui le remplace. Volume et limite de 3 voix encore à juger. Le son sous WSL demande le paquet `libpulse0` (WSLg fournit le serveur PulseAudio ; sans la bibliothèque, Godot retombe sur le pilote factice).
- **Curseur système** : caché par le réticule dans l'arène, rendu visible quand l'arène quitte l'arbre (vérifié en fenêtré). ~~Le menu de pause (story 1.6) devra le rendre visible~~ **Résolu par la story 1.6** : le réticule rend le curseur visible et se cache sur `NOTIFICATION_DISABLED`, et l'inverse sur `NOTIFICATION_ENABLED` (vérifié en fenêtré) ; la gestion fine (bascule clavier-souris ↔ manette) est la story 1.7.
- **Bascule souris ↔ stick provisoire** : le stick prend la main au-delà de la zone morte, la souris la reprend quand sa position de viewport change. À remplacer par l'état du dernier périphérique (story 1.7).
- **Coût du test de charge** : médiane du temps de physique en headless ≈ 212 µs contre ≈ 202 µs au commit de base (3 mesures chacun, bruit du même ordre). Le surcoût par projectile sans cible est un test booléen ; la mesure de 10 minutes sur la machine de référence (story 1.2) reste à faire.
- **`Input.parse_input_event()` est appliqué au tick suivant** (événements mis en tampon) : les scripts de vérification doivent attendre un tick après un événement de stick simulé. Rien à changer dans le jeu ; à savoir pour les futurs tests.

## Deferred from: code review of story 1-5 (2026-11-21)

- ~~`BulletManager._deliver_hits()` livre toujours `DamageInfo.Source.PLAYER_SHOT`, quel que soit le camp du manager : à étendre quand les projectiles ennemis toucheront la `Hurtbox` du joueur (epic 2).~~ (**résolu en story 2.1** : source selon le camp du manager)
- Désenregistrement des hurtbox par `tree_exiting` en `CONNECT_ONE_SHOT` : une hurtbox déplacée (`remove_child` puis `add_child`) ou réutilisée par un pool n'est plus jamais touchée, sans erreur. À revoir avec un pool d'ennemis (epic 2).
- ~~Le test de touche ignore l'état de la `Hurtbox` (`monitorable`, forme `disabled`) : seul le désenregistrement empêche une touche. À trancher avec `Health`, la mort et l'invulnérabilité (story 2.1).~~ (**résolu en story 2.1** : `Hurtbox.is_hittable()` lu par le manager une fois par tick)
- Test de touche discret (position de fin de tick, sans balayage) : traversée de cible, touche à travers un mur ou après expiration possibles seulement à des réglages extrêmes (`bullet_speed` élevé, `hitbox_size` à 0). Aucun saut aux valeurs du GDD (3,73 px/tick, cible de 12 px).
- ~~Ordre de traitement dans l'arbre : les rectangles des cibles sont lus dans le tick du `BulletManager` (ajouté en dernier dans l'arène), et `HitFeedback` dure 3 ticks seulement parce que les cibles passent avant lui. Un ennemi ajouté après le manager serait testé avec un tick de retard. Convention à fixer en 2.1 (rejoint le report de 1.4 sur la lecture de l'invulnérabilité), par exemple avec `process_physics_priority`.~~ (**résolu en story 2.1** : `process_physics_priority` à 100 pour tous les `BulletManager`)
- Pool `Audio` : un flux en boucle, ou un `stop()`, ne libère jamais le lecteur ni le compteur de voix (`finished` n'arrive pas) ; ~~les lecteurs se figent avec l'arbre en pause (sons d'UI du menu de pause, 1.6)~~ (**sans objet depuis la story 1.6** : la pause ne fige que `ActiveScene`, les lecteurs d'`Audio` continuent ; l'aperçu sonore du volume SFX joue pendant la pause) ; `max_voices <= 0` n'est pas validé.
- `SpriteKick` suppose un sprite au repos en `(0, 0)` et `HitFeedback.setup()` écrase le `material` existant du sprite : vrai pour le joueur et les cibles, à revoir avec Le Somnambule (2.3).
- Réticule au stick placé sur la position physique non interpolée du joueur (saccade possible au-delà de 60 Hz d'affichage) ; réticule hors écran dans les barres noires, curseur caché. À juger sur manette avec la story 1.7.
- `Player.equip_bullets()` est répétable (une apparence de plus à chaque appel) et `_bullets == null` ne détecte pas un manager libéré ; un `ShotTuning` invalide fait refuser et journaliser chaque tir. L'arène recrée le joueur aujourd'hui ; à revoir avec les changements de salle (epic 4).

## Deferred from: story 1-6 (2026-11-21)

- **Start et B sur une vraie manette : NON VÉRIFIÉS.** Pas de manette sous WSL. L'action `pause` porte Start (`InputEventJoypadButton`, indice 6) et `ui_*` couvre la croix, le stick gauche, A et B (vérifié par simulation d'actions seulement). À valider sous Windows, au plus tard avec la story 1.7.
- **Plein écran et VSync sous Windows natif : NON VÉRIFIÉS.** Sous WSLg, le plein écran sans bordure s'applique (3840×2160, ×6) et le retour au fenêtré redonne 1280×720 ; la VSync ne peut pas être changée (« not supported by the graphics driver », avertissement du moteur présent dès le démarrage, déjà au commit de base). Effet réel de la VSync et choix exclusif ou mailbox : story 1.8.
- **Volumes à l'oreille : NON JUGÉS** (étape humaine) : le volume général à 80 %, l'aperçu du volume SFX (son de tir provisoire, trop aigu, voir 1.5) et le changement immédiat pendant le glissement ne sont vérifiés que par les valeurs des bus.
- **Renommage atomique sous Windows** : `DirAccess.rename_absolute()` remplace la cible existante ; sous Windows, Godot supprime la cible juste avant de renommer (courte fenêtre non atomique, côté moteur). Non testé sous Windows.
- **Pause automatique à la perte du focus** : vérifiée par `NOTIFICATION_APPLICATION_FOCUS_OUT` simulée en headless et par une fenêtre qui démarre avec le focus sous WSLg ; un alt-tab réel n'a pas été fait. Un lancement sans focus (fenêtre ouverte derrière le terminal) démarrerait en pause.
- **Suivi de la taille de fenêtre (story 1.1) corrigé** : `size_changed` ne part jamais quand seule la fenêtre change (le stretch `viewport` garde le viewport racine à 640×360) ; `Main` compare désormais la taille de la fenêtre à chaque image et ne journalise que les changements de facteur. Le redimensionnement à la souris d'un bord de fenêtre n'a pas été refait (seulement par programme et en plein écran).
- **`HSlider` ne dessine pas le style `focus`** en Godot 4.7 : le focus d'un curseur se voit par le curseur et le remplissage éclairés (thème). À revoir avec la palette de la story 7.2.
- **Police pixel provisoire** (Pixel Operator, CC0) et couleurs du thème provisoires : à revoir avec la story 7.2. Chiffres de dégâts (0,5 s, 8 px, décalages 0/−6/6/−3/3 px) à juger à l'œil.
- **`settings.cfg` sans section `[input]`** : réservée à la story 1.7.

## Deferred from: code review of story 1-6 (2026-11-21)

- `settings.cfg.tmp` laissé par un plantage entre l'écriture et le renommage, ou par un renommage raté : `load_from()` l'ignore (ni nettoyage, ni récupération si le fichier principal manque). Latent.
- `Settings.fullscreen` n'est jamais resynchronisé avec `Window.mode` quand le système change le mode (bouton agrandir, raccourci de la plateforme, mode refusé) : la case affiche alors un état faux et un clic peut être sans effet. Le retour du plein écran force `MODE_WINDOWED` et oublie l'état maximisé. À revoir avec le plein écran sous Windows (story 1.8).
- Montant des chiffres de dégâts non validé dans `DamageNumber` / `DamageNumbers` : `roundi(NAN)` donne un nombre aberrant, une fraction < 0,5 affiche « 0 », un négatif s'affiche tel quel, plus de 4 chiffres débordent le `Label` de 40 px. Latent (dégâts fixes à 10).
- ~~`Hurtbox.receive()` émet `Events.enemy_damaged` pour tout coup, même ignoré par l'ennemi (invulnérable, déjà mort) : à n'émettre qu'après application des dégâts, avec `Health` et la mort (story 2.1).~~ (**résolu en story 2.1** : `receive()` ne fait rien et renvoie `false` pour un coup refusé)

## Deferred from: story 2-1 (2026-11-21)

- **Ressenti du clignotement : NON ÉVALUÉ** (étape humaine). Demi-période de 0,1 s (5 clignotements par seconde), sur le `Sprite2D` seul. Vérifié par code (alternance toutes les 6 ticks, sprite visible à la fin) et par deux captures WSLg décalées (visible puis caché), pas à l'œil en jeu. Cadence et lisibilité en plein combat à juger.
- **Son de coup à l'oreille : NON ÉVALUÉ.** `sfx_player_hit.wav` provisoire (220 vers 90 Hz, 0,15 s), remplacé par la story 7.7 ; seul le compteur de voix est vérifié (headless, audio factice).
- **Lisibilité d'un coup reçu en plein combat : NON ÉVALUÉE** (pas de HUD avant 2.7, pas d'ennemi avant 2.4). Seul le panneau F1 (texte « hearts 5/6 armor 0 cap 24 ») montre la santé.
- **Réticule pendant le clignotement : NON VÉRIFIÉ à l'écran** (souris hors de la fenêtre en capture) ; le réticule est un enfant du joueur et seul le `Sprite2D` est masqué.
- **Dash et projectile au tout premier tick** : l'ordre est garanti par la priorité des managers (contact au premier tick du dash vérifié, K = 2 à 4 ticks après l'entrée) ; un contact un tick *avant* que l'entrée n'atteigne le joueur est un coup légitime. Le report « pas de `TICK_EPSILON` dans `Dash` » reste ouvert.
- **Panneau F1** : en haut à droite, il recouvre le haut du cadre de murs et la bande de HUD (de 24 px) sur 250 px de large ; à revoir quand le HUD de la 2.7 occupera la bande. Les commandes 1 à 5 lisent `physical_keycode` (non réassignables).
- **Mesure de 10 minutes à 400 projectiles sur la machine de référence : toujours NON FAITE** (étape humaine, déjà demandée par 1.2), à rappeler à Kroustille en fin d'epic.
- Un `DamageInfo` de montant invalide (NaN, < 0,5) est refusé avec `Log.error` + `assert` : en build de debug l'assertion fait apparaître un `SCRIPT ERROR` (le jeu continue en headless).

