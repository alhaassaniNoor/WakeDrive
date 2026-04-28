import Foundation
import CoreMotion
import Combine
import WatchKit

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    @Published var motionDangerScore = 0
    var currentBPM: Double = 0
    var isStill: Bool = false
    
    private var lastMovementTime = Date()
    private var stillnessTimer: Timer?
    
    // Haptic Stage Controls
    private var hapticTimer: Timer?
    private var hapticTicks = 0
    private var maxHapticTicks = 0
    private var currentHapticStage = 0
    
    func startTracking() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionDangerScore = 0
        isStill = false
        lastMovementTime = Date()
        currentHapticStage = 0
        
        motionManager.deviceMotionUpdateInterval = 0.5
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            self.analyzeMovement(motion)
        }
        
        stillnessTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkStillness()
        }
    }
    
    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
        
        // RUTHLESSLY KILL ALL TIMERS AND RESET SCORE
        stillnessTimer?.invalidate()
        stillnessTimer = nil
        
        hapticTimer?.invalidate()
        hapticTimer = nil
        currentHapticStage = 0
        
        motionDangerScore = 0
    }
    
    private func analyzeMovement(_ motion: CMDeviceMotion) {
        // --- THE STAGE 3 HARD LOCK ---
        // If score is 90+, ignore arm movement. They MUST press the button.
        guard motionDangerScore < 90 else { return }
        
        let accelX = abs(motion.userAcceleration.x)
        let accelY = abs(motion.userAcceleration.y)
        let accelZ = abs(motion.userAcceleration.z)
        let totalForce = accelX + accelY + accelZ
        
        // If they jerk the wheel, spike the score (but only if not already in Stage 3)
        if totalForce > 2.5 {
            updateScore(to: min(100, motionDangerScore + 20))
            WKInterfaceDevice.current().play(.directionUp)
        } else if totalForce > 0.15 {
            // Normal movement keeps them safe
            lastMovementTime = Date()
            isStill = false
            
            if motionDangerScore > 0 {
                updateScore(to: max(0, motionDangerScore - 2))
            }
            // Stop early haptics if they moved
            if motionDangerScore < 40 {
                stopHaptics()
            }
        }
    }
    
    private func checkStillness() {
        let secondsSinceLastMove = Date().timeIntervalSince(lastMovementTime)
        var scoreIncrement = 0
        
        // FACTOR 1: Physical Stillness
        if secondsSinceLastMove > 5.0 {
            scoreIncrement += 5
            isStill = true
        }
        
        // FACTOR 2: Biological Signal (Heart Rate Drop)
        if currentBPM > 0 && currentBPM < 55 {
            scoreIncrement += 5
        }
        
        if scoreIncrement > 0 && motionDangerScore < 100 {
            updateScore(to: motionDangerScore + scoreIncrement)
        }
        
        triggerStageHaptics()
    }

    private func triggerStageHaptics() {
        if motionDangerScore >= 90 && currentHapticStage != 3 {
            // STAGE 3: 20+ Seconds (Loops until reset)
            startHapticSequence(duration: 999, type: .retry, stage: 3)
        } else if motionDangerScore >= 70 && motionDangerScore < 90 && currentHapticStage != 2 {
            // STAGE 2: 15 Seconds
            startHapticSequence(duration: 15, type: .failure, stage: 2)
        } else if motionDangerScore >= 40 && motionDangerScore < 70 && currentHapticStage != 1 {
            // STAGE 1: 10 Seconds
            startHapticSequence(duration: 10, type: .directionUp, stage: 1)
        }
    }

    private func startHapticSequence(duration: Int, type: WKHapticType, stage: Int) {
        stopHaptics()
        currentHapticStage = stage
        maxHapticTicks = duration
        hapticTicks = 0
        
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            if self.hapticTicks < self.maxHapticTicks {
                WKInterfaceDevice.current().play(type)
                self.hapticTicks += 1
            } else {
                self.stopHaptics()
                // If it wasn't stage 3, reset stage memory so it can fire again if needed
                if stage != 3 { self.currentHapticStage = 0 }
            }
        }
    }

    private func stopHaptics() {
        hapticTimer?.invalidate()
        hapticTimer = nil
        // Only clear the stage memory if we are back in the safe zone
        if motionDangerScore < 40 { currentHapticStage = 0 }
    }

    private func updateScore(to newScore: Int) {
        DispatchQueue.main.async {
            self.motionDangerScore = newScore
            ConnectivityManager.shared.sendTelemetry(score: newScore, hr: self.currentBPM, still: self.isStill)
        }
    }
}           
