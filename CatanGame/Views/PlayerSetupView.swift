import SwiftUI

/// View allowing up to four players to enter their names before the game starts.
public struct PlayerSetupView: View {
    @State private var names: [String] = ["", "", "", ""]
    public var startGame: ([String]) -> Void

    public init(startGame: @escaping ([String]) -> Void) {
        self.startGame = startGame
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Enter Player Names")
                .font(.headline)
            ForEach(0..<4, id: \.self) { i in
                TextField("Player \(i+1) name", text: $names[i])
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
            }
            Button("Start Game") {
                startGame(names)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.2)))
        }
        .padding()
    }
}

struct PlayerSetupView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerSetupView { _ in }
            .previewLayout(.sizeThatFits)
    }
}
