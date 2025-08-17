import SwiftUI

/// Draws a straight line between two points representing a road.  If
/// claimed by a player, the line is drawn in that player's colour and
/// with a thicker stroke.  Otherwise, a thin grey line is drawn.
public struct RoadView: View {
    let start: CGPoint
    let end: CGPoint
    let occupant: Int?
    let playerColor: Color?
    let tapAction: () -> Void

    public init(start: CGPoint, end: CGPoint, occupant: Int?, playerColor: Color?, tapAction: @escaping () -> Void) {
        self.start = start
        self.end = end
        self.occupant = occupant
        self.playerColor = playerColor
        self.tapAction = tapAction
    }

    public var body: some View {
        Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(occupant != nil ? (playerColor ?? Color.primary) : Color.gray, lineWidth: occupant != nil ? 6 : 2)
        .contentShape(Rectangle())
        .onTapGesture {
            tapAction()
        }
    }
}