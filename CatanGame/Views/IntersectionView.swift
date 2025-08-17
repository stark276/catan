import SwiftUI

/// Renders an intersection (vertex) on the board.  Depending on
/// occupancy it shows an empty outline, a coloured circle for a
/// settlement, or a filled square for a city.  The `tapAction` is
/// invoked when the intersection is tapped, enabling building actions.
public struct IntersectionView: View {
    let occupant: IntersectionOccupant?
    let playerColor: Color?
    let radius: CGFloat
    let tapAction: () -> Void

    public init(occupant: IntersectionOccupant?, playerColor: Color?, radius: CGFloat, tapAction: @escaping () -> Void) {
        self.occupant = occupant
        self.playerColor = playerColor
        self.radius = radius
        self.tapAction = tapAction
    }

    public var body: some View {
        Group {
            if let occupant = occupant, let color = playerColor {
                switch occupant {
                case .settlement:
                    Circle()
                        .fill(color)
                        .frame(width: radius * 0.5, height: radius * 0.5)
                case .city:
                    RoundedRectangle(cornerRadius: radius * 0.1)
                        .fill(color)
                        .frame(width: radius * 0.6, height: radius * 0.6)
                }
            } else {
                Circle()
                    .stroke(Color.gray, lineWidth: 1)
                    .background(Circle().fill(Color.white.opacity(0.3)))
                    .frame(width: radius * 0.4, height: radius * 0.4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            tapAction()
        }
    }
}