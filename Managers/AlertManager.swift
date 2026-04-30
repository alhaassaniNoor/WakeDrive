import Foundation
import AVFoundation

class AlertManager {
    static let shared = AlertManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    // 🚨 Wakes up the speakers when the drive starts so it works when the screen is off
    func wakeUpAudioSystem() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            
            let silentUtterance = AVSpeechUtterance(string: " ")
            silentUtterance.volume = 0.01
            synthesizer.speak(silentUtterance)
        } catch {
            print("Failed to hijack audio session.")
        }
    }
    
    func speakStage2() {
        stopAllAlerts()
        let name = UserDefaults.standard.string(forKey: "userName") ?? "Driver"
        let phrases = [
            "You seem tired, open the window.",
            "Hey \(name), fix your posture.",
            "Take a deep breath and stay alert."
        ]
        speak(phrases.randomElement()!)
    }
    
    func speakStage3() {
        stopAllAlerts()
        let name = UserDefaults.standard.string(forKey: "userName") ?? "Driver"
        let phrases = [
            "\(name), consider pulling over safely.",
            "\(name), you seem very tired, take a break."
        ]
        speak(phrases.randomElement()!)
    }
    
    func stopAllAlerts() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    private func speak(_ text: String) {
        do { try AVAudioSession.sharedInstance().setActive(true) } catch {}
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
}
