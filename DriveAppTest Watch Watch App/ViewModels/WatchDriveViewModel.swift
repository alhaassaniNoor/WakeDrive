import SwiftUI
import Combine
import WatchKit

class WatchDriveViewModel: ObservableObject {
    @Published var isDriving = false
    @Published var currentScore = 0
    @Published var currentBPM: Double = 0
    @Published var isStill: Bool = false
    
    private var connectivity = ConnectivityManager.shared
    private var motionManager = MotionManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        connectivity.$isDriving.receive(on: DispatchQueue.main).sink { [weak self] status in
            self?.isDriving = status
            if status { self?.motionManager.startTracking() }
            else { self?.motionManager.stopTracking() }
        }.store(in: &cancellables)
        
        motionManager.$motionDangerScore.receive(on: DispatchQueue.main).sink { [weak self] score in
            self?.currentScore = score
        }.store(in: &cancellables)
        
        motionManager.$currentBPM.receive(on: DispatchQueue.main).sink { [weak self] bpm in
            self?.currentBPM = bpm
        }.store(in: &cancellables)
        
        motionManager.$isStill.receive(on: DispatchQueue.main).sink { [weak self] still in
            self?.isStill = still
        }.store(in: &cancellables)
        
        connectivity.$triggerWatchReset.receive(on: DispatchQueue.main).sink { [weak self] shouldReset in
            if shouldReset {
                self?.motionManager.resetDemo()
                self?.connectivity.triggerWatchReset = false
            }
        }.store(in: &cancellables)
    }
    
    func startTripFromWatch() {
        connectivity.sendDriveStatus(isStarting: true)
    }
    
    func endTripFromWatch() {
        connectivity.sendDriveStatus(isStarting: false)
    }
}
