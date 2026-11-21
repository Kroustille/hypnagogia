## Deferred from: code review of story 1-1 (2026-11-20)

- `GameClock.paused` est indépendant de `SceneTree.paused` : deux sources de vérité possibles, à trancher à la story 1.6 (pause).
- CA 9 et CA 11 : plein écran à ×2/×3/×4, HiDPI et build release non couverts par les mesures, à traiter à la story 1.8 (export et mesures).
- `GameClock` n'expose aucune API pour modifier les échelles (hitstop, ralenti) : à créer quand une story en aura besoin.

## Deferred from: story 1-2 (2026-11-20)

- **Mesure de 10 minutes à 400 projectiles sur la machine de référence (CA 7 et 8, NFR1, AR31 point 1) : NON FAITE.** Protocole dans la story 1.2 (« Mesure sur la machine de référence ») : F5, F3 visible, 10 minutes, FPS ≥ 60 et 1 % low ≥ 55, `refused` à 0. À faire avant de bâtir le combat ennemi (epic 2) et au plus tard avec l'export de la story 1.8. En cas d'échec : repli GDExtension ou Forward+, à décider et consigner dans la story et dans `game-architecture.md`. Décision de Kroustille du 2026-11-20 : « plus tard ».
- **Fluidité à 144 Hz (CA 9, AR31 point 3) : NON VÉRIFIÉE.** Aucune interpolation des positions de rendu n'est codée ; à ajouter dans `BulletManager` seulement si les projectiles saccadent sur un écran 144 Hz.

## Deferred from: code review of story 1-2 (2026-11-20)

- ~~Traversée de mur si l'échelle de temps d'un groupe dépasse 1 : un seul échantillon de cellule par tick. À traiter (sous-pas ou plafond de pas) à la story 1.4, quand `GameClock` aura une API d'écriture.~~ **Résolu par la story 1.4 (plafond d'échelle)** : `GameClock.global_multiplier` est borné à [0, 1] et aucune échelle de groupe n'est modifiable, donc `scale() ≤ 1` reste un invariant. Si une story future veut une échelle > 1 (aucune dans le GDD), elle devra rouvrir le sujet (sous-pas ou plafond de pas).
- Projectile qui sort de la zone tuilée (ouverture dans `Walls`) ou qui apparaît dans une cellule solide : il vit jusqu'à la fin de sa durée de vie. **Partiellement résolu par la story 1.3** : le cadre de murs de l'arène est fermé, donc aucun projectile ne sort de la zone. Reste le cas d'une apparition dans une cellule solide, à reprendre avec les motifs ennemis (epic 2).
- Couches solides libérées ou remplacées pendant la vie du manager (changement de salle), et F5 qui vide tous les enfants d'`ActiveScene` : **résolu par la story 1.3** pour F5 (l'arène est recréée à chaque retour, `ActiveScene` garde un seul enfant). Le remplacement des couches solides en cours de vie reste sans objet tant que l'arène ne porte pas de `BulletManager` (story 1.5, epic 4).

## Deferred from: story 1-3 (2026-11-20)

- **Stick de manette réel : NON VÉRIFIÉ.** Pas de manette sous WSL. Vérifié seulement par `InputEventJoypadMotion` simulés (zone morte à 0,1, déplacement à 1,0, stick incliné de 10° contre les quatre murs sans accrochage). À valider sous Windows avec une vraie manette, au plus tard avec la story 1.7.
- **Ressenti du déplacement et latence : NON ÉVALUÉS** (étapes humaines). Valeurs de départ à juger au jeu : demi-tour = 2× le temps d'accélération (il passe par `accel_px`), `wall_min_slide_angle` laissé au défaut de 15° (aucun accrochage mesuré, voir story 1.3). Latence mesurée : story 1.8.
- **F2 : le contour suit la position physique, pas la position interpolée.** `get_global_transform_interpolated()` n'existe pas en Godot 4.7.2. Le cadre peut devancer le sprite de moins d'un tick (≈1,6 px à pleine vitesse). Acceptable pour du debug ; à reprendre seulement si cela gêne le réglage des hitbox.
- **Mire de netteté (`scale_test_pattern`) conservée mais plus instanciée** : à supprimer ou à rebrancher (touche de debug) selon le besoin de la story 1.8.

## Deferred from: code review of story 1-3 (2026-11-20)

- Valeurs de réglage non validées (`NaN` dans une durée, `move_speed` ≤ 0, `hitbox_size` ≤ 0) : un point de validation unique viendra avec le premier outil d'édition des réglages. La spec ne validait que les deux durées de rampe.
- Pas de flèches directionnelles ni de croix directionnelle de manette sur `move_*` : la réassignation et les alternatives de touches sont la story 1.7.
- `CollisionDrawer` ignore les formes autres que `RectangleShape2D` et `CircleShape2D`, ainsi que les `CollisionShape2D` désactivées : à traiter avec les `Hurtbox` et `Hitbox` de la story 1.5.
- `main.gd` référence `CollisionDrawer` (`debug/`) à la compilation même en release (instanciation gardée par `OS.is_debug_build()`) : à vérifier à l'export, story 1.8.

## Deferred from: story 1-4 (2026-11-21)

- **RB sur une vraie manette : NON VÉRIFIÉ.** Pas de manette sous WSL. L'action `dash` porte bien un `InputEventJoypadButton` d'indice 10 (vérifié par `InputMap`), mais aucun appui réel n'a été fait. À valider sous Windows avec une vraie manette, au plus tard avec la story 1.7.
- **Ressenti du dash : NON ÉVALUÉ** (étapes humaines) : sensation des 3 tuiles en 0,18 s, du tampon de 0,1 s, du dash contre un mur oblique (glissement), du demi-tour juste après un dash. Latence mesurée : story 1.8.
- **Questions ouvertes de la story** (à juger au jeu) : invulnérabilité qui continue pendant que le joueur est coincé contre un mur ; le dash n'interrompt pas la marche (le moteur continue d'avancer vers l'entrée tenue).
- **Netteté du sprite pendant le dash non jugée à l'œil** : WSLg tourne sous llvmpipe, FPS non représentatifs. À regarder sous Windows.
- **Contour F2 devant le sprite pendant le dash** (jusqu'à ~4,4 px, position physique non interpolée) : attendu, voir le report de 1.3.
