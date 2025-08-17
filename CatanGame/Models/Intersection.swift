import SwiftUI

/// Encodes the type of structure built on an intersection.  A settlement
/// is upgraded to a city by the occupying player.
public enum IntersectionOccupant: Equatable {
    case settlement(player: Int)
    case city(player: Int)
}

/// Represents an intersection (vertex) on the Catan board.  Each
/// intersection corresponds to the meeting point of up to three
/// hexagonal tiles.  Intersections can hold either a settlement or a
/// city.  They also maintain links to adjacent tiles and neighbouring
/// intersections via roads.
public struct Intersection: Identifiable {
    public let id: Int
    public var position: CGPoint
    public var adjacentTiles: [Int] // indexes of tiles touching this vertex
    public var adjacentIntersections: Set<Int> // neighbours by road
    public var occupant: IntersectionOccupant?

    public init(id: Int, position: CGPoint, adjacentTiles: [Int]) {
        self.id = id
        self.position = position
        self.adjacentTiles = adjacentTiles
        self.adjacentIntersections = []
        self.occupant = nil
    }
}