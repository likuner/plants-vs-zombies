import SwiftUI

private enum BackyardPalette {
    static let ink = Color(red: 0.10, green: 0.16, blue: 0.10)
    static let moss = Color(red: 0.16, green: 0.37, blue: 0.16)
    static let grass = Color(red: 0.22, green: 0.63, blue: 0.20)
    static let grassLight = Color(red: 0.36, green: 0.76, blue: 0.24)
    static let lime = Color(red: 0.86, green: 0.95, blue: 0.40)
    static let cream = Color(red: 1.00, green: 0.96, blue: 0.81)
    static let paper = Color(red: 0.98, green: 0.91, blue: 0.70)
    static let woodDark = Color(red: 0.25, green: 0.10, blue: 0.045)
    static let wood = Color(red: 0.48, green: 0.21, blue: 0.08)
    static let woodLight = Color(red: 0.68, green: 0.36, blue: 0.14)
    static let gold = Color(red: 1.00, green: 0.76, blue: 0.18)
    static let coral = Color(red: 0.90, green: 0.25, blue: 0.19)
}

struct ContentView: View {
    @StateObject private var game = GameModel()
    @StateObject private var soundManager = SoundManager()
    @State private var showingRules = false

    private let gameClock = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            BackyardBackground()
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    intro
                    scoreRail
                    PlantDeck(game: game)
                    GameBoard(game: game)
                    missionPanel
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            game.onSoundEffect = { effect in
                soundManager.play(effect)
            }
        }
        .onDisappear {
            game.onSoundEffect = nil
            soundManager.stopAll()
        }
        .onReceive(gameClock) { _ in
            game.tick(delta: 0.12)
        }
        .sheet(isPresented: $showingRules) {
            RulesSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("后院")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(BackyardPalette.moss)
                Text("保卫战")
                    .font(.system(size: 35, weight: .black, design: .rounded))
                    .tracking(-1)
                    .foregroundStyle(BackyardPalette.ink)
            }

            Spacer()

            Button {
                soundManager.toggleMute()
            } label: {
                Image(systemName: soundManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(BackyardPalette.ink)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.7), in: Circle())
                    .overlay(Circle().stroke(BackyardPalette.ink.opacity(0.12), lineWidth: 1))
            }
            .accessibilityLabel(soundManager.isMuted ? "打开音效" : "关闭音效")

            Button {
                showingRules = true
            } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(BackyardPalette.ink)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.7), in: Circle())
                    .overlay(Circle().stroke(BackyardPalette.ink.opacity(0.12), lineWidth: 1))
            }
            .accessibilityLabel("玩法说明")
        }
    }

    private var intro: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.phase.label)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(game.phase == .lost ? BackyardPalette.coral : BackyardPalette.moss)
                Text(game.statusMessage)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(BackyardPalette.ink)
                    .lineLimit(2)
            }
            Spacer()
            Button {
                if game.phase == .won || game.phase == .lost {
                    game.reset()
                } else {
                    game.togglePause()
                }
            } label: {
                Image(systemName: controlIcon)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(BackyardPalette.cream)
                    .frame(width: 42, height: 42)
                    .background(BackyardPalette.ink, in: Circle())
            }
            .accessibilityLabel(controlLabel)
        }
    }

    private var scoreRail: some View {
        HStack(spacing: 8) {
            MetricPill(label: "阳光", value: "\(game.sun)", icon: "sun.max.fill", tint: PlantKind.sunflower.tint)
            MetricPill(label: "波次", value: "\(game.wave)/5", icon: "flag.fill", tint: BackyardPalette.moss)
            MetricPill(label: "分数", value: "\(game.score)", icon: "star.fill", tint: BackyardPalette.coral)
            Spacer(minLength: 0)
            Text(timeString)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundStyle(BackyardPalette.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(.white.opacity(0.62), in: Capsule())
        }
    }

    private var missionPanel: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BackyardPalette.ink)
                Image(systemName: "target")
                    .font(.system(size: 25, weight: .black))
                    .foregroundStyle(BackyardPalette.lime)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text("今日任务")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(BackyardPalette.moss)
                Text("在倒计时结束前击退 3 只僵尸。")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(BackyardPalette.ink)
            }

            Spacer()

            Text("\(min(game.defeated, 3))/3")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(BackyardPalette.ink)
        }
        .padding(12)
        .background(BackyardPalette.paper.opacity(0.9), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        )
    }

    private var timeString: String {
        let seconds = max(0, Int(game.secondsRemaining))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private var controlIcon: String {
        switch game.phase {
        case .paused: "play.fill"
        case .won, .lost: "arrow.clockwise"
        case .playing: "pause.fill"
        }
    }

    private var controlLabel: String {
        switch game.phase {
        case .paused: "继续游戏"
        case .won, .lost: "再来一局"
        case .playing: "暂停游戏"
        }
    }
}

private struct BackyardBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.89, blue: 0.65),
                    Color(red: 0.88, green: 0.83, blue: 0.55),
                    Color(red: 0.49, green: 0.76, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                HStack {
                    Circle()
                        .fill(.white.opacity(0.22))
                        .frame(width: 160, height: 160)
                        .blur(radius: 8)
                    Spacer()
                    Circle()
                        .fill(BackyardPalette.gold.opacity(0.22))
                        .frame(width: 110, height: 110)
                        .blur(radius: 8)
                }
                Spacer()
            }
            .padding(.horizontal, -30)
            .padding(.top, 60)

            VStack {
                Spacer()
                Rectangle()
                    .fill(BackyardPalette.moss.opacity(0.12))
                    .frame(height: 220)
                    .blur(radius: 28)
            }
        }
    }
}

private struct MetricPill: View {
    let label: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: -2) {
                Text(label)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(BackyardPalette.moss.opacity(0.75))
                Text(value)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(BackyardPalette.ink)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

private struct GameBoard: View {
    @ObservedObject var game: GameModel

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("草坪战场")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(BackyardPalette.ink)
                Spacer()
                Text("点击格子种植")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(BackyardPalette.moss)
            }

            GeometryReader { geometry in
                let cellWidth = geometry.size.width / CGFloat(GameModel.columns)
                let cellHeight = geometry.size.height / CGFloat(GameModel.rows)

                ZStack(alignment: .topLeading) {
                    VStack(spacing: 0) {
                        ForEach(0..<GameModel.rows, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<GameModel.columns, id: \.self) { column in
                                    Button {
                                        game.placePlant(row: row, column: column)
                                    } label: {
                                        LawnCell(
                                            row: row,
                                            column: column,
                                            plant: game.plants.first { $0.row == row && $0.column == column },
                                            isSelected: game.selectedPlant != nil
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: cellWidth, height: cellHeight)
                                    .accessibilityLabel("第 \(row + 1) 行，第 \(column + 1) 个格子")
                                }
                            }
                        }
                    }

                    ForEach(game.projectiles) { projectile in
                        ProjectileToken()
                            .position(
                                x: (projectile.position + 0.5) * cellWidth,
                                y: (CGFloat(projectile.row) + 0.5) * cellHeight
                            )
                    }

                    ForEach(game.zombies) { zombie in
                        ZombieToken(
                            health: zombie.health,
                            maxHealth: zombie.maxHealth,
                            isPaused: game.phase == .paused
                        )
                            .position(
                                x: (zombie.position + 0.5) * cellWidth,
                                y: (CGFloat(zombie.row) + 0.5) * cellHeight
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(BackyardPalette.ink.opacity(0.18), lineWidth: 2)
                )
                .shadow(color: BackyardPalette.ink.opacity(0.16), radius: 18, y: 10)
            }
            .aspectRatio(1.8, contentMode: .fit)
        }
    }
}

private struct LawnCell: View {
    let row: Int
    let column: Int
    let plant: Plant?
    let isSelected: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            row.isMultiple(of: 2) ? BackyardPalette.grassLight : BackyardPalette.grass,
                            BackyardPalette.grass.opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Rectangle()
                .fill(.black.opacity(column.isMultiple(of: 2) ? 0.03 : 0.0))

            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 15, height: 15)
                .offset(x: column.isMultiple(of: 2) ? -8 : 9, y: row.isMultiple(of: 2) ? -8 : 8)

            Capsule()
                .fill(BackyardPalette.moss.opacity(0.18))
                .frame(width: 4, height: 13)
                .rotationEffect(.degrees(column.isMultiple(of: 2) ? -25 : 25))
                .offset(x: 8, y: -9)

            if column == GameModel.columns - 1 {
                Rectangle()
                    .fill(.black.opacity(0.08))
                    .frame(width: 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let plant {
                PlantToken(plant: plant)
            } else if isSelected {
                Circle()
                    .stroke(.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .padding(7)
            }
        }
        .overlay(Rectangle().stroke(.white.opacity(0.12), lineWidth: 0.6))
    }
}

private struct PlantToken: View {
    let plant: Plant

    var body: some View {
        PlantAvatar(kind: plant.kind, size: 31)
        .overlay(alignment: .bottom) {
            HealthBar(value: Double(plant.health) / Double(plant.kind.health), tint: plant.kind.tint)
                .offset(y: 5)
        }
    }
}

private struct PlantAvatar: View {
    let kind: PlantKind
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(kind.tint.opacity(0.18))
                .overlay(Circle().stroke(.white.opacity(0.72), lineWidth: 1))

            switch kind {
            case .sunflower:
                SunflowerAvatar()
            case .peashooter:
                PeashooterAvatar()
            case .wallnut:
                WallnutAvatar()
            }
        }
        .frame(width: 42, height: 42)
        .scaleEffect(size / 42)
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: 2, y: 2)
    }
}

private struct SunflowerAvatar: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.22, green: 0.58, blue: 0.22))
                .frame(width: 4, height: 18)
                .offset(y: 13)

            Ellipse()
                .fill(Color(red: 0.18, green: 0.52, blue: 0.19))
                .frame(width: 13, height: 7)
                .rotationEffect(.degrees(-25))
                .offset(x: -8, y: 16)

            Ellipse()
                .fill(Color(red: 0.24, green: 0.63, blue: 0.22))
                .frame(width: 13, height: 7)
                .rotationEffect(.degrees(25))
                .offset(x: 8, y: 16)

            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(BackyardPalette.gold)
                    .frame(width: 7, height: 16)
                    .offset(y: -12)
                    .rotationEffect(.degrees(Double(index) * 45))
            }

            Circle()
                .fill(Color(red: 0.55, green: 0.27, blue: 0.08))
                .frame(width: 20, height: 20)
                .overlay {
                    HStack(spacing: 5) {
                        Circle().fill(.black.opacity(0.7)).frame(width: 2.5, height: 3)
                        Circle().fill(.black.opacity(0.7)).frame(width: 2.5, height: 3)
                    }
                    .offset(y: -2)
                }
        }
    }
}

private struct PeashooterAvatar: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.17, green: 0.52, blue: 0.20))
                .frame(width: 4, height: 18)
                .offset(y: 13)

            Ellipse()
                .fill(Color(red: 0.21, green: 0.63, blue: 0.22))
                .frame(width: 14, height: 7)
                .rotationEffect(.degrees(-25))
                .offset(x: -7, y: 16)

            Circle()
                .fill(Color(red: 0.48, green: 0.80, blue: 0.20))
                .frame(width: 22, height: 22)
                .offset(x: -2, y: -5)

            Capsule()
                .fill(Color(red: 0.32, green: 0.68, blue: 0.15))
                .frame(width: 15, height: 9)
                .offset(x: 13, y: -5)

            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
                .overlay(Circle().fill(.black).frame(width: 2.5, height: 2.5))
                .offset(x: 3, y: -9)
        }
    }
}

private struct WallnutAvatar: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.65, green: 0.36, blue: 0.14))
                .frame(width: 24, height: 27)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.39, green: 0.18, blue: 0.07), lineWidth: 1))

            HStack(spacing: 6) {
                Circle().fill(.white).frame(width: 6, height: 7)
                Circle().fill(.white).frame(width: 6, height: 7)
            }
            .overlay {
                HStack(spacing: 6) {
                    Circle().fill(.black).frame(width: 2, height: 3)
                    Circle().fill(.black).frame(width: 2, height: 3)
                }
            }
            .offset(y: -4)

            Capsule()
                .fill(Color(red: 0.35, green: 0.15, blue: 0.05))
                .frame(width: 10, height: 2)
                .offset(y: 6)

            NutCrack()
                .stroke(.black.opacity(0.3), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                .frame(width: 24, height: 27)
        }
    }
}

private struct NutCrack: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - 2, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.midX + 1, y: rect.midY - 2))
        path.addLine(to: CGPoint(x: rect.midX - 2, y: rect.maxY - 3))
        path.move(to: CGPoint(x: rect.midX + 1, y: rect.midY - 2))
        path.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.midY + 1))
        return path
    }
}

private struct ZombieToken: View {
    let health: Int
    let maxHealth: Int
    let isPaused: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.08, paused: isPaused)) { timeline in
            ZombieCharacter(
                time: timeline.date.timeIntervalSinceReferenceDate,
                health: health,
                maxHealth: maxHealth
            )
        }
    }
}

private struct ZombieCharacter: View {
    let time: Double
    let health: Int
    let maxHealth: Int

    var body: some View {
        let stride = sin(time * 8.0)
        let bob = sin(time * 8.0) * 1.2
        let armSwing = stride * 17
        let legSwing = stride * 14
        let blink = abs(sin(time * 1.35)) > 0.97

        VStack(spacing: 0) {
            ZStack {
                Ellipse()
                    .fill(.black.opacity(0.22))
                    .frame(width: 34, height: 7)
                    .offset(y: 31)

                ZombieLeg()
                    .rotationEffect(.degrees(legSwing), anchor: .top)
                    .offset(x: -7, y: 16 + bob)

                ZombieLeg()
                    .rotationEffect(.degrees(-legSwing), anchor: .top)
                    .offset(x: 7, y: 16 + bob)

                ZombieShoe()
                    .rotationEffect(.degrees(legSwing * 0.45))
                    .offset(x: -11, y: 28 + bob)

                ZombieShoe()
                    .rotationEffect(.degrees(-legSwing * 0.45))
                    .offset(x: 11, y: 28 + bob)

                ZombieArm(isLeft: true)
                    .rotationEffect(.degrees(-30 + armSwing), anchor: .top)
                    .offset(x: -18, y: 1 + bob)

                ZombieArm(isLeft: false)
                    .rotationEffect(.degrees(30 - armSwing), anchor: .top)
                    .offset(x: 18, y: 1 + bob)

                ZombieBody()
                    .offset(y: 9 + bob)

                ZombieHead(blink: blink)
                    .offset(y: -19 + bob)
            }
            .frame(width: 58, height: 68)
            .scaleEffect(0.47)
            .frame(width: 29, height: 33)

            HealthBar(value: Double(health) / Double(maxHealth), tint: BackyardPalette.coral)
                .frame(width: 25)
        }
        .frame(width: 34, height: 40)
    }
}

private struct ZombieBody: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.48, green: 0.28, blue: 0.18),
                            Color(red: 0.25, green: 0.13, blue: 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 29, height: 33)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.black.opacity(0.28), lineWidth: 1)
                }

            Capsule()
                .fill(BackyardPalette.coral)
                .frame(width: 5, height: 21)
                .rotationEffect(.degrees(7))
                .offset(y: 10)

            Circle()
                .fill(Color(red: 0.52, green: 0.67, blue: 0.44))
                .frame(width: 6, height: 6)
                .offset(x: -9, y: 13)

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 6, height: 1)
                .rotationEffect(.degrees(-18))
                .offset(x: 8, y: 4)
        }
    }
}

private struct ZombieHead: View {
    let blink: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.49, green: 0.63, blue: 0.42))
                .frame(width: 34, height: 35)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.black.opacity(0.3), lineWidth: 1.2)
                }

            Circle()
                .fill(Color(red: 0.49, green: 0.63, blue: 0.42))
                .frame(width: 9, height: 11)
                .offset(x: -18, y: 2)

            Circle()
                .fill(Color(red: 0.49, green: 0.63, blue: 0.42))
                .frame(width: 9, height: 11)
                .offset(x: 18, y: 2)

            ZombieHair()
                .fill(Color(red: 0.08, green: 0.10, blue: 0.09))
                .frame(width: 35, height: 14)
                .offset(x: -1, y: -23)

            HStack(spacing: 6) {
                ZombieEye(blink: blink)
                ZombieEye(blink: blink)
            }
            .offset(y: -8)

            Capsule()
                .fill(.black.opacity(0.22))
                .frame(width: 5, height: 8)
                .rotationEffect(.degrees(-20))
                .offset(x: -10, y: 2)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(red: 0.12, green: 0.08, blue: 0.07))
                .frame(width: 21, height: 11)
                .overlay {
                    HStack(spacing: 1.5) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(.white.opacity(0.92))
                                .frame(width: 3, height: 6)
                        }
                    }
                    .offset(y: -1)
                }
                .offset(y: 6)
        }
    }
}

private struct ZombieEye: View {
    let blink: Bool

    var body: some View {
        Capsule()
            .fill(blink ? .black.opacity(0.55) : .white)
            .frame(width: 9, height: blink ? 2 : 10)
            .overlay {
                if !blink {
                    Circle()
                        .fill(BackyardPalette.coral)
                        .frame(width: 4, height: 4)
                }
            }
    }
}

private struct ZombieArm: View {
    let isLeft: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(Color(red: 0.46, green: 0.59, blue: 0.40))
                .frame(width: 8, height: 29)
                .overlay(Capsule().stroke(.black.opacity(0.23), lineWidth: 1))

            HStack(spacing: 1) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(Color(red: 0.52, green: 0.67, blue: 0.44))
                        .frame(width: 3, height: 9)
                }
            }
            .offset(y: 14)
        }
        .frame(width: 11, height: 40)
        .scaleEffect(x: isLeft ? 1 : -1, y: 1)
    }
}

private struct ZombieLeg: View {
    var body: some View {
        Capsule()
            .fill(Color(red: 0.15, green: 0.21, blue: 0.36))
            .frame(width: 10, height: 22)
            .overlay(Capsule().stroke(.black.opacity(0.25), lineWidth: 1))
    }
}

private struct ZombieShoe: View {
    var body: some View {
        Capsule()
            .fill(Color(red: 0.19, green: 0.11, blue: 0.07))
            .frame(width: 19, height: 8)
            .overlay(Capsule().stroke(.black.opacity(0.32), lineWidth: 1))
    }
}

private struct ZombieHair: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + 2, y: rect.minY + 3))
        path.addLine(to: CGPoint(x: rect.minX + 7, y: rect.minY + 7))
        path.addLine(to: CGPoint(x: rect.minX + 9, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + 14, y: rect.minY + 6))
        path.addLine(to: CGPoint(x: rect.minX + 18, y: rect.minY + 1))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 5))
        path.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct ProjectileToken: View {
    var body: some View {
        Circle()
            .fill(BackyardPalette.lime)
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1))
            .shadow(color: BackyardPalette.lime.opacity(0.8), radius: 5)
    }
}

private struct HealthBar: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            Capsule()
                .fill(.black.opacity(0.2))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(tint)
                        .frame(width: max(2, geometry.size.width * max(0, min(1, value))))
                }
        }
        .frame(width: 27, height: 3)
    }
}

private struct PlantDeck: View {
    @ObservedObject var game: GameModel

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("植物卡组")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(BackyardPalette.cream)
                Spacer()
                Text(game.selectedPlant.map { "已选择 \($0.title)" } ?? "请选择植物")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.3)
                    .foregroundStyle(BackyardPalette.cream.opacity(0.8))
            }

            HStack(spacing: 10) {
                ForEach(PlantKind.allCases) { kind in
                    PlantCard(
                        kind: kind,
                        isSelected: game.selectedPlant == kind,
                        canAfford: game.sun >= kind.cost
                    ) {
                        game.selectPlant(kind)
                    }
                }
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [BackyardPalette.woodLight, BackyardPalette.wood, BackyardPalette.woodDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(BackyardPalette.woodDark.opacity(0.42), lineWidth: 2)
        )
        .shadow(color: BackyardPalette.woodDark.opacity(0.25), radius: 14, y: 8)
    }
}

private struct PlantCard: View {
    let kind: PlantKind
    let isSelected: Bool
    let canAfford: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    PlantAvatar(kind: kind, size: 42)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(BackyardPalette.moss)
                    }
                }

                Text(kind.title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(BackyardPalette.ink)

                Text(kind.description)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(BackyardPalette.moss)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 4) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 9, weight: .black))
                    Text("\(kind.cost)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                }
                .foregroundStyle(canAfford ? BackyardPalette.moss : BackyardPalette.coral)
            }
            .padding(11)
            .frame(minHeight: 126, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [BackyardPalette.cream, BackyardPalette.paper],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? BackyardPalette.gold : .white.opacity(0.7), lineWidth: isSelected ? 2.5 : 1)
            )
            .shadow(color: BackyardPalette.woodDark.opacity(0.22), radius: 5, y: 4)
            .opacity(canAfford ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(kind.title)，需要 \(kind.cost) 点阳光")
    }
}

private struct RulesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("玩法说明")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(BackyardPalette.ink)
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(BackyardPalette.moss)
            }

            RuleRow(icon: "1.circle.fill", text: "先选择植物卡片，再点击草坪格子种下它。")
            RuleRow(icon: "2.circle.fill", text: "向日葵产出阳光，豌豆射手自动清理道路。")
            RuleRow(icon: "3.circle.fill", text: "坚果墙可以挡住僵尸，为防线争取时间。")

            Spacer()
        }
        .padding(22)
        .background(BackyardPalette.cream)
    }
}

private struct RuleRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(BackyardPalette.moss)
                .font(.system(size: 20, weight: .black))
            Text(text)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(BackyardPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("后院保卫战") {
    ContentView()
}

#Preview("玩法说明") {
    RulesSheet()
}
