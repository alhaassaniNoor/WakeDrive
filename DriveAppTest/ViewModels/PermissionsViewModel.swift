import SwiftUI
import Combine
import CoreLocation
import HealthKit
import UserNotifications

class PermissionsViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var allPermissionsGranted = false
    @Published var isDenied = false // 🚨 Tracks if the user pressed "Don't Allow"
    
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
    
    // 🚨 Listens for the user's choice. If denied, triggers the hard-stop screen.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async {
            if status == .denied || status == .restricted {
                self.isDenied = true
            } else if status == .authorizedAlways || status == .authorizedWhenInUse {
                self.isDenied = false
            }
        }
    }
    
    private func requestHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        let typesToRead: Set = [heartRateType, hrvType, sleepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notifications allowed")
            }
        }
    }
}
