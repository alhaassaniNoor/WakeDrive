import Foundation
import WatchConnectivity
import Combine

class ConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = ConnectivityManager()
    
    @Published var isDriving = false
    @Published var currentSleepScore = 0
    @Published var currentHeartRate: Double = 0
    @Published var isStill: Bool = false
    
    var currentSpeed: Double = 0
    
    override private init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Outgoing Messages
    
    func sendDriveStatus(isStarting: Bool) {
        let stateMessage = ["isDriving": isStarting]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(stateMessage, replyHandler: nil)
        }
        
        try? WCSession.default.updateApplicationContext(stateMessage)
    }
    
    func sendTelemetry(score: Int, hr: Double, still: Bool) {
        let message: [String: Any] = [
            "sleepScore": score,
            "heartRate": hr,
            "isStill": still
        ]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil)
        }
        
        try? WCSession.default.updateApplicationContext(message)
    }
    
    // MARK: - Incoming Messages
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        updateInternalState(from: message)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        updateInternalState(from: applicationContext)
    }
    
    private func updateInternalState(from dictionary: [String: Any]) {
        DispatchQueue.main.async {
            if let drivingStatus = dictionary["isDriving"] as? Bool {
                self.isDriving = drivingStatus
            }
            if let hr = dictionary["heartRate"] as? Double {
                self.currentHeartRate = hr
            }
            if let still = dictionary["isStill"] as? Bool {
                self.isStill = still
            }
            if let score = dictionary["sleepScore"] as? Int {
                self.currentSleepScore = score
                
                #if os(iOS)
                self.triggerSafetyLogic(for: score)
                #endif
            }
        }
    }
    
    #if os(iOS)
    private func triggerSafetyLogic(for score: Int) {
        // NO MORE SPEED GATE. Voice is guaranteed regardless of GPS km/h.
        
        if score >= 90 {
            AlertManager.shared.playStageAlert(stage: 3)
        } else if score >= 70 {
            AlertManager.shared.playStageAlert(stage: 2)
        } else if score >= 40 {
            AlertManager.shared.playStageAlert(stage: 1)
        } else {
            // Only stop alerts if score naturally drops below 40
            AlertManager.shared.stopAllAlerts()
        }
    }
    #endif
    
    // MARK: - WCSession Delegate Requirements
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error { print("WCSession activation failed: \(error.localizedDescription)") }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
