# Goals and philosophy

[한국어](../ko/philosophy.md) · [Contents](index.md)

This page holds the principles the user set. When implementation choices diverge, this page decides.

## Goal and name

**DoGS — Dogs of Good Sense** turns dogs in Cataclysm: Bright Nights (BN) into tactical companions that read the situation, adjust their position and disrupt enemies. The name stands for good judgment and discernment. The lowercase o comes from "of."

## The dog's place

A DoGS dog is a companion that fights alongside the player, not a combatant that finishes enemies on its own.

- **It protects the player.** It stays by the player and takes on enemies that approach the player.
- **It ties enemies down.** It knocks them down and bites their ankles, creating openings for the player and disrupting other enemies' attacks.
- **It survives.** When encirclement looms, it moves out without hesitation. When wounded, it leaves the fight and returns to the player.

Which of these comes first is set by the player through the role (Guard, Harass, Free).

## Design principles

- Prioritize positioning, risk avoidance, enemy separation, intervention timing and disengagement over increased stats or damage.
- When an action is chosen matters more than what the dog can do.
- Do not add attacks that a normal dog's anatomy cannot explain.
- Do not add features whose implementation cost outweighs their play value.
- Target BN; do not assume DDA implementations carry over unchanged.

## Trained-dog behavior

Prefer short decisions and understandable, repeatable patterns over an AI that predicts the future perfectly. The dog has a strong survival instinct and can abandon a plan when things go badly.

Control actions are takedowns, body checks, ankle disruption, and brief bites followed by withdrawal. Bites are for physical wounds and mobility disruption.

## Principles set on 2026-10-05

Principles the user set during the experiments.

- **Control attacks are support.** Their purpose is not for the dog to kill alone but to support the player's attacks and disrupt other enemies. Their value is judged with the player fighting alongside.
- **The player directs the role; the dog judges the method.** The player assigns each dog a role (Guard, Harass, Free). Within it, the dog decides when and how to act.
- **Not losing the dog comes first.** A trained dog guards by default. A dog that runs off toward distant enemies is easily lost.
- **Remove the enemy in front of you quickly.** Even while guarding, the dog fights an enemy right in front of it with normal attacks.
- **The dog judges only by what it can perceive and remember.** A dog does not know what a gun or bow is, but after a shot it can remember that something flies along that path. Mistakes from this limit are acceptable to the player as a dog's limitation.
- **A wounded dog returns to its handler.** At low HP the dog leaves the fight and falls back behind the player; ending the situation is the player's job.

## Scope

The dog judges within the role the player assigns. Against a zombie group, it lures the outermost enemy first, separates it, leaves it straggling and returns (the Harass role). Current designs: [behavior design](design.md) and [Harass role](harass.md).
