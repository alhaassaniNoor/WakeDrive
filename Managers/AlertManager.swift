import Foundation
import AVFoundation

class AlertManager {
    static let shared = AlertManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    private var isAlertingStage2 = false
    private var isAlertingStage3 = false
    private var stage3Timer: Timer?
    
    func playStageAlert(stage: Int) {
        let name = UserDefaults.standard.string(forKey: "userName") ?? "Driver"
        
        switch stage {
        case 1:
            // Stage 1: Handled entirely by Watch vibrations
            stopAllAlerts()
            
        case 2:
            // Stage 2: Advice Message (Played once per entry to stage 2)
            if !isAlertingStage2 {
                stopAllAlerts()
                isAlertingStage2 = true
                speak("Advice: Please open the window and take a deep breath.")
            }
            
        case 3:
            // Stage 3: Emergency Name Loop
            if !isAlertingStage3 {
                stopAllAlerts()
                isAlertingStage3 = true
                
                speak("\(name), you are falling asleep! Wake up immediately!")
                
                stage3Timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                    self?.speak("\(name), wake up! Pull over now!")
                }
            }
            
        default:
            stopAllAlerts()
        }
    }
    
    func stopAllAlerts() {
        isAlertingStage2 = false
        isAlertingStage3 = false
        stage3Timer?.invalidate()
        stage3Timer = nil
        synthesizer.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        
        synthesizer.speak(utterance)
    }
}
