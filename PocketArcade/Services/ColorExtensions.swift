import SwiftUI

extension Color {
    static func arcadeAccent(for gameID: ArcadeGameID) -> Color {
        Color(ArcadeFX.accent(for: gameID))
    }
}
