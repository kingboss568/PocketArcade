import SwiftUI

extension Color {
    static func arcadeAccent(for gameID: ArcadeGameID) -> Color {
        switch gameID {
        case .brickBlitz: return .red
        case .snakeEVO: return .green
        case .stackAttack: return .orange
        case .frogDash: return .mint
        case .bubblePop: return .pink
        case .moleMania: return .brown
        case .pinballPro: return .purple
        case .twentyFortyEight: return .yellow
        case .asteroidAce: return .cyan
        case .gomokuGo: return .white
        }
    }
}
