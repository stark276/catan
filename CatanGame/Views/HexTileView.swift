import SwiftUI

/// A view representing a single hexagonal tile.  It draws a hex with
/// pointy‑top orientation, fills it with the resource colour, and
/// overlays the number token if applicable.  The view assumes it will
/// be positioned by its parent; the `center` property is used by
/// ContentView to place it correctly.
public struct HexTileView: View {
    public let tile: HexTile
    public let radius: CGFloat

    public var body: some View {
        ZStack {
            // Hexagon shape filled with resource colour
            HexagonShape(radius: radius)
                .fill(tile.resource.color)
            HexagonShape(radius: radius)
                .stroke(Color.black, lineWidth: radius * 0.05)
            // Display number token except on the desert (number 7)
            if tile.resource != .desert {
                Circle()
                    .fill(Color.white)
                    .frame(width: radius * 0.8, height: radius * 0.8)
                Text("\(tile.number)")
                    .font(.system(size: radius * 0.5, weight: .bold, design: .rounded))
                    .foregroundColor(Color.black)
            } else {
                // mark desert tile with robber icon or text
                Text("🐺")
                    .font(.system(size: radius * 0.8))
            }
        }
    }
}

/// Draws a pointy‑topped hexagon centred at the origin with the provided radius.
fileprivate struct HexagonShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Since this shape is expected to be centred at (0,0) when used,
        // draw relative to rect centre.  However, we ignore rect and use
        // origin as the centre.
        for i in 0..<6 {
            let angle = (Double(i) * 60.0 - 30.0) * Double.pi / 180.0
            let x = radius * CGFloat(cos(angle))
            let y = radius * CGFloat(sin(angle))
            let point = CGPoint(x: x + rect.midX, y: y + rect.midY)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}