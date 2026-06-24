import Foundation
import AVFoundation

class AlertManager {
    static let shared = AlertManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    // 🚨 Ensures the system gives your app priority over music/podcasts
    func wakeUpAudioSystem() {
        do {
            // Updated to use .mixWithOthers but with aggressive ducking so we are heard
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            
            // "Pre-warm" the speech synthesizer
            let silentUtterance = AVSpeechUtterance(string: " ")
            silentUtterance.volume = 0.0
            synthesizer.speak(silentUtterance)
        } catch {
            print("Failed to initialize audio session: \(error)")
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
            "Attention \(name), you are at high risk. Please pull over safely.",
            "Warning \(name), you are showing signs of exhaustion. Pull over now."
        ]
        speak(phrases.randomElement()!)
    }
    
    func stopAllAlerts() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    private func speak(_ text: String) {
        // Ensure the session is still active before speaking
        try? AVAudioSession.sharedInstance().setActive(true)
        
        let utterance = AVSpeechUtterance(string: text)
        // Set to English US with a slightly faster rate for urgency
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52
        utterance.volume = 1.0
        
        // 🚨 FIXED: Changed from prefersAssistivePitch to pitchMultiplier
        utterance.pitchMultiplier = 1.2 // A slightly higher pitch cuts through road noise better
        
        synthesizer.speak(utterance)
    }
}
