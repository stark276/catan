# Catan iOS Game

This repository contains a simplified implementation of the classic
board game *Catan* written in Swift using SwiftUI.  The goal of
the project is to demonstrate the core mechanics of the game —
resource generation, settlement and road placement, city upgrades,
turn management and scoring — inside a fully native iOS application.

> **Important**: This implementation is intended for educational
> purposes.  It is not a complete or polished recreation of the
> commercial Catan game and omits several advanced rules such as
> development cards, the robber/knight mechanics, longest road and
> largest army awards, harbors, trading and multiplayer networking.

## Features

* Procedurally generated board with 19 hexes laid out in a 3–4–5–4–3
  configuration using axial coordinates.
* Randomised resource tile assignment (wood, sheep, grain, brick,
  ore and a single desert) and number tokens (2–12 except 7 for the
  desert) on each new game.
* Interactive hex map scaled to fit any device screen, drawn with
  crisp vector graphics.
* Tap intersections to build a settlement (if empty and you can
  afford it).  Tap an owned settlement again to upgrade it to a city.
* Tap road edges to build roads connected to your existing network.
* Roll dice to produce resources for settlements and cities on
  matching numbers.
* Turn tracker and resource/victory point display for up to four
  players.

## Running the App

1. Ensure you have Xcode 15 or later installed on a Mac with the iOS
   17 SDK.  SwiftUI is required to run this project.
2. Clone or copy this folder to your Mac.
3. Open `CatanGameApp.swift` in Xcode or simply open the project
   directory by choosing **File → Open** in Xcode and selecting the
   directory containing `CatanGameApp.swift`.
4. Select an iOS Simulator (e.g. iPhone 15) or your connected device
   and press **Run**.

## Gameplay Notes

* At the start of the game all players have zero resources.  Use the
  “Roll Dice” button to produce resources based on settlements and
  cities already on the board.  You may wish to give each player a
  few starting resources by modifying the `Player` initialiser.
* Building a settlement costs 1 wood, 1 brick, 1 grain and 1 sheep;
  upgrading to a city costs 2 grain and 3 ore; building a road costs
  1 wood and 1 brick.
* Settlement placement obeys the distance rule: no two settlements can
  be adjacent.  Road placement requires that the road connect to one
  of your existing roads or settlements, except that the first road
  may be placed anywhere.
* A simple turn system is implemented via the **End Turn** button.
  Players may perform any number of actions (roll, build, upgrade)
  during their turn before ending it.
* Dice rolls of 7 currently only print a message; robber mechanics
  (stealing and discarding) are not implemented.

## Extending the Game

There are many ways to enhance this project:

* Implement the robber and knight cards, including discarding
  resources and moving the robber to block resource generation.
* Add development cards, longest road and largest army scoring,
  harbors and resource trading between players and the bank.
* Introduce an AI opponent or online multiplayer using GameKit.
* Add proper graphics for settlements, cities and roads.
* Incorporate sound effects and animations.

Pull requests are welcome if you want to contribute improvements!