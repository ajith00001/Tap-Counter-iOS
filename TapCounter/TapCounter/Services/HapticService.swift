import UIKit
import AudioToolbox
import AVFoundation

// MARK: - Haptic & Sound Service
class HapticService {
    static let shared = HapticService()
    
    private var audioPlayer: AVAudioPlayer?
    private let strongImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    private init() {
        configureAudioSession()
        prepareAudioPlayer()
        strongImpactGenerator.prepare()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func prepareAudioPlayer() {
        if let soundURL = Bundle.main.url(forResource: "click", withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.volume = 1.0
                audioPlayer?.prepareToPlay()
            } catch {
                print("Failed to load click.wav: \(error)")
            }
        }
    }

    // MARK: - Tap Feedback (strong click haptic + crisp keyboard click sound)
    func tapFeedback() {
        // Strong, crisp mechanical click haptic
        strongImpactGenerator.impactOccurred(intensity: 1.0)
        strongImpactGenerator.prepare()
        
        playTapSound()
    }

    // MARK: - Target Reached Feedback (strong haptic + sound)
    func targetReachedFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        playSuccessSound()
    }

    // MARK: - Timer Expired Feedback
    func timerExpiredFeedback() {
        // Triple pulse
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            generator.notificationOccurred(.warning)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            generator.notificationOccurred(.warning)
        }
        playTimerSound()
    }

    // MARK: - Subtract Feedback
    func subtractFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Reset Feedback
    func resetFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Sounds
    private func playTapSound() {
        // Play through dedicated AVAudioPlayer in .playback category (plays even in silent mode)
        if let player = audioPlayer {
            player.currentTime = 0
            player.play()
        } else {
            AudioServicesPlaySystemSound(1104)
        }
    }

    private func playSuccessSound() {
        AudioServicesPlaySystemSound(1007)
    }

    private func playTimerSound() {
        AudioServicesPlaySystemSound(1005)
    }
}
