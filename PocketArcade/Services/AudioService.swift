import AVFoundation
import Combine
import Foundation

@MainActor
final class AudioService: ObservableObject {
    @Published var isSoundOn: Bool {
        didSet { UserDefaults.standard.set(isSoundOn, forKey: "isSoundOn") }
    }

    private var player: AVAudioPlayer?

    init() {
        isSoundOn = UserDefaults.standard.object(forKey: "isSoundOn") as? Bool ?? true
    }

    func playMenuLoop() {
        guard isSoundOn else { return }
        play(fileName: "bgm_main", extensionName: "mp3", loops: -1)
    }

    func playEffect(_ name: String) {
        guard isSoundOn else { return }
        play(fileName: name, extensionName: "wav", loops: 0)
    }

    private func play(fileName: String, extensionName: String, loops: Int) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: extensionName) else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = loops
            player?.prepareToPlay()
            player?.play()
        } catch {
            player = nil
        }
    }
}
