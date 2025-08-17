import SwiftUI

/// Represents a single hexagonal tile on the Catan board.  Each tile has
/// an axial coordinate (q, r) indicating its location in the hex grid,
/// a resource type, and a dice number token.  The number is `7` for the
/// robber/desert tile or `0` if unassigned.
public struct HexTile: Identifiable {
    public let id: UUID
    public let resource: ResourceType
    public let number: Int
    public let q: Int
    public let r: Int

    public init(resource: ResourceType, number: Int, q: Int, r: Int) {
        self.id = UUID()
        self.resource = resource
        self.number = number
        self.q = q
        self.r = r
    }
}