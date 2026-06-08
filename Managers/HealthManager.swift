import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var currentHeartRate: Double = 0
    @Published var isAuthorized: Bool = false

    func requestPermissions(completion: @escaping (Bool) -> Void) {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let typesToRead: Set = [heartRateType, hrvType, sleepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                self.isAuthorized = success
                completion(success)
            }
        }
    }
}
