import SwiftUI
import Foundation

/// Central game model controlling board state, players and game flow.  This
/// class is responsible for generating the hexagonal map, computing
/// intersection and road connectivity, updating the current player, and
/// distributing resources on dice rolls.  It exposes published
/// properties so that SwiftUI views automatically update when the state
/// changes.
public final class GameState: ObservableObject {
    // MARK: - Published Properties

    /// The collection of hex tiles constituting the game board.  Each
    /// tile has a resource type, number token and axial coordinates.
    @Published public private(set) var tiles: [HexTile] = []

    /// Intersection vertices where players build settlements and cities.
    @Published public private(set) var intersections: [Intersection] = []

    /// Road segments connecting intersections.  Each road can be
    /// claimed by a player.
    @Published public private(set) var roads: [Road] = []

    /// List of players participating in the game.  The index into this
    /// array corresponds to the player's id.
    @Published public private(set) var players: [Player] = []

    /// Index of the current player in the players array.  The current
    /// player may perform actions such as building and rolling dice.
    @Published public var currentPlayerIndex: Int = 0

    /// Indicates whether the game is in the initial setup phase where players
    /// place their first settlements and roads for free.
    @Published public var setupPhase: Bool = true

    /// Tracks the required action during setup: players must place a settlement
    /// then a road before ending their turn.
    public enum SetupStage { case settlement, road, done }
    @Published public var setupStage: SetupStage = .settlement

    /// Remaining time for the current player's turn in seconds.
    @Published public var timeRemaining: Int = 100

    /// The most recent dice roll (sum of two six‑sided dice).  A value
    /// of 7 indicates the robber was rolled.  A value of 0 indicates no
    /// roll has occurred yet.
    @Published public private(set) var diceResult: Int = 0

    /// A text message describing the last significant event (dice roll,
    /// invalid build attempt, etc.).  The UI can display this to
    /// provide feedback to the user.
    @Published public private(set) var lastMessage: String = ""

    // MARK: - Private Properties

    /// Relative positions of tile centres computed at generation time.
    /// These positions assume a hex radius of 1; scaling to actual
    /// screen coordinates occurs in the `position(for:in:)` helper.
    private var tileRelativeCenters: [UUID: CGPoint] = [:]

    /// Bounding box of all relative positions (including intersections)
    /// used to scale and centre the board within the view.  These
    /// values are computed when generating the board.
    private var minRelativeX: CGFloat = 0
    private var maxRelativeX: CGFloat = 0
    private var minRelativeY: CGFloat = 0
    private var maxRelativeY: CGFloat = 0

    /// For each tile index, holds the indices of the 6 intersections
    /// (vertices) making up that tile, ordered clockwise.  This is
    /// helpful when determining which settlements receive resources on
    /// dice rolls.
    private var tileCornerIndices: [[Int]] = []

    /// Count of initial settlement/road pairs each player has placed.
    private var setupPairsBuilt: [Int] = []

    /// Timer handling the countdown for each player's turn.
    private var turnTimer: Timer?

    // MARK: - Initialiser

    /// Create a new game state with a standard Catan board.  You may
    /// optionally supply player names; otherwise defaults are used.
    /// - Parameters:
    ///   - playerCount: Number of players (typically 3–4).  Values
    ///     outside 2–4 are clamped.
    ///   - playerNames: Optional list of names for each player.
    ///     Only the first `playerCount` names are used.
    public init(playerCount: Int = 4, playerNames: [String]? = nil) {
        let count = max(2, min(playerCount, 4))
        self.setupPlayers(count: count, names: playerNames)
        self.generateBoard()
        self.setupPairsBuilt = Array(repeating: 0, count: count)
        self.currentPlayerIndex = Int.random(in: 0..<count)
        self.startTurnTimer()
    }

    // MARK: - Setup Methods

    /// Create the players array with default colours and names.  The
    /// colours are chosen to contrast on the board.  If custom names
    /// are supplied, they override the defaults.
    private func setupPlayers(count: Int, names: [String]? = nil) {
        let defaultNames = ["Red", "Blue", "Green", "Orange"]
        let defaultColors: [Color] = [.red, .blue, .green, .orange]
        let trimmedNames = (names ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var players: [Player] = []
        for i in 0..<count {
            let provided = i < trimmedNames.count ? trimmedNames[i] : ""
            let name = provided.isEmpty ? (i < defaultNames.count ? defaultNames[i] : "Player \(i+1)") : provided
            let color = i < defaultColors.count ? defaultColors[i] : Color(
                hue: Double(i) / Double(count),
                saturation: 0.7,
                brightness: 0.8
            )
            players.append(Player(id: i, name: name, color: color))
        }
        self.players = players
    }

    /// Generate a new board, intersections and roads.  This method
    /// randomises resource placement and number tokens, then computes
    /// relative positions, intersection clustering and adjacency graphs.
    private func generateBoard() {
        // Clear existing state
        self.tiles.removeAll()
        self.intersections.removeAll()
        self.roads.removeAll()
        self.tileCornerIndices.removeAll()
        self.tileRelativeCenters.removeAll()

        // 1. Generate axial coordinates for the 19 hexes.  Use the
        // constraint |q + r| <= 2 with q, r in [-2, 2].
        var axialCoords: [(q: Int, r: Int)] = []
        for q in -2...2 {
            for r in -2...2 {
                let s = -q - r
                if s >= -2 && s <= 2 {
                    axialCoords.append((q, r))
                }
            }
        }
        // Sort coordinates to keep a consistent ordering (optional)
        axialCoords.sort { (a, b) -> Bool in
            if a.r == b.r { return a.q < b.q }
            return a.r < b.r
        }

        // 2. Prepare resource and number pools for random assignment
        var resourcesPool: [ResourceType] = []
        resourcesPool += Array(repeating: .lumber, count: 4)
        resourcesPool += Array(repeating: .wool,   count: 4)
        resourcesPool += Array(repeating: .grain,  count: 4)
        resourcesPool += Array(repeating: .brick,  count: 3)
        resourcesPool += Array(repeating: .ore,    count: 3)
        resourcesPool += [.desert]
        resourcesPool.shuffle()

        // Number tokens: one each of 2 and 12, two each of 3–6 and 8–11.  7 is reserved for the robber/desert.
        var numberPool: [Int] = [2, 12]
        numberPool += Array(repeating: 3, count: 2)
        numberPool += Array(repeating: 4, count: 2)
        numberPool += Array(repeating: 5, count: 2)
        numberPool += Array(repeating: 6, count: 2)
        numberPool += Array(repeating: 8, count: 2)
        numberPool += Array(repeating: 9, count: 2)
        numberPool += Array(repeating: 10, count: 2)
        numberPool += Array(repeating: 11, count: 2)
        numberPool.shuffle()

        // 3. Create HexTile objects with assigned resources and numbers
        var tiles: [HexTile] = []
        var desertIndex: Int? = nil
        var numberIndex = 0
        for coord in axialCoords {
            let resource = resourcesPool.removeFirst()
            let number: Int
            if resource == .desert {
                number = 7
                desertIndex = tiles.count
            } else {
                number = numberPool[numberIndex]
                numberIndex += 1
            }
            let tile = HexTile(resource: resource, number: number, q: coord.q, r: coord.r)
            tiles.append(tile)
        }
        self.tiles = tiles

        // 4. Compute relative positions for tile centres using a unit radius of 1
        var centers: [UUID: CGPoint] = [:]
        for tile in tiles {
            let q = CGFloat(tile.q)
            let r = CGFloat(tile.r)
            let x = sqrt(3) * (q + r/2)
            let y = 3.0/2.0 * r
            centers[tile.id] = CGPoint(x: x, y: y)
        }
        self.tileRelativeCenters = centers

        // 5. Generate intersections by iterating over each tile's 6 corners
        var intersections: [Intersection] = []
        var tileCornerIndices: [[Int]] = Array(repeating: [], count: tiles.count)

        // Helper to find or create an intersection at a given relative position
        func findOrCreateIntersection(at point: CGPoint, tileIndex: Int) -> Int {
            // Try to find an existing intersection within epsilon distance
            let epsilon: CGFloat = 0.01
            for (i, inter) in intersections.enumerated() {
                let dx = inter.position.x - point.x
                let dy = inter.position.y - point.y
                if dx*dx + dy*dy < epsilon * epsilon {
                    // Found an existing intersection: update its adjacent tiles
                    if !intersections[i].adjacentTiles.contains(tileIndex) {
                        intersections[i].adjacentTiles.append(tileIndex)
                    }
                    return i
                }
            }
            // Create new intersection
            let newIndex = intersections.count
            var newIntersection = Intersection(id: newIndex, position: point, adjacentTiles: [tileIndex])
            intersections.append(newIntersection)
            return newIndex
        }

        // For each tile compute its six corner positions (pointy top orientation)
        for (tIdx, tile) in tiles.enumerated() {
            guard let center = centers[tile.id] else { continue }
            var cornerIndices: [Int] = []
            for i in 0..<6 {
                // For pointy top orientation, angles offset by -30°
                let angle = (Double(i) * 60.0 - 30.0) * Double.pi / 180.0
                let x = center.x + cos(angle)
                let y = center.y + sin(angle)
                let cornerPoint = CGPoint(x: x, y: y)
                let idx = findOrCreateIntersection(at: cornerPoint, tileIndex: tIdx)
                cornerIndices.append(idx)
            }
            tileCornerIndices[tIdx] = cornerIndices
        }
        self.intersections = intersections
        self.tileCornerIndices = tileCornerIndices

        // 6. Generate roads between adjacent intersections (edges of tiles)
        var roads: [Road] = []
        var roadKeyToIndex: [String: Int] = [:]
        // Helper to create a key from two indices (order independent)
        func key(from i: Int, _ j: Int) -> String {
            return i < j ? "\(i)-\(j)" : "\(j)-\(i)"
        }
        for cornerIndices in tileCornerIndices {
            let n = cornerIndices.count
            for i in 0..<n {
                let a = cornerIndices[i]
                let b = cornerIndices[(i + 1) % n]
                let k = key(from: a, b)
                if roadKeyToIndex[k] == nil {
                    let roadIndex = roads.count
                    roads.append(Road(id: roadIndex, from: a, to: b))
                    roadKeyToIndex[k] = roadIndex
                    // update intersection adjacency
                    intersections[a].adjacentIntersections.insert(b)
                    intersections[b].adjacentIntersections.insert(a)
                }
            }
        }
        self.roads = roads
        // update intersections property (since we mutated intersections after building roads)
        self.intersections = intersections

        // 7. Compute bounding box of relative positions for scaling
        var minX: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude
        for inter in intersections {
            let p = inter.position
            if p.x < minX { minX = p.x }
            if p.x > maxX { maxX = p.x }
            if p.y < minY { minY = p.y }
            if p.y > maxY { maxY = p.y }
        }
        self.minRelativeX = minX
        self.maxRelativeX = maxX
        self.minRelativeY = minY
        self.maxRelativeY = maxY
    }

    // MARK: - Position Scaling

    /// Convert a relative position (as used internally for tiles and
    /// intersections) into a pixel coordinate within the provided
    /// drawing area.  This method ensures that the board fits within
    /// `size` with a margin.
    /// - Parameters:
    ///   - point: Relative coordinates of a tile centre or intersection.
    ///   - size: Size of the drawing view.
    ///   - marginFactor: Percentage of padding applied around the board
    ///     (0–1).  A value of 0.1 leaves a 10% margin on each side.
    /// - Returns: The scaled and translated coordinate in view space.
    public func scalePosition(_ point: CGPoint, in size: CGSize, marginFactor: CGFloat = 0.1) -> CGPoint {
        let boardWidth = maxRelativeX - minRelativeX
        let boardHeight = maxRelativeY - minRelativeY
        // avoid division by zero
        guard boardWidth > 0 && boardHeight > 0 else { return CGPoint(x: size.width/2, y: size.height/2) }
        // choose uniform scale to fit board in view minus margins
        let availableWidth = size.width * (1.0 - marginFactor)
        let availableHeight = size.height * (1.0 - marginFactor)
        let scale = min(availableWidth / boardWidth, availableHeight / boardHeight)
        // compute offset to centre the board
        let offsetX = size.width/2 - ((minRelativeX + maxRelativeX) / 2 * scale)
        let offsetY = size.height/2 - ((minRelativeY + maxRelativeY) / 2 * scale)
        return CGPoint(x: point.x * scale + offsetX, y: point.y * scale + offsetY)
    }

    /// Compute the scale factor (tile radius) for the given view size.  This
    /// scale factor is equivalent to the `scale` used in `scalePosition` and
    /// represents the number of pixels per unit length of the relative
    /// board.  Use this value to compute the radius of hexes when
    /// drawing.
    /// - Parameters:
    ///   - size: The size of the drawing area.
    ///   - marginFactor: Percentage of space reserved as margin around the board.
    /// - Returns: Pixels per unit relative length (radius of a hex).  Returns zero if the board size is undefined.
    public func hexScale(in size: CGSize, marginFactor: CGFloat = 0.1) -> CGFloat {
        let boardWidth = maxRelativeX - minRelativeX
        let boardHeight = maxRelativeY - minRelativeY
        guard boardWidth > 0 && boardHeight > 0 else { return 0 }
        let availableWidth = size.width * (1.0 - marginFactor)
        let availableHeight = size.height * (1.0 - marginFactor)
        return min(availableWidth / boardWidth, availableHeight / boardHeight)
    }

    /// Convenience to obtain a pixel coordinate for a tile centre.
    public func position(forTile tile: HexTile, in size: CGSize) -> CGPoint {
        if let relative = tileRelativeCenters[tile.id] {
            return scalePosition(relative, in: size)
        }
        return CGPoint(x: size.width/2, y: size.height/2)
    }

    /// Convenience to obtain a pixel coordinate for an intersection by id.
    public func position(forIntersection index: Int, in size: CGSize) -> CGPoint {
        guard index >= 0 && index < intersections.count else {
            return CGPoint(x: size.width/2, y: size.height/2)
        }
        let relative = intersections[index].position
        return scalePosition(relative, in: size)
    }

    // MARK: - Game Logic

    /// Start or reset the countdown timer for the current player's turn.
    private func startTurnTimer() {
        timeRemaining = 100
        turnTimer?.invalidate()
        turnTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.lastMessage = "Time's up for \(self.players[self.currentPlayerIndex].name)."
                self.advancePlayer()
            }
        }
    }

    /// End the current player's turn and move to the next one. During the setup
    /// phase players must place a settlement and road before ending.
    public func endTurn() {
        if setupPhase && setupStage != .done {
            lastMessage = "Place a settlement and road before ending your turn."
            return
        }
        advancePlayer()
    }

    /// Advance to the next player, updating setup state and restarting the timer.
    private func advancePlayer() {
        if setupPhase && setupPairsBuilt.allSatisfy({ $0 >= 2 }) {
            setupPhase = false
        }
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        setupStage = setupPhase ? .settlement : .done
        startTurnTimer()
    }

    /// Roll two six‑sided dice and distribute resources accordingly.
    public func rollDice() {
        guard !setupPhase else {
            lastMessage = "Finish initial placements before rolling the dice."
            return
        }
        let dice = Int.random(in: 1...6) + Int.random(in: 1...6)
        diceResult = dice
        if dice == 7 {
            lastMessage = "Robber rolled – no production this turn."
            // robber handling (discard and robber placement) omitted
        } else {
            distributeResources(for: dice)
            lastMessage = "Player \(players[currentPlayerIndex].name) rolled a \(dice)."
        }
        // After rolling dice, the player may build roads/settlements; not advancing automatically.
    }

    /// Distribute resources to players based on settlements and cities adjacent to
    /// tiles matching the rolled number.
    /// - Parameter diceNumber: The rolled number (2–12 except 7).
    private func distributeResources(for diceNumber: Int) {
        // For each tile matching the number, award resources to players with adjacent settlements or cities.
        for (tileIndex, tile) in tiles.enumerated() {
            guard tile.number == diceNumber else { continue }
            let resourceType = tile.resource
            // Desert tile produces nothing
            if resourceType == .desert { continue }
            let corners = tileCornerIndices[tileIndex]
            for cornerIndex in corners {
                let intersection = intersections[cornerIndex]
                guard let occupant = intersection.occupant else { continue }
                switch occupant {
                case .settlement(let playerId):
                    players[playerId].resources[resourceType, default: 0] += 1
                case .city(let playerId):
                    players[playerId].resources[resourceType, default: 0] += 2
                }
            }
        }
    }

    /// Attempt to place a settlement at the specified intersection.  Validates
    /// that the intersection is empty, that no adjacent intersections are
    /// occupied (distance rule), and that the current player has the
    /// required resources.  If successful, deducts the resources and
    /// updates the game state.
    /// - Parameter intersectionIndex: Index of the intersection where the settlement should be placed.
    public func placeSettlement(at intersectionIndex: Int) {
        guard intersectionIndex >= 0 && intersectionIndex < intersections.count else { return }
        var intersection = intersections[intersectionIndex]
        // must be empty
        guard intersection.occupant == nil else {
            lastMessage = "That spot is already taken."
            return
        }
        // ensure no adjacent intersections are occupied
        for neighbour in intersection.adjacentIntersections {
            if let occupant = intersections[neighbour].occupant {
                if case .settlement(let pid) = occupant { _ = pid }
                lastMessage = "You must respect the distance rule (no adjacent settlements)."
                return
            }
        }
        let playerId = currentPlayerIndex
        if setupPhase {
            guard setupStage == .settlement else {
                lastMessage = "Place your road before another settlement."
                return
            }
        } else {
            let cost: [ResourceType: Int] = [.lumber: 1, .brick: 1, .grain: 1, .wool: 1]
            guard canAfford(playerId: playerId, cost: cost) else {
                lastMessage = "Not enough resources to build a settlement."
                return
            }
            // must touch one of the player's roads
            let connectsToRoad = roads.contains { road in
                road.occupant == playerId &&
                    (road.from == intersectionIndex || road.to == intersectionIndex)
            }
            guard connectsToRoad else {
                lastMessage = "Settlement must connect to your road."
                return
            }
            payResources(playerId: playerId, cost: cost)
        }
        // place settlement
        intersection.occupant = .settlement(player: playerId)
        intersections[intersectionIndex] = intersection
        players[playerId].settlements += 1
        players[playerId].victoryPoints += 1
        if setupPhase {
            setupStage = .road
            lastMessage = "\(players[playerId].name) placed an initial settlement."
        } else {
            lastMessage = "\(players[playerId].name) built a settlement."
        }
    }

    /// Attempt to upgrade a settlement to a city at the specified intersection.  The
    /// current player must own the settlement and pay the city cost.
    /// - Parameter intersectionIndex: Index of the intersection to upgrade.
    public func upgradeToCity(at intersectionIndex: Int) {
        guard intersectionIndex >= 0 && intersectionIndex < intersections.count else { return }
        var intersection = intersections[intersectionIndex]
        guard let occupant = intersection.occupant else {
            lastMessage = "No settlement exists here to upgrade."
            return
        }
        let playerId = currentPlayerIndex
        switch occupant {
        case .settlement(let owner) where owner == playerId:
            // city cost: two grain and three ore
            let cost: [ResourceType: Int] = [.grain: 2, .ore: 3]
            guard canAfford(playerId: playerId, cost: cost) else {
                lastMessage = "Not enough resources to upgrade to a city."
                return
            }
            payResources(playerId: playerId, cost: cost)
            intersection.occupant = .city(player: playerId)
            intersections[intersectionIndex] = intersection
            players[playerId].cities += 1
            players[playerId].victoryPoints += 1 // additional point (settlement already counted)
            lastMessage = "\(players[playerId].name) upgraded to a city."
        case .settlement(let owner):
            lastMessage = "Only the owner of this settlement can upgrade it."
        case .city:
            lastMessage = "This settlement is already a city."
        }
    }

    /// Attempt to place a road on the specified road index.  Validates
    /// that the road is unclaimed and that the current player has the
    /// required resources.  Does not enforce full Catan road placement
    /// rules (i.e. connecting to own road/settlement) but could be
    /// extended to do so.
    /// - Parameter roadIndex: Index of the road to place.
    public func placeRoad(at roadIndex: Int) {
        guard roadIndex >= 0 && roadIndex < roads.count else { return }
        if roads[roadIndex].occupant != nil {
            lastMessage = "That road has already been built."
            return
        }
        let playerId = currentPlayerIndex
        if setupPhase {
            guard setupStage == .road else {
                lastMessage = "Place a settlement first."
                return
            }
        }
        // Optionally enforce adjacency: road must touch at least one intersection owned by player or a road belonging to player.
        // Here we implement a simple rule: you can build a road if at least one of its endpoints is adjacent to a
        // settlement/city/road belonging to the player.  In the initial placement phase, players may have no structures.
        let road = roads[roadIndex]
        let a = road.from
        let b = road.to
        let touchesPlayerStructure: Bool = {
            // check settlements/cities at endpoints
            if let occupant = intersections[a].occupant {
                switch occupant {
                case .settlement(let owner) where owner == playerId: return true
                case .city(let owner) where owner == playerId: return true
                default: break
                }
            }
            if let occupant = intersections[b].occupant {
                switch occupant {
                case .settlement(let owner) where owner == playerId: return true
                case .city(let owner) where owner == playerId: return true
                default: break
                }
            }
            // check existing roads adjacent to endpoints
            for r in roads where r.occupant == playerId {
                if r.from == a || r.to == a || r.from == b || r.to == b {
                    return true
                }
            }
            return false
        }()
        let playerHasNoRoads = !roads.contains(where: { $0.occupant == playerId })
        if setupPhase {
            if !touchesPlayerStructure {
                lastMessage = "Initial road must connect to your settlement."
                return
            }
        } else {
            if !touchesPlayerStructure && !playerHasNoRoads {
                lastMessage = "Road must connect to your existing road or settlement."
                return
            }
            // road cost: one lumber and one brick
            let cost: [ResourceType: Int] = [.lumber: 1, .brick: 1]
            guard canAfford(playerId: playerId, cost: cost) else {
                lastMessage = "Not enough resources to build a road."
                return
            }
            payResources(playerId: playerId, cost: cost)
        }
        roads[roadIndex].occupant = playerId
        players[playerId].roads += 1
        if setupPhase {
            setupPairsBuilt[playerId] += 1
            setupStage = .done
            lastMessage = "\(players[playerId].name) placed an initial road."
        } else {
            lastMessage = "\(players[playerId].name) built a road."
        }
    }

    // MARK: - Resource Management Helpers

    /// Check whether a player can afford a build cost.
    private func canAfford(playerId: Int, cost: [ResourceType: Int]) -> Bool {
        for (resource, amount) in cost {
            if players[playerId].resources[resource, default: 0] < amount {
                return false
            }
        }
        return true
    }

    /// Deduct a build cost from a player's resources.
    private func payResources(playerId: Int, cost: [ResourceType: Int]) {
        for (resource, amount) in cost {
            players[playerId].resources[resource, default: 0] -= amount
        }
    }
}
