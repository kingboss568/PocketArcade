import SwiftUI
import SharedCore

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private let pages = [
        ("掌心遊樂場", "10 款復古街機，地鐵、飛機、等人時都能開一局。", "sparkles"),
        ("離線優先", "遊戲與音效本地打包；沒網路時自動隱藏廣告入口。", "wifi.slash"),
        ("一次解鎖", "前 3 款免費，$2.99 解鎖全部 10 款，分數同步 Game Center。", "lock.open.fill")
    ]

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 38)
                    .fill(.black.opacity(0.25))
                    .frame(width: 230, height: 230)
                    .overlay(RoundedRectangle(cornerRadius: 38).stroke(ArcadeTheme.neonCyan, lineWidth: 2))
                    .shadow(color: ArcadeTheme.neonRed.opacity(0.45), radius: 34)
                Image(systemName: pages[page].2)
                    .font(.system(size: 74, weight: .black))
                    .foregroundStyle(LinearGradient(colors: [ArcadeTheme.neonYellow, ArcadeTheme.neonRed], startPoint: .top, endPoint: .bottom))
            }
            VStack(spacing: 12) {
                Text(pages[page].0)
                    .font(ArcadeTheme.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                Text(pages[page].1)
                    .font(ArcadeTheme.body)
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            HStack {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? ArcadeTheme.neonYellow : .white.opacity(0.25))
                        .frame(width: index == page ? 30 : 10, height: 8)
                }
            }
            Button {
                if page < pages.count - 1 {
                    withAnimation(.bouncy) { page += 1 }
                } else {
                    onFinish()
                }
            } label: {
                Text(page == pages.count - 1 ? "進入街機廳" : "下一步")
                    .font(.system(.headline, design: .monospaced).weight(.black))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ArcadeTheme.neonYellow, in: RoundedRectangle(cornerRadius: 18))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 28)
            Spacer()
        }
        .arcadeScreenBackground()
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
