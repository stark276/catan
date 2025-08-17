import SwiftUI

/// Represents a player in the Catan game.  Each player has a unique
/// identifier, a display name, a color used for rendering their pieces,
/// a collection of resources, and counters for built settlements, roads
/// and cities.  Players also earn victory points through their builds.
public struct Player: Identifiable {
    public let id: Int
    public let name: String
    public let color: Color
    public var resources: [ResourceType: Int]
    public var settlements: Int
    public var roads: Int
    public var cities: Int
    public var victoryPoints: Int

    /// Creates a new player with the provided id, name and color.  All
    /// resources and build counters are initialised to zero.
    public init(id: Int, name: String, color: Color) {
        self.id = id
        self.name = name
        self.color = color
        self.resources = [:]
        for type in ResourceType.allCases {
            self.resources[type] = 0
        }
        self.settlements = 0
        self.roads = 0
        self.cities = 0
        self.victoryPoints = 0
    }
}