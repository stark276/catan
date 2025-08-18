import SwiftUI

/// Entry point for the iOS Catan game application.  This struct
/// conforms to the `App` protocol and creates the main window
/// containing the `ContentView`.
@main
struct CatanGameApp: App {
    @State private var gameState: GameState? = nil

    var body: some Scene {
        WindowGroup {
            if let gameState = gameState {
                ContentView(gameState: gameState)
            } else {
                PlayerSetupView { names in
                    gameState = GameState(playerCount: 4, playerNames: names)
                }
            }
        }
    }
}