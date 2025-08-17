import SwiftUI

/// Represents the various resources available in a Catan game.
/// Each resource provides a color for rendering on the game board and
/// a human‑readable name.  The desert tile produces no resources.
public enum ResourceType: String, CaseIterable, Codable {
    case lumber   // wood
    case wool     // sheep
    case grain    // wheat
    case brick    // clay/brick
    case ore
    case desert

    /// A displayable name for the resource.  This value is used in UI labels.
    var displayName: String {
        switch self {
        case .lumber: return "Wood"
        case .wool:   return "Sheep"
        case .grain:  return "Grain"
        case .brick:  return "Brick"
        case .ore:    return "Ore"
        case .desert: return "Desert"
        }
    }

    /// Color used to render the hex tile corresponding to this resource.
    var color: Color {
        switch self {
        case .lumber: return Color(red: 0.67, green: 0.88, blue: 0.40) // soft green
        case .wool:   return Color(red: 0.86, green: 0.98, blue: 0.70) // pale green
        case .grain:  return Color(red: 0.99, green: 0.97, blue: 0.69) // yellowish
        case .brick:  return Color(red: 0.93, green: 0.45, blue: 0.36) // reddish
        case .ore:    return Color(red: 0.71, green: 0.71, blue: 0.71) // gray
        case .desert: return Color(red: 0.94, green: 0.83, blue: 0.63) // beige
        }
    }
}