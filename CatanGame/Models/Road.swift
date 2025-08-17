import Foundation

/// Represents a road segment connecting two intersections on the Catan
/// board.  A road can only be built if it is currently unoccupied and
/// connects two adjacent intersections.  The occupant stores the id
/// of the player who built the road.
public struct Road: Identifiable {
    public let id: Int
    public let from: Int
    public let to: Int
    public var occupant: Int?

    public init(id: Int, from: Int, to: Int) {
        self.id = id
        self.from = from
        self.to = to
        self.occupant = nil
    }
}