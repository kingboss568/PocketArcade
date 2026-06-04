import Foundation

public enum GameCatalogLoader {
    public static func load(bundle: Bundle = .main) -> [GameModel] {
        guard let url = bundle.url(forResource: "GameCatalogSeed", withExtension: "json") else {
            return fallback
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let games = try decoder.decode([GameModel].self, from: data)
            return games.sorted { lhs, rhs in
                let leftIndex = ArcadeGameID.allCases.firstIndex(of: lhs.id) ?? 0
                let rightIndex = ArcadeGameID.allCases.firstIndex(of: rhs.id) ?? 0
                return leftIndex < rightIndex
            }
        } catch {
            return fallback
        }
    }

    public static let fallback: [GameModel] = {
        let date = ISO8601DateFormatter().date(from: "2026-05-20T00:00:00Z") ?? .now
        return [
            GameModel(id: .brickBlitz, title: "磚塊爆破", englishTitle: "Brick Blitz", reference: "打磚塊 Breakout", isFree: true, levelCount: 30, leaderboardID: "pocketarcade_brickblitz", mechanics: ["左右滑動球拍", "加速彈", "清除 80% 過關"], sourceName: "企劃案A_Pocket_Arcade.md", sourceURL: "local://PocketArcade", fetchedAt: date, licenseNote: "User-provided product plan."),
            GameModel(id: .snakeEVO, title: "貪吃蛇進化", englishTitle: "Snake EVO", reference: "貪吃蛇 Snake", isFree: true, levelCount: 20, leaderboardID: "pocketarcade_snakeevo", mechanics: ["紅藍黃食物", "雙人對戰"], sourceName: "企劃案A_Pocket_Arcade.md", sourceURL: "local://PocketArcade", fetchedAt: date, licenseNote: "User-provided product plan."),
            GameModel(id: .stackAttack, title: "方塊疊疊樂", englishTitle: "Stack Attack", reference: "俄羅斯方塊 Tetris", isFree: true, levelCount: 0, leaderboardID: "pocketarcade_stackattack", mechanics: ["炸彈方塊", "救援模式"], sourceName: "企劃案A_Pocket_Arcade.md", sourceURL: "local://PocketArcade", fetchedAt: date, licenseNote: "User-provided product plan."),
            GameModel(id: .frogDash, title: "青蛙跳跳", englishTitle: "Frog Dash", reference: "Frogger", isFree: false, levelCount: 20, leaderboardID: "pocketarcade_frogdash", mechanics: ["車道河流", "星星皮膚"], sourceName: "企劃案A_Pocket_Arcade.md", sourceURL: "local://PocketArcade", fetchedAt: date, licenseNote: "User-provided product plan."),
            GameModel(id: .bubblePop, title: "泡泡消消", englishTitle: "Bubble Pop", reference: "Puzzle Bobble", isFree: false, levelCount: 50, leaderboardID: "pocketarcade_bubblepop", mechanics: ["三同色", "Boss 泡泡"], sourceName: "企劃案A_Pocket_Arcade.md", sourceURL: "local://PocketArcade", fetchedAt: date, licenseNote: "User-provided product plan."),
            GameModel(id: .moleMania, title: "打地鼠狂熱", englishTitle: "Mole Mania", reference: "Whack-a-Mole", isFree: false, levelCount: 0, leaderboardID: "pocketarcade_molemania", mechanics: ["金鼠", "炸彈鼠", "狂熱模式"], sourceName: "企劃案A_Pocket_Arcade.md", sourceURL: "local://PocketArcade", fetchedAt: date, licenseNote: "User-provided product plan."),
            GameModel(id: .pinballPro, title: "彈珠台", englishTitle: "Pinball Pro", reference: "Pinball", isFree: false, levelCount: 0, leaderboardID: "pocketarcade_pinballpro", mechanics: ["撥桿", "Multiball"], sourceName: "企劃案A_Pocket_Arcade.md", sourceURL: "local://PocketArcade", fetchedAt: date, licenseNote: "User-provided product plan."),
            GameModel(id: .twentyFortyEight, title: "數字 2048 Plus", englishTitle: "2048 Plus", reference: "2048", isFree: false, levelCount: 20, leaderboardID: "pocketarcade_2048plus", mechanics: ["障礙格", "乘法格"], sourceName: "企劃案A_Pocket_Arcade.md", sourceURL: "local://PocketArcade", fetchedAt: date, licenseNote: "User-provided product plan."),
            GameModel(id: .asteroidAce, title: "射擊隕石", englishTitle: "Asteroid Ace", reference: "Asteroids", isFree: false, levelCount: 0, leaderboardID: "pocketarcade_asteroidace", mechanics: ["自動連射", "Boss 隕石"], sourceName: "企劃案A_Pocket_Arcade.md", sourceURL: "local://PocketArcade", fetchedAt: date, licenseNote: "User-provided product plan."),
            GameModel(id: .gomokuGo, title: "連線五子棋", englishTitle: "Gomoku Go", reference: "五子棋", isFree: false, levelCount: 0, leaderboardID: "pocketarcade_gomokugo", mechanics: ["禁手提示", "AI 難度"], sourceName: "企劃案A_Pocket_Arcade.md", sourceURL: "local://PocketArcade", fetchedAt: date, licenseNote: "User-provided product plan.")
        ]
    }()
}
