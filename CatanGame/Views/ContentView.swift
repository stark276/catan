import SwiftUI

/// The main view presenting the entire game interface.  It displays the
/// board, players' status, a dice roll button, build actions, and
/// messages.  Interaction with the board is handled via tap
/// gestures on intersections and roads.
public struct ContentView: View {
    @StateObject private var gameState = GameState(playerCount: 4)

    public var body: some View {
        VStack(spacing: 8) {
            // Player status cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(gameState.players) { player in
                        PlayerCardView(player: player, isCurrent: player.id == gameState.currentPlayerIndex)
                    }
                }
                .padding(.horizontal)
            }

            // Board area
            GeometryReader { geometry in
                ZStack {
                    // Roads
                    ForEach(gameState.roads) { road in
                        RoadView(start: gameState.position(forIntersection: road.from, in: geometry.size),
                                 end: gameState.position(forIntersection: road.to, in: geometry.size),
                                 occupant: road.occupant,
                                 playerColor: road.occupant != nil ? gameState.players[road.occupant!].color : nil,
                                 tapAction: {
                                    gameState.placeRoad(at: road.id)
                                 })
                    }
                    // Tiles
                    ForEach(gameState.tiles) { tile in
                        let centre = gameState.position(forTile: tile, in: geometry.size)
                        let radius = gameState.hexScale(in: geometry.size) * 0.95 // small shrink to avoid overlaps
                        HexTileView(tile: tile, radius: radius)
                            .position(x: centre.x, y: centre.y)
                    }
                    // Intersections
                    ForEach(gameState.intersections) { intersection in
                        let pos = gameState.position(forIntersection: intersection.id, in: geometry.size)
                        let radius = gameState.hexScale(in: geometry.size)
                        IntersectionView(occupant: intersection.occupant,
                                        playerColor: {
                                            if let occupant = intersection.occupant {
                                                switch occupant {
                                                case .settlement(let pid): return gameState.players[pid].color
                                                case .city(let pid): return gameState.players[pid].color
                                                }
                                            }
                                            return nil
                                        }(),
                                        radius: radius,
                                        tapAction: {
                                            // Build settlement or upgrade city depending on current state
                                            if let occupant = intersection.occupant {
                                                switch occupant {
                                                case .settlement(let owner) where owner == gameState.currentPlayerIndex:
                                                    gameState.upgradeToCity(at: intersection.id)
                                                default:
                                                    break
                                                }
                                            } else {
                                                gameState.placeSettlement(at: intersection.id)
                                            }
                                        })
                        .position(x: pos.x, y: pos.y)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding([.leading, .trailing], 8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )

            // Dice roll and action buttons
            HStack(spacing: 16) {
                Button(action: {
                    gameState.rollDice()
                }) {
                    VStack {
                        Text("Roll Dice")
                            .font(.headline)
                        if gameState.diceResult > 0 {
                            Text("Result: \(gameState.diceResult)")
                                .font(.subheadline)
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.2)))
                }
                Button(action: {
                    // End turn advances to next player
                    gameState.currentPlayerIndex = (gameState.currentPlayerIndex + 1) % gameState.players.count
                }) {
                    Text("End Turn")
                        .font(.headline)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.2)))
                }
            }
            .padding(.bottom, 4)
            // Last message
            Text(gameState.lastMessage)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(.top, 8)
    }
}

// Provide a preview for Xcode's canvas.  Note: Previews will not
// compile in this environment but are included for completeness.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.sizeThatFits)
    }
}