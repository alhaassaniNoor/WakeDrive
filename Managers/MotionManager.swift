import Foundation
import CoreMotion
import Combine
import WatchKit
import HealthKit

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    private var healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    
    @Published var motionDangerScore = 0
    var currentBPM: Double = 75
    var isStill: Bool = false
    
    private var lastMovementTime = Date()
    private var logicTimer: Timer?
    private var hapticTimer: Timer?
    private var hapticTicks = 0
    private var activeStage = 0
    
    private var shakeBuffer: [Double] = []
    
    private var calibrationSeconds = 0
    private let CALIBRATION_LIMIT = 60 // Seconds needed at the start of a drive to establish a baseline heart rate.
    private var hrReadings: [Double] = []
    private var dynamicHRDropThreshold: Double = 60.0
    
    func startTracking() {
        stopTracking()
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionDangerScore = -1
        isStill = false
        lastMovementTime = Date()
        activeStage = 0
        shakeBuffer.removeAll()
        calibrationSeconds = 0
        hrReadings = []
        
        startWorkoutSession()
        startHeartRateQuery()
        
        motionManager.deviceMotionUpdateInterval = 0.1 // Checks the wrist sensor 10 times per second.
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            self.analyzeMovement(motion)
        }
        
        logicTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.evaluateRealData()
        }
    }
    
    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
        logicTimer?.invalidate()
        logicTimer = nil
        workoutSession?.end()
        stopHaptics()
        activeStage = 0
        DispatchQueue.main.async { self.motionDangerScore = 0 }
    }
    
    func resetDemo() {
        stopHaptics()
        lastMovementTime = Date()
        activeStage = 0
        isStill = false
        motionDangerScore = 0
        shakeBuffer.removeAll()
        updateScore(to: 0)
    }
    
    private func analyzeMovement(_ motion: CMDeviceMotion) {
        if calibrationSeconds < CALIBRATION_LIMIT { return }
        
        let totalForce = abs(motion.userAcceleration.x) + abs(motion.userAcceleration.y) + abs(motion.userAcceleration.z)
        
        shakeBuffer.append(totalForce)
        if shakeBuffer.count > 15 { // Holds exactly 1.5 seconds of wrist movement history.
            shakeBuffer.removeFirst()
        }
        
        if motionDangerScore >= 90 {
            let averageForce = shakeBuffer.reduce(0, +) / Double(shakeBuffer.count)
            
            if shakeBuffer.count == 15 && averageForce > 1.0 { // 1.0 Gs is the sustained force required to register a wake-up shake and dismiss the alarm.
                updateScore(to: max(0, motionDangerScore - 50))
                shakeBuffer.removeAll()
                stopHaptics()
                activeStage = 0
                lastMovementTime = Date()
                return
            }
            return
        }
        
        if totalForce > 3.5 { // 3.5 Gs indicates a violent swerve or panic movement (instantly adds 40 points).
            updateScore(to: min(100, motionDangerScore + 40))
        } else if totalForce > 0.30 { // 0.30 Gs is the minimum force of normal steering needed to prove the driver is awake.
            lastMovementTime = Date()
            isStill = false
            if motionDangerScore > 0 { updateScore(to: max(0, motionDangerScore - 2)) }
        }
    }
    
    private func evaluateRealData() {
        if calibrationSeconds < CALIBRATION_LIMIT {
            calibrationSeconds += 1
            if currentBPM > 40 { hrReadings.append(currentBPM) }
            
            if calibrationSeconds == CALIBRATION_LIMIT {
                let sum = hrReadings.reduce(0, +)
                let avg = hrReadings.isEmpty ? 75.0 : sum / Double(hrReadings.count)
                dynamicHRDropThreshold = avg * 0.85 // The driver's heart rate must drop 15% below their baseline to increase risk points.
                updateScore(to: 0)
            } else {
                updateScore(to: -1)
            }
            return
        }
        
        let secondsSinceLastMove = Date().timeIntervalSince(lastMovementTime)
        var scoreIncrement = 0
        
        if secondsSinceLastMove > 8.0 { // 8.0 seconds of a dead-still wrist triggers a risk point increase.
            scoreIncrement += 1
            isStill = true
        } else {
            isStill = false
        }
        
        if currentBPM > 0 && currentBPM < dynamicHRDropThreshold {
            scoreIncrement += 1
        }
        
        if scoreIncrement > 0 {
            if hapticTimer == nil || activeStage == 3 {
                updateScore(to: min(100, motionDangerScore + scoreIncrement))
            }
        }
        manageStages()
    }
    
    private func manageStages() {
        let targetStage: Int
        if motionDangerScore >= 90 { targetStage = 3 }
        else if motionDangerScore >= 70 { targetStage = 2 }
        else if motionDangerScore >= 40 { targetStage = 1 }
        else { targetStage = 0 }
        
        if targetStage != activeStage {
            if targetStage == 3 { triggerStage3() }
            else if targetStage == 2 { triggerStage2() }
            else if targetStage == 1 { triggerStage1() }
            else {
                stopHaptics()
                activeStage = 0
            }
        }
    }
    
    private func triggerStage1() {
        stopHaptics()
        activeStage = 1
        hapticTicks = 0
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.activeStage != 1 { return }
            
            if self.hapticTicks < 50 { // 50 ticks = 15 seconds of vibration for Stage 1.
                WKInterfaceDevice.current().play(.start)
                self.hapticTicks += 1
            } else {
                self.stopHaptics()
                self.lastMovementTime = Date()
            }
        }
    }
    
    private func triggerStage2() {
        stopHaptics()
        activeStage = 2
        hapticTicks = 0
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.activeStage != 2 { return }
            
            if self.hapticTicks < 66 { // 66 ticks = 20 seconds of vibration for Stage 2.
                WKInterfaceDevice.current().play(.start)
                self.hapticTicks += 1
            } else if self.hapticTicks == 66 {
                ConnectivityManager.shared.sendCommand("speakStage2")
                self.hapticTicks += 1
            } else {
                self.stopHaptics()
                self.lastMovementTime = Date()
            }
        }
    }
    
    private func triggerStage3() {
        stopHaptics()
        activeStage = 3
        hapticTicks = 0
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.activeStage != 3 { return }
            
            let cycleTick = self.hapticTicks % 100 // 100 ticks = 30 second total cycle loop for Stage 3.
            
            if cycleTick < 83 { // 83 ticks = 25 seconds of vibration before the voice alert.
                WKInterfaceDevice.current().play(.start)
            } else if cycleTick == 83 {
                ConnectivityManager.shared.sendCommand("speakStage3")
            }
            self.hapticTicks += 1
        }
    }

    private func stopHaptics() {
        hapticTimer?.invalidate()
        hapticTimer = nil
    }

    private func updateScore(to newScore: Int) {
        DispatchQueue.main.async {
            self.motionDangerScore = newScore
            ConnectivityManager.shared.sendTelemetry(score: newScore, hr: self.currentBPM, still: self.isStill)
        }
    }
    
    private func startWorkoutSession() {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            workoutSession?.startActivity(with: Date())
        } catch { print("Failed to start session") }
    }
    
    private func startHeartRateQuery() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, _, _ in
            self?.fetchLatestHeartRate()
        }
        healthStore.execute(query)
    }
    
    private func fetchLatestHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, results, _ in
            guard let sample = results?.first as? HKQuantitySample else { return }
            let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            DispatchQueue.main.async { self?.currentBPM = bpm }
        }
        healthStore.execute(query)
    }
}
