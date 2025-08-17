import SwiftUI

/// Displays a summary of a player's status including name, resources,
/// and victory points.  Highlights the card when it is the current
/// player's turn.
public struct PlayerCardView: View {
    let player: Player
    let isCurrent: Bool

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(player.color)
                    .frame(width: 12, height: 12)
                Text(player.name)
                    .font(.headline)
            }
            // Resource counts
            VStack(alignment: .leading, spacing: 2) {
                ForEach(ResourceType.allCases.filter { $0 != .desert }, id: \ .self) { resource in
                    HStack {
                        Text(resource.displayName + ":")
                            .font(.caption2)
                        Spacer()
                        Text("\(player.resources[resource, default: 0])")
                            .font(.caption2)
                    }
                }
            }
            HStack {
                Text("Settlements: \(player.settlements)")
                    .font(.caption2)
                Spacer()
                Text("Cities: \(player.cities)")
                    .font(.caption2)
                Spacer()
                Text("Roads: \(player.roads)")
                    .font(.caption2)
            }
            HStack {
                Text("Victory Points: \(player.victoryPoints)")
                    .font(.caption2)
                Spacer()
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 8)
                        .fill(isCurrent ? Color.yellow.opacity(0.3) : Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(isCurrent ? Color.orange : Color.gray.opacity(0.3), lineWidth: isCurrent ? 2 : 1))
        .frame(width: 160)
    }
}