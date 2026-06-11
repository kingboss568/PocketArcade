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
            guard games.count >= ArcadeGameID.allCases.count else { return fallback }
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
        let date = ISO8601DateFormatter().date(from: "2026-06-11T00:00:00Z") ?? .now
        func make(_ id: ArcadeGameID, _ title: String, _ english: String, _ reference: String, _ isFree: Bool, _ levelCount: Int, _ leaderboard: String, _ mechanics: [String]) -> GameModel {
            GameModel(id: id, title: title, englishTitle: english, reference: reference, isFree: isFree, levelCount: levelCount, leaderboardID: leaderboard, mechanics: mechanics, sourceName: "企劃案A_Pocket_Arcade.md", sourceURL: "local://PocketArcade", fetchedAt: date, licenseNote: "User-provided product plan.")
        }
        return [
            make(.brickBlitz, "磚塊爆破", "Brick Blitz", "打磚塊 Breakout", true, 30, "pocketarcade_brickblitz", ["拖曳控制球拍", "道具：加寬、多球", "3 條命"]),
            make(.snakeEVO, "貪吃蛇進化", "Snake EVO", "貪吃蛇 Snake", true, 20, "pocketarcade_snakeevo", ["滑動轉向", "紅金藍三種食物"]),
            make(.stackAttack, "方塊疊疊樂", "Stack Attack", "Stack 疊塔", true, 0, "pocketarcade_stackattack", ["點擊放下方塊", "完美堆疊加分"]),
            make(.pongDuel, "乒乓對戰", "Pong Duel", "Pong", true, 0, "pocketarcade_pongduel", ["拖曳球拍", "先得 7 分獲勝"]),
            make(.memoryMatch, "記憶翻牌", "Memory Match", "Memory 翻牌配對", true, 8, "pocketarcade_memorymatch", ["翻牌配對", "Combo 加分"]),
            make(.fruitCatch, "接水果", "Fruit Catch", "Catch 接物遊戲", true, 0, "pocketarcade_fruitcatch", ["拖曳籃子", "避開炸彈"]),
            make(.frogDash, "青蛙跳跳", "Frog Dash", "Frogger", false, 20, "pocketarcade_frogdash", ["點擊前跳", "避開車流踩浮木"]),
            make(.bubblePop, "泡泡消消", "Bubble Pop", "Puzzle Bobble", false, 50, "pocketarcade_bubblepop", ["瞄準發射", "三同色消除"]),
            make(.moleMania, "打地鼠狂熱", "Mole Mania", "Whack-a-Mole", false, 0, "pocketarcade_molemania", ["點擊地鼠", "60 秒限時"]),
            make(.pinballPro, "彈珠台", "Pinball Pro", "Pinball", false, 0, "pocketarcade_pinballpro", ["左右撥桿", "3 顆球"]),
            make(.twentyFortyEight, "數字 2048", "2048 Plus", "2048", false, 20, "pocketarcade_2048plus", ["滑動合併", "合出 2048"]),
            make(.asteroidAce, "射擊隕石", "Asteroid Ace", "Asteroids", false, 0, "pocketarcade_asteroidace", ["拖曳移動自動開火", "隕石會分裂"]),
            make(.gomokuGo, "連線五子棋", "Gomoku Go", "五子棋", false, 0, "pocketarcade_gomokugo", ["點擊落子", "AI 對弈"]),
            make(.skyHop, "跳跳樂", "Sky Hop", "Jump 跳台遊戲", false, 0, "pocketarcade_skyhop", ["拖曳左右移動", "自動彈跳爬升"]),
            make(.rocketRush, "火箭飛行", "Rocket Rush", "Flappy 飛行閃避", false, 0, "pocketarcade_rocketrush", ["點擊噴射", "穿過閘門"]),
            make(.laneRacer, "極速閃避", "Lane Racer", "Lane Racer 賽車", false, 0, "pocketarcade_laneracer", ["滑動換車道", "金幣加分"]),
            make(.reversiRoyale, "黑白棋", "Reversi Royale", "Reversi 黑白棋", false, 0, "pocketarcade_reversiroyale", ["夾住翻面", "角落是關鍵"]),
            make(.mineSweeper, "掃雷高手", "Mine Sweeper", "Minesweeper 掃雷", false, 10, "pocketarcade_minesweeper", ["點擊翻開", "長按插旗"]),
            make(.gemCrush, "寶石消消樂", "Gem Crush", "Match-3 三消", false, 30, "pocketarcade_gemcrush", ["交換寶石", "連鎖得分"]),
            make(.invaderStorm, "太空侵略者", "Invader Storm", "Space Invaders", false, 0, "pocketarcade_invaderstorm", ["拖曳戰機", "波次挑戰"])
        ]
    }()
}
