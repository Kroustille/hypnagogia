---
title: 'Stress test — Hypnagogia brainstorm'
date: '2026-11-20'
reviewed: '_bmad-output/planning-artifacts/hypnagogia-brainstorm.md'
workflow: bmad-review
lenses: [adversarial, edge-case-hunter]
---

# Stress test — Hypnagogia brainstorm

Content: design document (`docs`, defines behavior). Lenses: **adversarial**, **edge-case-hunter**. Editorial lenses (structure, prose) were not run: this review is about the content, not the wording. There's no severity ranking, by design. Overlap between the two lenses is deliberate and shows where problems cluster.

## Adversarial (20 findings)

### 1. Lucidity drops with damage, and low lucidity makes rooms harder: struggling players get punished twice (death spiral), while skilled players stay high and miss the bonus loot.

- **Where:** Mécaniques › Jauge de lucidité (L76)
- **Fix:** Make losing lucidity a choice (pacts, consumables, optional risky actions) and keep damage on HP only, or add a strong catch-up mechanic at low lucidity. Test it on paper with a few simulated runs before building it.
- **If ignored:** The signature system turns into a difficulty multiplier for weak runs instead of a risk/reward choice, which breaks the 'death is always deserved' pillar.

### 2. The lucidity economy only goes down: damage, curses, every pact, Somnifère and Boîte à musique lower it, and only 'Se pincer' raises it.

- **Where:** Mécaniques › Jauge de lucidité + Consommables + Pactes
- **Fix:** List every source and sink with numbers (gauge size, cost per hit, per pact, per consumable) and add regular recovery (floor clear, boss kill, a 'lucid' action).
- **If ignored:** The gauge bottoms out by floor 2–3 in every run, so 'high lucidity' play never happens and the system reads as a countdown.

### 3. At low lucidity 'les ennemis deviennent imprévisibles', but the golden rule says combat must stay readable and death deserved.

- **Where:** Mécaniques › Jauge de lucidité vs Règle d'or (L76)
- **Fix:** Turn 'unpredictable' into readable, telegraphed changes: faster windups, an extra pattern, more spawns. Only visuals and sound get distorted, never behavior randomness.
- **If ignored:** Random enemy behavior makes deaths feel unfair, which contradicts pillar 1.

### 4. The run structure isn't defined: floors per run, whether one run covers all 4 phases, target run length, and what winning a run means.

- **Where:** Boucle de jeu (L16) + Questions ouvertes
- **Fix:** Fix it: e.g. a run is 4 floors (one per phase), plus the secret floor once unlocked, 25–40 min. Define the win state (wake up 'for real', unlock the next nightmare).
- **If ignored:** Without it you can't size rooms, items, enemies or the difficulty curve. Every downstream estimate floats.

### 5. No economy or room types: no currency, shops or keys, no explanation of how items are obtained. Treasure rooms show up in a pact but are never defined.

- **Where:** Boucle de jeu + Objets + Pactes
- **Fix:** Add a section listing room types (combat, treasure, consumable cache, pact, boss, secret) and how each item reaches the player (drops, treasure, boss reward, shop or not).
- **If ignored:** Item, pact and Copie d'examen ('plus de loot') effects rest on systems that don't exist, and the floor generator can't be specified.

### 6. The health model is incomplete: hearts and half-hearts appear, 'Être nu' removes 'armure', but armor is never defined, and its overlap with Doudou is unclear.

- **Where:** Objets et synergies (L92) + Mécaniques
- **Fix:** Define health: starting hearts, max-heart cap, whether armor or shields exist and how they're gained. Otherwise rewrite the cost of 'Être nu en public'.
- **If ignored:** At least one item cost is meaningless and the balancing has no foundation.

### 7. No enemy list: each phase gets a mood ('foule sans visage', 'ennemis massifs'), but there are no enemy archetypes, telegraph rules or counts per phase. Prototype 1 needs 3.

- **Where:** Structure du monde › Acte 1
- **Fix:** Define 4–6 archetypes (chaser, shooter, charger, spawner, turret, splitter) with dream skins per phase, plus a telegraph rule (e.g. every attack has a ≥0.4 s windup).
- **If ignored:** Combat, the actual subject of Prototype 1, has no design target, so the prototype tests movement against placeholders.

### 8. Several costs depend on an aggro system that doesn't exist: Réveil cassé 'attire les ennemis', Bougie attracts moths, Boîte à musique puts enemies to sleep. In locked rooms where everything already chases you, 'attract' does nothing.

- **Where:** Objets / Consommables / Pactes
- **Fix:** Either add enemy awareness (idle/alert states, cross-room wandering) or rewrite those costs as concrete effects (e.g. the alarm spawns an extra wave).
- **If ignored:** Costs that do nothing turn trade-off items into pure upgrades, and builds become obvious.

### 9. The pact grants 'invulnérable pendant les dash', but the base dash already has short invulnerability, and showing only the player's shadow hurts player readability.

- **Where:** Pactes › Visage oublié vs Mécaniques › Contrôles
- **Fix:** Change the power (e.g. the dash leaves a damaging afterimage) and make sure the player's hitbox stays perfectly readable under the shadow look.
- **If ignored:** The power does nothing and the curse breaks the golden rule, since you can't dodge what you can't see yourself doing.

### 10. 'Plus de consommables actifs' also removes the only lucidity refill (Se pincer), on top of the lucidity every pact already costs.

- **Where:** Pactes › Sans voix
- **Fix:** Either have pacts cost lucidity or a curse, not both, or exempt Se pincer, or give Sans voix a lucidity floor.
- **If ignored:** A guaranteed lucidity collapse makes Sans voix a trap choice, which goes against 'les décisions passent par les pactes'.

### 11. The synergies are hand-written pairs. That scales quadratically with the item count and won't deliver 'guessable by meaning' across a large pool.

- **Where:** Objets et synergies › Synergies par le sens
- **Fix:** Give items theme tags (chute, temps, regard, poursuite…) with rules per tag (e.g. 2 'chute' items → shockwave on landing), and keep hand-made pairs for the story fragments.
- **If ignored:** Either a small fixed set of synergies players memorize (the opposite of the pillar) or an unbalanceable combinatorial explosion.

### 12. The link between floors and nightmares is unclear: 5 nightmares and 4 phases plus a secret floor, 'beating one unlocks the next', but which boss guards which floor in a given run?

- **Where:** Cauchemars (L144) + Boucle de jeu
- **Fix:** Make a table: floor/phase → boss pool, and unlock rule → what changes in the next run (new final boss? deeper floor?).
- **If ignored:** The difficulty progression and the ending conditions, which depend on bosses beaten, can't be designed.

### 13. The endings read like player choices (stay, escape, sleep forever), but they're triggered by which nightmares you've beaten, a linear unlock order. Act 2/3 transition triggers ('cachets recrachés') aren't defined either.

- **Where:** Histoire et mystère › Fins
- **Fix:** Decide: choice-driven endings (a final in-world decision) or progress-driven ones (the order bosses fall), and define each act transition as an explicit trigger.
- **If ignored:** Endings feel arbitrary, or the whole narrative structure collapses into a single path.

### 14. Act 1 is supposed to be a complete game, but its central twist (the false awakening) only pays off in Act 2.

- **Where:** Points de vigilance › Scope + Histoire
- **Fix:** Write an Act 1 ending that resolves a question (e.g. revealing the false awakening is the Act 1 finale) while opening the next one.
- **If ignored:** An Act 1-only release ends on a cliffhanger instead of the 'jeu complet et satisfaisant' you're aiming for.

### 15. The mechanics treat psychiatric medication as the enemy (Act 2: fighting your treatment) and stopping it as power (Act 3), while the narrative wants to stay neutral.

- **Where:** Mécaniques › Jauge de lucidité (Actes 2–3) + Points de vigilance
- **Fix:** Give Act 3's heightened lucidity a clear cost that keeps the 'ill or lied to?' doubt in the mechanics. Plan a sensitivity read / consult, as Hellblade did.
- **If ignored:** The game reads as anti-medication messaging no matter what the text says, a reputational and ethical risk.

### 16. No accessibility plan, even though the core identity uses chromatic aberration, wavy backgrounds, saturated REM neons and bullet-hell density.

- **Where:** Direction artistique et son + Mécaniques
- **Fix:** Commit early to options: reduce distortion and screen shake, a photosensitivity mode, a colorblind-safe projectile palette that stays the same in every phase, and a remappable UI.
- **If ignored:** Motion sickness and photosensitivity complaints, and projectile readability lost in phases whose palette clashes with the bullets.

### 17. Prototype 1 is supposed to prove 'combat is tight', but its boss, La Silhouette, starts the fight with the player immobilized: the least representative mechanic there is.

- **Where:** Premier prototype › Prototype 1 (L196)
- **Fix:** Use a straightforward pattern boss for Prototype 1 (e.g. Le Professeur) and move La Silhouette to Prototype 2.
- **If ignored:** The prototype's result gets muddied by a gimmick boss, and you learn less about core feel.

### 18. Prototype 1 is scoped too wide to answer one question (floor generation, a hub, items, a synergy), while the riskiest system, lucidity, waits until Prototype 2.

- **Where:** Premier prototype
- **Fix:** Prototype 1: one arena, movement, shooting and dash, 3 enemies, instant restart. Prototype 1.5: a cheap lucidity test (gauge plus one distortion) before investing in content.
- **If ignored:** Weeks spent on infrastructure before you know whether the feel works or whether lucidity spirals.

### 19. Missing GDD basics: target platforms (PC? Steam Deck? consoles?), audience, a scope reference for a solo dev, pixel resolution, and the engine (native Rust isn't supported by BMGD's architecture workflows).

- **Where:** Questions ouvertes + general
- **Fix:** Decide platform, engine and base resolution (e.g. 480×270 / 640×360) before the architecture workflow. Name 2–3 comparable games for scope.
- **If ignored:** Architecture and art pipeline work can't start, and the scope has no reference to measure it against.

### 20. Mechanically the core is very close to Binding of Isaac (trade-off items, boss unlocks as difficulty, curses, rooms). The planned difference is story and art, and the only mechanical difference is lucidity.

- **Where:** Pitch et piliers + Points de vigilance
- **Fix:** Make lucidity, or another system, visibly central from the first minute and test it early, so the game has a mechanical hook as well as a story one.
- **If ignored:** Reviews and players file it as 'Isaac with a dream skin'.

## Edge-Case Hunter (17 findings)

### 1. Lucidity reaching 0 or the maximum isn't handled.

- **Where:** Mécaniques › Jauge de lucidité
- **Fix:** Rule: at 0 → [death | forced nightmare room | max distortion cap]; at max → no further gain, extra refills convert to [X].
- **If ignored:** Undefined end states produce exploits or soft deaths.

### 2. In Act 3 lucidity sits 'au maximum'. Can damage still lower it, and what does low lucidity mean then?

- **Where:** Mécaniques › Acte 3
- **Fix:** Define the Act 3 gauge behavior explicitly (inverted, locked, or a new resource).
- **If ignored:** The core system is ambiguous for a whole act.

### 3. Falling into a pit, or being knocked into a fall by Ailes de papier, has no outcome, and neither does a fall on a floor without pits.

- **Where:** Structure du monde › Endormissement (trous) + Ailes de papier
- **Fix:** Rule: a fall = [half a heart + respawn at the edge | drop a floor]. Ailes de papier: on a hit, if over a pit → fall, otherwise → stun 0.5 s.
- **If ignored:** An item cost that does nothing on most floors, and a core hazard you can't implement.

### 4. Nothing happens when the room timer runs out, and boss rooms and cleared rooms aren't covered.

- **Where:** Objets › Copie d'examen vierge
- **Fix:** Rule: at 0 → [extra wave | lose the loot bonus for the room]; no timer in boss or cleared rooms.
- **If ignored:** A cost with no teeth, or an unfair boss fight.

### 5. Stacking duplicates, or max hearts reaching 0, isn't covered.

- **Where:** Objets › Dent qui tombe
- **Fix:** Rule: duplicates [can't appear | stack, with max hearts never below 1].
- **If ignored:** Instant death from picking up an item, or an unbounded damage stack.

### 6. The rewind's scope isn't defined: are consumables used, items picked up, lucidity and curses gained in the room restored? Can you use it in a boss room?

- **Where:** Consommables › Sablier
- **Fix:** Rule: restore HP and lucidity only; items and consumables are kept; can't be used in boss rooms (or: allowed, with the boss enraged).
- **If ignored:** A duplication exploit or a confusing rewind.

### 7. Using it with no curse isn't covered, and it's unclear whether pact curses can be purged. If they can, pacts become free power.

- **Where:** Consommables › Verre d'eau + Pactes
- **Fix:** Rule: pact curses can't be purged (or purging also removes the pact power); with no curse, it only rolls the add-a-curse chance.
- **If ignored:** Pacts get trivialized by a common consumable.

### 8. Taking the pact while holding consumables isn't covered.

- **Where:** Pactes › Sans voix
- **Fix:** Rule: held consumables are [dropped | kept but locked | turned into lucidity].
- **If ignored:** Inconsistent behavior and a possible loss of player resources.

### 9. The map reorganizes after every room. There's no guarantee the boss stays reachable, and backtracking to uncleared or treasure rooms isn't handled.

- **Where:** Pactes › Portes mouvantes
- **Fix:** Rule: rebuild only unvisited rooms, and always keep a path to the boss.
- **If ignored:** Softlocks, or unreachable rewards.

### 10. Refusing every pact ('jouer la sécurité') has no defined result.

- **Where:** Pactes (choix)
- **Fix:** Rule: refusing = no change, or a small heal or lucidity refill, so playing it safe is an actual option.
- **If ignored:** Either pacts are mandatory in practice or refusing is the dominant choice.

### 11. The 1 s immobilization during a boss fight or bullet-hell isn't covered, and neither is whether the Boîte à musique affects bosses.

- **Where:** Consommables › Regarder ses mains / Boîte à musique
- **Fix:** Rule: invulnerable during Regarder ses mains, or say explicitly that it isn't; bosses are immune to sleep (or only slowed).
- **If ignored:** Unfair deaths, or bosses trivialized.

### 12. Several 'double' entities can be active at once (the Miroir's evil double, the watching presence, the 'Toi' boss), and nothing defines how they interact or how players tell them apart.

- **Where:** Objets › Miroir + Pactes › On te regarde + Cauchemars › Toi
- **Fix:** Rule: give each its own silhouette and color, and suppress the Miroir double during the 'Toi' fight.
- **If ignored:** Visual confusion in the climactic fight and broken readability.

### 13. The player appears only as a shadow, in dark rooms, so they may not be visible at all.

- **Where:** Pactes › Visage oublié + Sommeil profond (salles sombres)
- **Fix:** Rule: always draw an outline or hitbox marker for the player, whatever the pact or lighting.
- **If ignored:** The player can't see their own position, so deaths feel unfair.

### 14. A story fragment is tied to a synergy whose items may not be unlocked yet, or whose random drops rarely line up.

- **Where:** Objets et synergies › Fragments de souvenirs
- **Fix:** Rule: fragment synergies only use items already unlocked, with a pity mechanic or guaranteed offer after N runs.
- **If ignored:** Story progress stalls on RNG and a key fragment may never be seen.

### 15. Finishing a run (beating the last available nightmare) has no defined outcome, since only 'death = waking up' is specified, and the death-clock time formula isn't defined.

- **Where:** Boucle de jeu (victoire) + Hub › Le réveil
- **Fix:** Rule: win = [wake up with a special scene / clock shows a target time]; clock time = f(depth reached, time spent). Decide whether dying exactly at 4:12 means something.
- **If ignored:** No closure on success, and the disguised score means nothing.

### 16. Precedence when several ending conditions are met at once isn't defined.

- **Where:** Histoire et mystère › Fins
- **Fix:** Rule: a strict priority order or an explicit choice point at the end of Act 3.
- **If ignored:** Endings trigger unpredictably.

### 17. Quitting mid-run (save and resume vs. abandon) isn't addressed.

- **Where:** Boucle de jeu
- **Fix:** Rule: suspend-save on quit, deleted on load (or: quitting counts as waking up).
- **If ignored:** Save-scumming, or lost runs on Steam Deck / suspend.

## Findings (JSON)

```json
[
  {
    "lens": "adversarial",
    "location": "Mécaniques › Jauge de lucidité (L76)",
    "trigger_condition": "Lucidity drops with damage, and low lucidity makes rooms harder: struggling players get punished twice (death spiral), while skilled players stay high and miss the bonus loot.",
    "guard_snippet": "Make losing lucidity a choice (pacts, consumables, optional risky actions) and keep damage on HP only, or add a strong catch-up mechanic at low lucidity. Test it on paper with a few simulated runs before building it.",
    "potential_consequence": "The signature system turns into a difficulty multiplier for weak runs instead of a risk/reward choice, which breaks the 'death is always deserved' pillar."
  },
  {
    "lens": "adversarial",
    "location": "Mécaniques › Jauge de lucidité + Consommables + Pactes",
    "trigger_condition": "The lucidity economy only goes down: damage, curses, every pact, Somnifère and Boîte à musique lower it, and only 'Se pincer' raises it.",
    "guard_snippet": "List every source and sink with numbers (gauge size, cost per hit, per pact, per consumable) and add regular recovery (floor clear, boss kill, a 'lucid' action).",
    "potential_consequence": "The gauge bottoms out by floor 2–3 in every run, so 'high lucidity' play never happens and the system reads as a countdown."
  },
  {
    "lens": "adversarial",
    "location": "Mécaniques › Jauge de lucidité vs Règle d'or (L76)",
    "trigger_condition": "At low lucidity 'les ennemis deviennent imprévisibles', but the golden rule says combat must stay readable and death deserved.",
    "guard_snippet": "Turn 'unpredictable' into readable, telegraphed changes: faster windups, an extra pattern, more spawns. Only visuals and sound get distorted, never behavior randomness.",
    "potential_consequence": "Random enemy behavior makes deaths feel unfair, which contradicts pillar 1."
  },
  {
    "lens": "adversarial",
    "location": "Boucle de jeu (L16) + Questions ouvertes",
    "trigger_condition": "The run structure isn't defined: floors per run, whether one run covers all 4 phases, target run length, and what winning a run means.",
    "guard_snippet": "Fix it: e.g. a run is 4 floors (one per phase), plus the secret floor once unlocked, 25–40 min. Define the win state (wake up 'for real', unlock the next nightmare).",
    "potential_consequence": "Without it you can't size rooms, items, enemies or the difficulty curve. Every downstream estimate floats."
  },
  {
    "lens": "adversarial",
    "location": "Boucle de jeu + Objets + Pactes",
    "trigger_condition": "No economy or room types: no currency, shops or keys, no explanation of how items are obtained. Treasure rooms show up in a pact but are never defined.",
    "guard_snippet": "Add a section listing room types (combat, treasure, consumable cache, pact, boss, secret) and how each item reaches the player (drops, treasure, boss reward, shop or not).",
    "potential_consequence": "Item, pact and Copie d'examen ('plus de loot') effects rest on systems that don't exist, and the floor generator can't be specified."
  },
  {
    "lens": "adversarial",
    "location": "Objets et synergies (L92) + Mécaniques",
    "trigger_condition": "The health model is incomplete: hearts and half-hearts appear, 'Être nu' removes 'armure', but armor is never defined, and its overlap with Doudou is unclear.",
    "guard_snippet": "Define health: starting hearts, max-heart cap, whether armor or shields exist and how they're gained. Otherwise rewrite the cost of 'Être nu en public'.",
    "potential_consequence": "At least one item cost is meaningless and the balancing has no foundation."
  },
  {
    "lens": "adversarial",
    "location": "Structure du monde › Acte 1",
    "trigger_condition": "No enemy list: each phase gets a mood ('foule sans visage', 'ennemis massifs'), but there are no enemy archetypes, telegraph rules or counts per phase. Prototype 1 needs 3.",
    "guard_snippet": "Define 4–6 archetypes (chaser, shooter, charger, spawner, turret, splitter) with dream skins per phase, plus a telegraph rule (e.g. every attack has a ≥0.4 s windup).",
    "potential_consequence": "Combat, the actual subject of Prototype 1, has no design target, so the prototype tests movement against placeholders."
  },
  {
    "lens": "adversarial",
    "location": "Objets / Consommables / Pactes",
    "trigger_condition": "Several costs depend on an aggro system that doesn't exist: Réveil cassé 'attire les ennemis', Bougie attracts moths, Boîte à musique puts enemies to sleep. In locked rooms where everything already chases you, 'attract' does nothing.",
    "guard_snippet": "Either add enemy awareness (idle/alert states, cross-room wandering) or rewrite those costs as concrete effects (e.g. the alarm spawns an extra wave).",
    "potential_consequence": "Costs that do nothing turn trade-off items into pure upgrades, and builds become obvious."
  },
  {
    "lens": "adversarial",
    "location": "Pactes › Visage oublié vs Mécaniques › Contrôles",
    "trigger_condition": "The pact grants 'invulnérable pendant les dash', but the base dash already has short invulnerability, and showing only the player's shadow hurts player readability.",
    "guard_snippet": "Change the power (e.g. the dash leaves a damaging afterimage) and make sure the player's hitbox stays perfectly readable under the shadow look.",
    "potential_consequence": "The power does nothing and the curse breaks the golden rule, since you can't dodge what you can't see yourself doing."
  },
  {
    "lens": "adversarial",
    "location": "Pactes › Sans voix",
    "trigger_condition": "'Plus de consommables actifs' also removes the only lucidity refill (Se pincer), on top of the lucidity every pact already costs.",
    "guard_snippet": "Either have pacts cost lucidity or a curse, not both, or exempt Se pincer, or give Sans voix a lucidity floor.",
    "potential_consequence": "A guaranteed lucidity collapse makes Sans voix a trap choice, which goes against 'les décisions passent par les pactes'."
  },
  {
    "lens": "adversarial",
    "location": "Objets et synergies › Synergies par le sens",
    "trigger_condition": "The synergies are hand-written pairs. That scales quadratically with the item count and won't deliver 'guessable by meaning' across a large pool.",
    "guard_snippet": "Give items theme tags (chute, temps, regard, poursuite…) with rules per tag (e.g. 2 'chute' items → shockwave on landing), and keep hand-made pairs for the story fragments.",
    "potential_consequence": "Either a small fixed set of synergies players memorize (the opposite of the pillar) or an unbalanceable combinatorial explosion."
  },
  {
    "lens": "adversarial",
    "location": "Cauchemars (L144) + Boucle de jeu",
    "trigger_condition": "The link between floors and nightmares is unclear: 5 nightmares and 4 phases plus a secret floor, 'beating one unlocks the next', but which boss guards which floor in a given run?",
    "guard_snippet": "Make a table: floor/phase → boss pool, and unlock rule → what changes in the next run (new final boss? deeper floor?).",
    "potential_consequence": "The difficulty progression and the ending conditions, which depend on bosses beaten, can't be designed."
  },
  {
    "lens": "adversarial",
    "location": "Histoire et mystère › Fins",
    "trigger_condition": "The endings read like player choices (stay, escape, sleep forever), but they're triggered by which nightmares you've beaten, a linear unlock order. Act 2/3 transition triggers ('cachets recrachés') aren't defined either.",
    "guard_snippet": "Decide: choice-driven endings (a final in-world decision) or progress-driven ones (the order bosses fall), and define each act transition as an explicit trigger.",
    "potential_consequence": "Endings feel arbitrary, or the whole narrative structure collapses into a single path."
  },
  {
    "lens": "adversarial",
    "location": "Points de vigilance › Scope + Histoire",
    "trigger_condition": "Act 1 is supposed to be a complete game, but its central twist (the false awakening) only pays off in Act 2.",
    "guard_snippet": "Write an Act 1 ending that resolves a question (e.g. revealing the false awakening is the Act 1 finale) while opening the next one.",
    "potential_consequence": "An Act 1-only release ends on a cliffhanger instead of the 'jeu complet et satisfaisant' you're aiming for."
  },
  {
    "lens": "adversarial",
    "location": "Mécaniques › Jauge de lucidité (Actes 2–3) + Points de vigilance",
    "trigger_condition": "The mechanics treat psychiatric medication as the enemy (Act 2: fighting your treatment) and stopping it as power (Act 3), while the narrative wants to stay neutral.",
    "guard_snippet": "Give Act 3's heightened lucidity a clear cost that keeps the 'ill or lied to?' doubt in the mechanics. Plan a sensitivity read / consult, as Hellblade did.",
    "potential_consequence": "The game reads as anti-medication messaging no matter what the text says, a reputational and ethical risk."
  },
  {
    "lens": "adversarial",
    "location": "Direction artistique et son + Mécaniques",
    "trigger_condition": "No accessibility plan, even though the core identity uses chromatic aberration, wavy backgrounds, saturated REM neons and bullet-hell density.",
    "guard_snippet": "Commit early to options: reduce distortion and screen shake, a photosensitivity mode, a colorblind-safe projectile palette that stays the same in every phase, and a remappable UI.",
    "potential_consequence": "Motion sickness and photosensitivity complaints, and projectile readability lost in phases whose palette clashes with the bullets."
  },
  {
    "lens": "adversarial",
    "location": "Premier prototype › Prototype 1 (L196)",
    "trigger_condition": "Prototype 1 is supposed to prove 'combat is tight', but its boss, La Silhouette, starts the fight with the player immobilized: the least representative mechanic there is.",
    "guard_snippet": "Use a straightforward pattern boss for Prototype 1 (e.g. Le Professeur) and move La Silhouette to Prototype 2.",
    "potential_consequence": "The prototype's result gets muddied by a gimmick boss, and you learn less about core feel."
  },
  {
    "lens": "adversarial",
    "location": "Premier prototype",
    "trigger_condition": "Prototype 1 is scoped too wide to answer one question (floor generation, a hub, items, a synergy), while the riskiest system, lucidity, waits until Prototype 2.",
    "guard_snippet": "Prototype 1: one arena, movement, shooting and dash, 3 enemies, instant restart. Prototype 1.5: a cheap lucidity test (gauge plus one distortion) before investing in content.",
    "potential_consequence": "Weeks spent on infrastructure before you know whether the feel works or whether lucidity spirals."
  },
  {
    "lens": "adversarial",
    "location": "Questions ouvertes + general",
    "trigger_condition": "Missing GDD basics: target platforms (PC? Steam Deck? consoles?), audience, a scope reference for a solo dev, pixel resolution, and the engine (native Rust isn't supported by BMGD's architecture workflows).",
    "guard_snippet": "Decide platform, engine and base resolution (e.g. 480×270 / 640×360) before the architecture workflow. Name 2–3 comparable games for scope.",
    "potential_consequence": "Architecture and art pipeline work can't start, and the scope has no reference to measure it against."
  },
  {
    "lens": "adversarial",
    "location": "Pitch et piliers + Points de vigilance",
    "trigger_condition": "Mechanically the core is very close to Binding of Isaac (trade-off items, boss unlocks as difficulty, curses, rooms). The planned difference is story and art, and the only mechanical difference is lucidity.",
    "guard_snippet": "Make lucidity, or another system, visibly central from the first minute and test it early, so the game has a mechanical hook as well as a story one.",
    "potential_consequence": "Reviews and players file it as 'Isaac with a dream skin'."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Mécaniques › Jauge de lucidité",
    "trigger_condition": "Lucidity reaching 0 or the maximum isn't handled.",
    "guard_snippet": "Rule: at 0 → [death | forced nightmare room | max distortion cap]; at max → no further gain, extra refills convert to [X].",
    "potential_consequence": "Undefined end states produce exploits or soft deaths."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Mécaniques › Acte 3",
    "trigger_condition": "In Act 3 lucidity sits 'au maximum'. Can damage still lower it, and what does low lucidity mean then?",
    "guard_snippet": "Define the Act 3 gauge behavior explicitly (inverted, locked, or a new resource).",
    "potential_consequence": "The core system is ambiguous for a whole act."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Structure du monde › Endormissement (trous) + Ailes de papier",
    "trigger_condition": "Falling into a pit, or being knocked into a fall by Ailes de papier, has no outcome, and neither does a fall on a floor without pits.",
    "guard_snippet": "Rule: a fall = [half a heart + respawn at the edge | drop a floor]. Ailes de papier: on a hit, if over a pit → fall, otherwise → stun 0.5 s.",
    "potential_consequence": "An item cost that does nothing on most floors, and a core hazard you can't implement."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Objets › Copie d'examen vierge",
    "trigger_condition": "Nothing happens when the room timer runs out, and boss rooms and cleared rooms aren't covered.",
    "guard_snippet": "Rule: at 0 → [extra wave | lose the loot bonus for the room]; no timer in boss or cleared rooms.",
    "potential_consequence": "A cost with no teeth, or an unfair boss fight."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Objets › Dent qui tombe",
    "trigger_condition": "Stacking duplicates, or max hearts reaching 0, isn't covered.",
    "guard_snippet": "Rule: duplicates [can't appear | stack, with max hearts never below 1].",
    "potential_consequence": "Instant death from picking up an item, or an unbounded damage stack."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Consommables › Sablier",
    "trigger_condition": "The rewind's scope isn't defined: are consumables used, items picked up, lucidity and curses gained in the room restored? Can you use it in a boss room?",
    "guard_snippet": "Rule: restore HP and lucidity only; items and consumables are kept; can't be used in boss rooms (or: allowed, with the boss enraged).",
    "potential_consequence": "A duplication exploit or a confusing rewind."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Consommables › Verre d'eau + Pactes",
    "trigger_condition": "Using it with no curse isn't covered, and it's unclear whether pact curses can be purged. If they can, pacts become free power.",
    "guard_snippet": "Rule: pact curses can't be purged (or purging also removes the pact power); with no curse, it only rolls the add-a-curse chance.",
    "potential_consequence": "Pacts get trivialized by a common consumable."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Pactes › Sans voix",
    "trigger_condition": "Taking the pact while holding consumables isn't covered.",
    "guard_snippet": "Rule: held consumables are [dropped | kept but locked | turned into lucidity].",
    "potential_consequence": "Inconsistent behavior and a possible loss of player resources."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Pactes › Portes mouvantes",
    "trigger_condition": "The map reorganizes after every room. There's no guarantee the boss stays reachable, and backtracking to uncleared or treasure rooms isn't handled.",
    "guard_snippet": "Rule: rebuild only unvisited rooms, and always keep a path to the boss.",
    "potential_consequence": "Softlocks, or unreachable rewards."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Pactes (choix)",
    "trigger_condition": "Refusing every pact ('jouer la sécurité') has no defined result.",
    "guard_snippet": "Rule: refusing = no change, or a small heal or lucidity refill, so playing it safe is an actual option.",
    "potential_consequence": "Either pacts are mandatory in practice or refusing is the dominant choice."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Consommables › Regarder ses mains / Boîte à musique",
    "trigger_condition": "The 1 s immobilization during a boss fight or bullet-hell isn't covered, and neither is whether the Boîte à musique affects bosses.",
    "guard_snippet": "Rule: invulnerable during Regarder ses mains, or say explicitly that it isn't; bosses are immune to sleep (or only slowed).",
    "potential_consequence": "Unfair deaths, or bosses trivialized."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Objets › Miroir + Pactes › On te regarde + Cauchemars › Toi",
    "trigger_condition": "Several 'double' entities can be active at once (the Miroir's evil double, the watching presence, the 'Toi' boss), and nothing defines how they interact or how players tell them apart.",
    "guard_snippet": "Rule: give each its own silhouette and color, and suppress the Miroir double during the 'Toi' fight.",
    "potential_consequence": "Visual confusion in the climactic fight and broken readability."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Pactes › Visage oublié + Sommeil profond (salles sombres)",
    "trigger_condition": "The player appears only as a shadow, in dark rooms, so they may not be visible at all.",
    "guard_snippet": "Rule: always draw an outline or hitbox marker for the player, whatever the pact or lighting.",
    "potential_consequence": "The player can't see their own position, so deaths feel unfair."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Objets et synergies › Fragments de souvenirs",
    "trigger_condition": "A story fragment is tied to a synergy whose items may not be unlocked yet, or whose random drops rarely line up.",
    "guard_snippet": "Rule: fragment synergies only use items already unlocked, with a pity mechanic or guaranteed offer after N runs.",
    "potential_consequence": "Story progress stalls on RNG and a key fragment may never be seen."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Boucle de jeu (victoire) + Hub › Le réveil",
    "trigger_condition": "Finishing a run (beating the last available nightmare) has no defined outcome, since only 'death = waking up' is specified, and the death-clock time formula isn't defined.",
    "guard_snippet": "Rule: win = [wake up with a special scene / clock shows a target time]; clock time = f(depth reached, time spent). Decide whether dying exactly at 4:12 means something.",
    "potential_consequence": "No closure on success, and the disguised score means nothing."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Histoire et mystère › Fins",
    "trigger_condition": "Precedence when several ending conditions are met at once isn't defined.",
    "guard_snippet": "Rule: a strict priority order or an explicit choice point at the end of Act 3.",
    "potential_consequence": "Endings trigger unpredictably."
  },
  {
    "lens": "edge-case-hunter",
    "location": "Boucle de jeu",
    "trigger_condition": "Quitting mid-run (save and resume vs. abandon) isn't addressed.",
    "guard_snippet": "Rule: suspend-save on quit, deleted on load (or: quitting counts as waking up).",
    "potential_consequence": "Save-scumming, or lost runs on Steam Deck / suspend."
  }
]
```
