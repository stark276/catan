import SwiftUI

/// Entry point for the iOS Catan game application.  This struct
/// conforms to the `App` protocol and creates the main window
/// containing the `ContentView`.
@main
struct CatanGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}