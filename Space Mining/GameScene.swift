//
//  GameScene.swift
//  Space Mining
//
//  Created by Giorgi Matiashvili on 18/06/2026.
//
//  A cute-space take on Motherload: pilot a mining pod down through a tile
//  grid, dig out shiny gems, manage fuel and cargo, then haul your haul back
//  to the surface base to sell, refuel, repair and upgrade — and dive deeper.
//
//  Controls (on-screen):
//    ◀ ▶  move / drill sideways
//    🔽   drill straight down
//    🔼   thrust up through dug tunnels (costs fuel)
//  Gravity pulls the pod down through empty space.
//

import SpriteKit
import GameplayKit
import UIKit


// MARK: - Scene

class GameScene: SKScene {

    var entities = [GKEntity]()
    var graphs = [String: GKGraph]()

    // --- Level (set before the scene is presented; defaults to level 1) ---
    var level: LevelConfig = Levels.deepDig
    let player = PlayerState.shared

    // --- Grid config (derived from the level) ---
    var cols: Int { level.cols }
    var skyRows: Int { level.skyRows }
    var groundRows: Int { level.groundRows }
    var totalRows: Int { level.totalRows }
    var surfaceRow: Int { level.surfaceRow }   // row the pod parks on at the base
    var tileSize: CGFloat = 40

    var grid: [[TileKind]] = []
    var tileNodes: [[SKSpriteNode?]] = []

    // --- Pod state ---
    var podCol = 0
    var podRow = 0
    var isBusy = false
    var fallCells = 0
    var facingLeft = false

    // --- Resources ---
    var cash = 0
    var fuel: Double = 0
    var hull: Double = 0
    var cargo: [OreKind: Int] = [:]

    // --- Upgrade levels ---
    var drillLevel = 1
    var fuelLevel = 0
    var cargoLevel = 0
    var hullLevel = 0
    var engineLevel = 0

    var maxFuel: Double { 100 + Double(fuelLevel) * 70 }
    var maxHull: Double { 60 + Double(hullLevel) * 45 }
    var maxCargo: Int { 12 + cargoLevel * 9 }
    var drillSpeed: Double { Double(drillLevel) }
    var canBreakRock: Bool { drillLevel >= 3 }
    var thrustCost: Double { max(0.5, 1.8 - Double(engineLevel) * 0.25) }
    var moveDuration: Double { max(0.06, 0.13 - Double(engineLevel) * 0.012) }

    var cargoCount: Int { cargo.values.reduce(0, +) }
    var cargoValue: Int { cargo.reduce(0) { $0 + $1.value * $1.key.value } }

    // --- Flow flags ---
    var shopOpen = false
    var respawning = false
    var atSurface: Bool { podRow <= surfaceRow }

    // --- Level-complete / rescue flow ---
    enum ShopExit { case resume, nextLevel, retry }
    var completionPanel: SKNode?       // modal shown on success or rescue
    var shopExit: ShopExit = .resume   // what the shop's exit button does
    var rescuing = false               // tow-drone cutscene is playing

    // --- Objective tracking ---
    var levelComplete = false
    var maxDepthMeters = 0
    var oreCollectedTotal = 0
    var cashEarned = 0
    var earnedStars = 0

    // --- Nodes ---
    var cameraNode = SKCameraNode()
    let uiLayer = SKNode()          // all interface lives here, above the world
    let uiZ: CGFloat = 50           // base z for interface (world tops out ~5)
    var pod: SKNode!
    var shopPanel: SKNode?
    var banner: SKLabelNode?

    var cashLabel: SKLabelNode!
    var depthLabel: SKLabelNode!
    var cargoLabel: SKLabelNode!
    var fuelBar: SKShapeNode!
    var fuelBarBG: SKShapeNode!
    var hullBar: SKShapeNode!
    var hullBarBG: SKShapeNode!
    var shopButton: SKNode!
    var controlButtons: [Direction: SKShapeNode] = [:]
    var podFlame: SKSpriteNode?
    var podSprite: SKSpriteNode?

    lazy var tex = TextureFactory(theme: level.theme)

    var heldButtons: [ObjectIdentifier: Direction] = [:]
    var lastUpdateTime: TimeInterval = 0

    let font = "AvenirNext-Bold"

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.12, alpha: 1)
        tileSize = floor(size.width / CGFloat(cols))

        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width / 2, y: -size.height / 2)
        addChild(cameraNode)
        cameraNode.addChild(uiLayer)

        buildBackground()
        buildHUDChrome()
        loadProgress()
        buildSky()
        generateWorld()
        buildBase()
        buildPod()
        buildHUD()
        buildControls()
        buildVignette()

        fuel = maxFuel
        hull = maxHull
        spawnAtBase()
        updateCamera()
        refreshHUD()
    }

    func cellPosition(_ col: Int, _ row: Int) -> CGPoint {
        CGPoint(x: CGFloat(col) * tileSize + tileSize / 2,
                y: -CGFloat(row) * tileSize - tileSize / 2)
    }

    func inRange(_ col: Int, _ row: Int) -> Bool {
        col >= 0 && col < cols && row >= 0 && row < totalRows
    }

    func depthBand(_ depth: Int) -> Int { min(3, max(0, depth / 24)) }

    func spawnAtBase() {
        podCol = cols / 2
        podRow = surfaceRow
        fallCells = 0
        pod.position = cellPosition(podCol, podRow)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if rescuing { return }   // input locked during the rescue cutscene
        for t in touches {
            let p = t.location(in: cameraNode)
            if completionPanel != nil { handleCompletionTap(p); continue }
            if shopOpen { handleShopTap(p); continue }
            if !shopButton.isHidden, shopButton.contains(p) { shopExit = .resume; openShop(); continue }
            for (dir, b) in controlButtons where b.contains(p) {
                heldButtons[ObjectIdentifier(t)] = dir
            }
        }
        updateButtonHighlights()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { heldButtons[ObjectIdentifier(t)] = nil }
        updateButtonHighlights()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    func chosenDirection() -> Direction? {
        let held = Set(heldButtons.values)
        for d in [Direction.up, .left, .right, .down] where held.contains(d) { return d }
        return nil
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        updateCamera()

        guard !shopOpen, !respawning, !rescuing, completionPanel == nil else { return }

        maxDepthMeters = max(maxDepthMeters, (podRow - surfaceRow) * 10)
        checkObjective()

        // Passive fuel burn while away from the surface.
        if !atSurface {
            fuel = max(0, fuel - 0.7 * dt)
            if fuel <= 0 { strand(); return }
        }
        refreshHUD()
        tryStep()
    }

    func updateCamera() {
        let upper = -size.height / 2
        let lower = -CGFloat(totalRows) * tileSize + size.height / 2
        let y = pod.position.y
        cameraNode.position = CGPoint(x: size.width / 2, y: max(min(lower, upper), min(max(lower, upper), y)))
    }

    func tryStep() {
        guard !isBusy else { return }

        if let dir = chosenDirection() {
            move(dir)
        } else if isEmpty(podCol, podRow + 1) {
            fall()
        } else if fallCells > 0 {
            land()
        }
    }

    func isEmpty(_ col: Int, _ row: Int) -> Bool {
        guard inRange(col, row) else { return false }
        if case .empty = grid[row][col] { return true }
        return false
    }

    // per-level best depth). The world itself regenerates each visit.
    func saveProgress() {
        player.cash = cash
        player.drillLevel = drillLevel
        player.fuelLevel = fuelLevel
        player.cargoLevel = cargoLevel
        player.hullLevel = hullLevel
        player.engineLevel = engineLevel
        player.recordDepth(level.id, meters: maxDepthMeters)
        player.save()
    }

    func loadProgress() {
        cash = player.cash
        drillLevel = player.drillLevel
        fuelLevel = player.fuelLevel
        cargoLevel = player.cargoLevel
        hullLevel = player.hullLevel
        engineLevel = player.engineLevel
    }

    func safeTop() -> CGFloat { view?.safeAreaInsets.top ?? 24 }

    func safeBottom() -> CGFloat { view?.safeAreaInsets.bottom ?? 12 }
}
