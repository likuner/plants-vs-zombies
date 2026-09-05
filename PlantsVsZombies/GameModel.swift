import Combine
import Foundation
import SwiftUI

enum PlantKind: String, CaseIterable, Identifiable {
    case sunflower
    case peashooter
    case wallnut

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sunflower: "向日葵"
        case .peashooter: "豌豆射手"
        case .wallnut: "坚果墙"
        }
    }

    var shortTitle: String {
        switch self {
        case .sunflower: "向日葵"
        case .peashooter: "豌豆"
        case .wallnut: "坚果"
        }
    }

    var icon: String {
        switch self {
        case .sunflower: "sun.max.fill"
        case .peashooter: "leaf.fill"
        case .wallnut: "shield.fill"
        }
    }

    var tint: Color {
        switch self {
        case .sunflower: Color(red: 0.98, green: 0.65, blue: 0.14)
        case .peashooter: Color(red: 0.15, green: 0.56, blue: 0.25)
        case .wallnut: Color(red: 0.62, green: 0.32, blue: 0.15)
        }
    }

    var cost: Int {
        switch self {
        case .sunflower: 50
        case .peashooter: 100
        case .wallnut: 50
        }
    }

    var recharge: Double {
        switch self {
        case .sunflower: 7
        case .peashooter: 1.1
        case .wallnut: 0
        }
    }

    var health: Int {
        switch self {
        case .sunflower: 60
        case .peashooter: 75
        case .wallnut: 260
        }
    }

    var description: String {
        switch self {
        case .sunflower: "持续产出阳光"
        case .peashooter: "向本行发射豌豆"
        case .wallnut: "坚固地挡住僵尸"
        }
    }
}

struct Plant: Identifiable {
    let id = UUID()
    let kind: PlantKind
    let row: Int
    let column: Int
    var health: Int
    var cooldown: Double
}

struct Zombie: Identifiable {
    let id = UUID()
    let row: Int
    var position: Double
    var health: Int
    let maxHealth: Int
    let speed: Double
    var attackCooldown: Double
}

struct Projectile: Identifiable {
    let id = UUID()
    let row: Int
    var position: Double
    let damage: Int
}

enum GamePhase: Equatable {
    case playing
    case paused
    case won
    case lost

    var label: String {
        switch self {
        case .playing: "防守进行中"
        case .paused: "游戏已暂停"
        case .won: "后院守住了"
        case .lost: "防线被突破"
        }
    }
}

@MainActor
final class GameModel: ObservableObject {
    static let rows = 5
    static let columns = 9
    static let totalDuration = 75.0

    @Published private(set) var plants: [Plant] = []
    @Published private(set) var zombies: [Zombie] = []
    @Published private(set) var projectiles: [Projectile] = []
    @Published private(set) var sun = 175
    @Published private(set) var score = 0
    @Published private(set) var defeated = 0
    @Published private(set) var secondsRemaining = totalDuration
    @Published private(set) var wave = 1
    @Published private(set) var statusMessage = "布置植物，准备迎接下一波僵尸。"
    @Published private(set) var phase: GamePhase = .playing
    @Published var selectedPlant: PlantKind? = .sunflower

    var onSoundEffect: ((SoundEffect) -> Void)?

    private var elapsed = 0.0
    private var sunTimer = 0.0
    private var spawnTimer = 0.0
    private var nextSpawn = 3.2

    init() {
        reset()
    }

    func reset() {
        plants = []
        projectiles = []
        zombies = [
            Zombie(row: 2, position: 7.6, health: 120, maxHealth: 120, speed: 0.15, attackCooldown: 0.7)
        ]
        sun = 175
        score = 0
        defeated = 0
        secondsRemaining = Self.totalDuration
        wave = 1
        statusMessage = "布置植物，准备迎接下一波僵尸。"
        phase = .playing
        selectedPlant = .sunflower
        elapsed = 0
        sunTimer = 0
        spawnTimer = 0.7
        nextSpawn = 3.2
    }

    func togglePause() {
        guard phase == .playing || phase == .paused else { return }
        let isPausing = phase == .playing
        phase = isPausing ? .paused : .playing
        statusMessage = phase == .paused ? "时间暂停，后院暂时安全。" : "战斗继续，守住每一条路！"
        playSound(isPausing ? .pause : .resume)
    }

    func selectPlant(_ kind: PlantKind) {
        guard phase == .playing else { return }
        selectedPlant = selectedPlant == kind ? nil : kind
        playSound(.select)
    }

    func placePlant(row: Int, column: Int) {
        guard phase == .playing, let kind = selectedPlant else { return }
        guard row >= 0, row < Self.rows, column >= 0, column < Self.columns else { return }
        guard plants.first(where: { $0.row == row && $0.column == column }) == nil else {
            statusMessage = "这个格子已经有植物了。"
            return
        }
        guard sun >= kind.cost else {
            statusMessage = "阳光还不够，先收集更多阳光吧。"
            return
        }

        sun -= kind.cost
        plants.append(
            Plant(
                kind: kind,
                row: row,
                column: column,
                health: kind.health,
                cooldown: kind == .wallnut ? 0 : kind.recharge * 0.6
            )
        )
        statusMessage = "已在第 \(row + 1) 行种下\(kind.title)。"
        playSound(.plant)
    }

    func tick(delta: Double) {
        guard phase == .playing else { return }

        elapsed += delta
        secondsRemaining = max(0, Self.totalDuration - elapsed)
        if secondsRemaining <= 0 {
            phase = .won
            statusMessage = "后院安全了！指挥官，干得漂亮！"
            playSound(.win)
            return
        }

        sunTimer += delta
        spawnTimer += delta

        if sunTimer >= 4.5 {
            sun += 25
            sunTimer = 0
            statusMessage = "阳光从天而降，阳光 +25。"
            playSound(.sunflower)
        }

        updatePlants(delta: delta)
        updateProjectiles(delta: delta)
        updateZombies(delta: delta)
        spawnIfNeeded()
        wave = min(5, 1 + Int(elapsed / 15))
    }

    private func updatePlants(delta: Double) {
        for index in plants.indices {
            plants[index].cooldown -= delta
            switch plants[index].kind {
            case .sunflower:
                if plants[index].cooldown <= 0 {
                    sun += 25
                    plants[index].cooldown = plants[index].kind.recharge
                    statusMessage = "向日葵开花了，阳光 +25。"
                    playSound(.sunflower)
                }
            case .peashooter:
                if plants[index].cooldown <= 0 {
                    projectiles.append(
                        Projectile(
                            row: plants[index].row,
                            position: Double(plants[index].column) + 0.35,
                            damage: 30
                        )
                    )
                    plants[index].cooldown = plants[index].kind.recharge
                    playSound(.shoot)
                }
            case .wallnut:
                break
            }
        }
        plants.removeAll { $0.health <= 0 }
    }

    private func updateProjectiles(delta: Double) {
        var activeProjectiles: [Projectile] = []

        for var projectile in projectiles {
            projectile.position += delta * 5.2
            if let zombieIndex = zombies.firstIndex(where: {
                $0.row == projectile.row && abs($0.position - projectile.position) < 0.42
            }) {
                zombies[zombieIndex].health -= projectile.damage
                playSound(.hit)
                if zombies[zombieIndex].health <= 0 {
                    zombies.remove(at: zombieIndex)
                    defeated += 1
                    score += 25
                    statusMessage = "僵尸被击退了，继续守住这条路！"
                    playSound(.zombieDown)
                }
            } else if projectile.position < Double(Self.columns) + 0.6 {
                activeProjectiles.append(projectile)
            }
        }

        projectiles = activeProjectiles
    }

    private func updateZombies(delta: Double) {
        for index in zombies.indices {
            guard let plantIndex = plants.firstIndex(where: {
                $0.row == zombies[index].row &&
                abs(Double($0.column) - zombies[index].position) < 0.34
            }) else {
                zombies[index].position -= zombies[index].speed * delta
                continue
            }

            zombies[index].attackCooldown -= delta
            if zombies[index].attackCooldown <= 0 {
                plants[plantIndex].health -= 12
                zombies[index].attackCooldown = 0.75
            }
        }

        if zombies.contains(where: { $0.position < -0.35 }) {
            phase = .lost
            statusMessage = "僵尸闯进屋了，重新布置再试一次。"
            playSound(.lose)
        }
    }

    private func spawnIfNeeded() {
        guard spawnTimer >= nextSpawn, zombies.count < 10 else { return }

        let lane = Int((elapsed * 1.7).rounded()) % Self.rows
        let health = 100 + wave * 15
        zombies.append(
            Zombie(
                row: lane,
                position: Double(Self.columns) + 0.2,
                health: health,
                maxHealth: health,
                speed: 0.13 + Double(wave) * 0.015,
                attackCooldown: 0.7
            )
        )
        spawnTimer = 0
        nextSpawn = max(1.8, 4.4 - elapsed * 0.025)
        statusMessage = "第 \(lane + 1) 行出现僵尸，注意防守！"
        playSound(.warning)
    }

    private func playSound(_ effect: SoundEffect) {
        onSoundEffect?(effect)
    }
}
