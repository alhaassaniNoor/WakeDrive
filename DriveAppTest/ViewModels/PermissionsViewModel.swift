import SwiftUI
import Combine
import CoreLocation
import HealthKit
import UserNotifications

class PermissionsViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var allPermissionsGranted = false
    
    private let locationManager = CLLocationManager()
    private let healthStore = HKHealthStore()
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestAllPermissions() {
        requestLocation()
        requestHealthKit()
        requestNotifications()
    }
    
    private func requestLocation() {
        locationManager.requestAlwaysAuthorization()
    }
    
    private func requestHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        // 🚨 NEW: Added Sleep Analysis to the requested types
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        let typesToRead: Set = [heartRateType, hrvType, sleepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit Error: \(error.localizedDescription)")
            } else {
                print("HealthKit access granted!")
            }
        }
    }
    
    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notifications allowed - Crucial for Stage 2 & 3 audio alerts")
            }
        }
    }
}
