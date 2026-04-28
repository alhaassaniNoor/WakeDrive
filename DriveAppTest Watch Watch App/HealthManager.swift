import Foundation
import HealthKit
import Combine 

class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var currentHeartRate: Double = 0
    
    // We'll use this to compare current HR to a baseline
    private var heartRateQuery: HKAnchoredObjectQuery?

    func requestPermissions(completion: @escaping (Bool) -> Void) {
        // We only need to READ Heart Rate
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let typesToRead: Set = [heartRateType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            completion(success)
        }
    }
    
    func startHeartRateQuery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, newAnchor, error) in
            self.updateHeartRate(samples)
        }
        
        query.updateHandler = { (query, samples, deletedObjects, newAnchor, error) in
            self.updateHeartRate(samples)
        }
        
        healthStore.execute(query)
        self.heartRateQuery = query
    }
    
    private func updateHeartRate(_ samples: [HKSample]?) {
        guard let heartSamples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            guard let lastSample = heartSamples.last else { return }
            let hrUnit = HKUnit(from: "count/min")
            self.currentHeartRate = lastSample.quantity.doubleValue(for: hrUnit)
            print("Current Heart Rate: \(self.currentHeartRate) BPM")
        }
    }
    
    func stopQuery() {
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
    }
}
