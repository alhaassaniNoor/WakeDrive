import Foundation
import WatchConnectivity
import Combine

struct TripSummaryData: Equatable {
    let date: String
    let duration: String
    let speed: Int
    let hr: Int
    let avgRiskScore: Int
    let warning: Bool
}

class ConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = ConnectivityManager()
    
    @Published var isDriving = false
    @Published var currentSleepScore = 0
    @Published var currentHeartRate: Double = 0
    @Published var isStill: Bool = false
    @Published var triggerWatchReset = false
    
    #if os(iOS)
    @Published var isWatchAppInstalled: Bool = false
    @Published var newlyCompletedTripData: TripSummaryData?
    
    private var tripStartDate: Date?
    private var speedReadings: [Int] = []
    private var hrReadings: [Double] = []
    private var riskReadings: [Int] = []
    private var hadWarning: Bool = false
    #endif
    
    override private init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendDriveStatus(isStarting: Bool) {
        let msg: [String: Any] = ["isDriving": isStarting]
        DispatchQueue.main.async {
            if isStarting {
                self.isDriving = true
                #if os(iOS)
                AlertManager.shared.wakeUpAudioSystem()
                self.tripStartDate = Date()
                self.speedReadings = []
                self.hrReadings = []
                self.riskReadings = []
                self.hadWarning = false
                #endif
            } else {
                self.isDriving = false
                #if os(iOS)
                self.saveTrip()
                AlertManager.shared.stopAllAlerts()
                #endif
                self.currentSleepScore = 0
            }
        }
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(msg, replyHandler: nil) { _ in
                WCSession.default.transferUserInfo(msg)
            }
        } else {
            WCSession.default.transferUserInfo(msg)
        }
        try? WCSession.default.updateApplicationContext(msg)
    }
    
    func sendTelemetry(score: Int, hr: Double = 0, still: Bool = false) {
        let msg: [String: Any] = ["sleepScore": score, "heartRate": hr, "isStill": still]
        try? WCSession.default.updateApplicationContext(msg)
    }
    
    func sendCommand(_ command: String) {
        let msg = ["command": command]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(msg, replyHandler: nil) { _ in
                WCSession.default.transferUserInfo(msg)
            }
        } else {
            WCSession.default.transferUserInfo(msg)
        }
    }
    
    func sendEmergencyReset() {
        sendCommand("resetAwake")
        DispatchQueue.main.async {
            self.currentSleepScore = 0
            #if os(iOS)
            AlertManager.shared.stopAllAlerts()
            #endif
        }
    }
    
    #if os(iOS)
    func addTelemetry(speed: Int, hr: Double) {
        if speed > 0 { speedReadings.append(speed) }
        if hr > 0 { hrReadings.append(hr) }
    }
    
    private func saveTrip() {
        guard let start = tripStartDate else { return }
        let durationMinutes = max(1, Int(Date().timeIntervalSince(start) / 60))
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let dateString = formatter.string(from: start)
        
        let avgSpd = speedReadings.isEmpty ? 0 : speedReadings.reduce(0, +) / speedReadings.count
        let avgHeart = hrReadings.isEmpty ? 0 : Int(hrReadings.reduce(0, +) / Double(hrReadings.count))
        let avgRisk = riskReadings.isEmpty ? 0 : riskReadings.reduce(0, +) / riskReadings.count
        
        self.newlyCompletedTripData = TripSummaryData(
            date: dateString,
            duration: "\(durationMinutes) mins",
            speed: avgSpd,
            hr: avgHeart,
            avgRiskScore: avgRisk,
            warning: hadWarning
        )
        
        tripStartDate = nil
    }
    #endif
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) { handleIncoming(message) }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) { handleIncoming(applicationContext) }
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) { handleIncoming(userInfo) }
    
    private func handleIncoming(_ dict: [String: Any]) {
        DispatchQueue.main.async {
            if let drivingStatus = dict["isDriving"] as? Bool {
                #if os(iOS)
                if self.isDriving == true && drivingStatus == false {
                    self.saveTrip()
                    AlertManager.shared.stopAllAlerts()
                } else if self.isDriving == false && drivingStatus == true {
                    AlertManager.shared.wakeUpAudioSystem()
                    self.tripStartDate = Date()
                    self.speedReadings = []
                    self.hrReadings = []
                    self.riskReadings = []
                    self.hadWarning = false
                }
                #endif
                self.isDriving = drivingStatus
            }
            if let hr = dict["heartRate"] as? Double { self.currentHeartRate = hr }
            if let still = dict["isStill"] as? Bool { self.isStill = still }
            if let score = dict["sleepScore"] as? Int {
                self.currentSleepScore = score
                #if os(iOS)
                // 🚨 FIX: Ignore negative calibration scores (-1)
                if score >= 0 {
                    self.riskReadings.append(score)
                }
                if score >= 70 { self.hadWarning = true }
                #endif
            }
            
            if let cmd = dict["command"] as? String {
                if cmd == "resetAwake" {
                    self.currentSleepScore = 0
                    self.triggerWatchReset = true
                    #if os(iOS)
                    AlertManager.shared.stopAllAlerts()
                    #endif
                }
                #if os(iOS)
                if cmd == "speakStage2" { AlertManager.shared.speakStage2() }
                if cmd == "speakStage3" { AlertManager.shared.speakStage3() }
                #endif
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if os(iOS)
        DispatchQueue.main.async {
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
        #endif
    }
    
    #if os(iOS)
    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isWatchAppInstalled = session.isWatchAppInstalled }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
}
