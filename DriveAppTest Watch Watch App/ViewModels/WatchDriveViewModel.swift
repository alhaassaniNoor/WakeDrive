import SwiftUI
import Combine
import WatchKit

class WatchDriveViewModel: ObservableObject {
    @Published var isDriving = false
    @Published var currentScore = 0
    
    private var connectivity = ConnectivityManager.shared
    private var motionManager = MotionManager()
    private var healthManager = HealthManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        connectivity.$isDriving
            .receive(on: DispatchQueue.main)
            .sink { [weak self] drivingStatus in
                self?.isDriving = drivingStatus
                if drivingStatus {
                    self?.startSensors()
                } else {
                    self?.stopSensors()
                }
            }
            .store(in: &cancellables)
            
        motionManager.$motionDangerScore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] score in
                self?.currentScore = score
            }
            .store(in: &cancellables)
            
        connectivity.$currentSleepScore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] score in
                if score == 0 { self?.currentScore = 0 }
            }
            .store(in: &cancellables)
            
        healthManager.$currentHeartRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bpm in
                self?.motionManager.currentBPM = bpm
            }
            .store(in: &cancellables)
    }
    
    // NEW: Watch Controls
    func startTripFromWatch() {
        connectivity.isDriving = true
        connectivity.sendDriveStatus(isStarting: true)
        startSensors()
    }
    
    func endTripFromWatch() {
        connectivity.isDriving = false
        connectivity.sendDriveStatus(isStarting: false)
        stopSensors()
    }
    
    func startSensors() {
        motionManager.startTracking()
        healthManager.requestPermissions { [weak self] success in
            if success { self?.healthManager.startHeartRateQuery() }
        }
    }
    
    func stopSensors() {
        motionManager.stopTracking()
        healthManager.stopQuery()
        currentScore = 0
        connectivity.sendTelemetry(score: 0, hr: 0, still: false)
    }
    
    func resetScoreManually() {
        self.currentScore = 0
        motionManager.stopTracking()
        motionManager.startTracking()
        connectivity.sendTelemetry(score: 0, hr: 0, still: false)
        WKInterfaceDevice.current().play(.success)
    }
}
