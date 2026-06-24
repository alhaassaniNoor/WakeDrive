import Foundation
import CoreMotion
import Combine
import WatchKit
import HealthKit

class MotionManager: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    private var motionManager = CMMotionManager()
    private var healthStore = HKHealthStore()
    
    // 🚨 The "Trojan Horse" to keep sensors alive indefinitely
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    @Published var motionDangerScore = 0
    @Published var currentBPM: Double = 0
    @Published var isStill: Bool = false
    
    // Core Formula Variables
    private var hrHistory: [Double] = []
    private var lastMovementTime = Date()
    private var shakeBuffer: [Double] = []
    private var smoothedRiskScore: Double = 0.0
    
    // Sleep Data Variables
    private var hasSleepData: Bool = false
    private var sleepPenaltyScore: Double = 0.0
    
    // System Timers
    private var logicTimer: Timer?
    private var hapticTimer: Timer?
    private var hapticTicks = 0
    private var activeStage = 0
    
    func startTracking(sleepHours: Double? = nil) {
        stopTracking()
        guard motionManager.isDeviceMotionAvailable else { return }
        
        if let hours = sleepHours, hours > 0 {
            self.hasSleepData = true
            self.sleepPenaltyScore = min(100.0, max(0.0, (6.0 - hours) * 25.0))
        } else {
            self.hasSleepData = false
            self.sleepPenaltyScore = 0.0
        }
        
        resetEngine()
        fetchLocalSleepData()
        
        // 🚨 Activate the infinite background session with explicit permission handling
        startWorkoutSession()
        
        motionManager.deviceMotionUpdateInterval = 0.2
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            self.analyzeMovement(motion)
        }
        
        logicTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.evaluateDriverState()
        }
    }
    
    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
        logicTimer?.invalidate()
        logicTimer = nil
        
        endWorkoutSession()
        stopHaptics()
        resetEngine()
    }
    
    private func resetEngine() {
        motionDangerScore = 0
        smoothedRiskScore = 0.0
        currentBPM = 0
        isStill = false
        lastMovementTime = Date()
        activeStage = 0
        hrHistory.removeAll()
        shakeBuffer.removeAll()
        updatePhone()
    }
    
    private func analyzeMovement(_ motion: CMDeviceMotion) {
        let totalForce = abs(motion.userAcceleration.x) + abs(motion.userAcceleration.y) + abs(motion.userAcceleration.z)
        
        if totalForce > 0.30 {
            lastMovementTime = Date()
            isStill = false
        }
        
        shakeBuffer.append(totalForce)
        if shakeBuffer.count > 15 { shakeBuffer.removeFirst() }
        
        if motionDangerScore >= 90 {
            let averageForce = shakeBuffer.reduce(0, +) / Double(shakeBuffer.count)
            if shakeBuffer.count == 15 && averageForce > 1.2 {
                smoothedRiskScore = max(0, smoothedRiskScore - 50)
                motionDangerScore = Int(smoothedRiskScore)
                shakeBuffer.removeAll()
                stopHaptics()
                activeStage = 0
                updatePhone()
            }
        }
    }
    
    private func evaluateDriverState() {
        if motionDangerScore >= 90 { triggerStage3(); return }
        
        if currentBPM > 40 {
            hrHistory.append(currentBPM)
            if hrHistory.count > 120 { hrHistory.removeFirst() }
        }
        
        let hrBaseline = hrHistory.isEmpty ? currentBPM : hrHistory.reduce(0, +) / Double(hrHistory.count)
        var hrDropScore: Double = 0
        
        if hrBaseline > 0 && currentBPM > 0 && currentBPM < hrBaseline {
            let dropPercentage = ((hrBaseline - currentBPM) / hrBaseline) * 100.0
            let effectiveDrop = max(0, dropPercentage - 5.0)
            hrDropScore = min(100.0, (effectiveDrop / 10.0) * 100.0)
        }
        
        let secondsSinceMove = Date().timeIntervalSince(lastMovementTime)
        let movScore = secondsSinceMove < 5.0 ? 0.0 : (secondsSinceMove > 15.0 ? 100.0 : ((secondsSinceMove - 5.0) / 10.0) * 100.0)
        
        let targetRawScore = hasSleepData ? (hrDropScore * 0.5) + (sleepPenaltyScore * 0.2) + (movScore * 0.3) : (hrDropScore * 0.7) + (movScore * 0.3)
        
        let speedMult = 1.0 + (Double(ConnectivityManager.shared.currentSpeedKMH) / 120.0)
        smoothedRiskScore = ((min(100.0, targetRawScore * speedMult)) * 0.15) + (smoothedRiskScore * 0.85)
        
        motionDangerScore = Int(smoothedRiskScore)
        updatePhone()
        manageStages()
    }
    
    private func manageStages() {
        let targetStage = motionDangerScore >= 90 ? 3 : (motionDangerScore >= 70 ? 2 : (motionDangerScore >= 40 ? 1 : 0))
        if targetStage != activeStage {
            if targetStage == 3 { triggerStage3() }
            else if targetStage == 2 { triggerStage2() }
            else if targetStage == 1 { triggerStage1() }
            else { stopHaptics(); activeStage = 0 }
        }
    }
    
    private func triggerStage1() {
        stopHaptics(); activeStage = 1; hapticTicks = 0
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self, self.activeStage == 1 else { return }
            if self.hapticTicks < 50 { WKInterfaceDevice.current().play(.directionUp); self.hapticTicks += 1 }
            else { self.stopHaptics() }
        }
    }
    
    private func triggerStage2() {
        stopHaptics(); activeStage = 2; hapticTicks = 0
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self, self.activeStage == 2 else { return }
            if self.hapticTicks < 66 { WKInterfaceDevice.current().play(.failure); self.hapticTicks += 1 }
            else if self.hapticTicks == 66 { ConnectivityManager.shared.sendCommand("speakStage2"); self.hapticTicks += 1 }
            else { self.stopHaptics() }
        }
    }
    
    private func triggerStage3() {
        stopHaptics(); activeStage = 3; hapticTicks = 0
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self, self.activeStage == 3 else { return }
            let cycleTick = self.hapticTicks % 100
            if cycleTick < 83 { WKInterfaceDevice.current().play(.notification) }
            else if cycleTick == 83 { ConnectivityManager.shared.sendCommand("speakStage3") }
            self.hapticTicks += 1
        }
    }

    private func stopHaptics() { hapticTimer?.invalidate(); hapticTimer = nil }
    private func updatePhone() { DispatchQueue.main.async { ConnectivityManager.shared.sendTelemetry(score: self.motionDangerScore, hr: self.currentBPM, still: self.isStill) } }
    
    private func fetchLocalSleepData() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let now = Date(); let yesterday = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
        let query = HKSampleQuery(sampleType: sleepType, predicate: HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, _ in
            let totalHours = (samples as? [HKCategorySample])?.filter { $0.value <= 4 }.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } ?? 0 / 3600.0
            DispatchQueue.main.async { if totalHours > 0 { self?.hasSleepData = true; self?.sleepPenaltyScore = min(100.0, max(0.0, (6.0 - totalHours) * 25.0)) } }
        }
        healthStore.execute(query)
    }
    
    // MARK: - Workout Session Lifecycle
    private func startWorkoutSession() {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [hrType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, _ in
            guard success, let self = self else { return }
            
            let config = HKWorkoutConfiguration(); config.activityType = .mindAndBody; config.locationType = .unknown
            self.workoutSession = try? HKWorkoutSession(healthStore: self.healthStore, configuration: config)
            self.workoutBuilder = self.workoutSession?.associatedWorkoutBuilder()
            self.workoutSession?.delegate = self; self.workoutBuilder?.delegate = self
            self.workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: self.healthStore, workoutConfiguration: config)
            self.workoutSession?.startActivity(with: Date())
            self.workoutBuilder?.beginCollection(withStart: Date()) { _, _ in }
        }
    }
    
    private func endWorkoutSession() {
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { _, _ in self.workoutBuilder?.finishWorkout { _, _ in } }
    }
    
    // MARK: - HealthKit Delegates (Nonisolated for strict concurrency)
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        if let stats = workoutBuilder.statistics(for: HKQuantityType.quantityType(forIdentifier: .heartRate)!), let qty = stats.mostRecentQuantity() {
            DispatchQueue.main.async {
                self.currentBPM = qty.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            }
        }
    }
    
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
}
