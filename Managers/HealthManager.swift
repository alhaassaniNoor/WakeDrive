import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var currentHeartRate: Double = 0
    @Published var isAuthorized: Bool = false
    
    // This is what triggers the popup in your onboarding
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        // 🚨 FIXED: Removed the impossible HRV request to clear App Store guidelines
        let typesToRead: Set = [heartRateType, sleepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                completion(success)
            }
        }
    }

    // This is what MotionManager will use to get your live data
    func startHeartRateQuery(completion: @escaping (Double) -> Void) {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: 1) { _, samples, _, _, _ in
            if let lastSample = samples?.last as? HKQuantitySample {
                let bpm = lastSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                DispatchQueue.main.async { completion(bpm) }
            }
        }
        healthStore.execute(query)
    }
}
