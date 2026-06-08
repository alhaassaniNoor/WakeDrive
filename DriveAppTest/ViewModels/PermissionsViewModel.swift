import SwiftUI
import Combine
import CoreLocation
import HealthKit
import UserNotifications

class PermissionsViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var allPermissionsGranted = false
    @Published var isDenied = false
    
    private let locationManager = CLLocationManager()
    // Connect to the HealthManager we just created
    private let healthManager = HealthManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        checkLocationStatus()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkLocationStatus),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    func requestAllPermissions() {
        // 1. Ask for Location
        locationManager.requestAlwaysAuthorization()
        
        // 2. Ask for Health using the unified HealthManager (Staggered to prevent black screen)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.healthManager.requestPermissions { success in
                print("HealthKit Authorization Success: \(success)")
            }
        }
        
        // 3. Ask for Notifications
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                if granted { print("Notifications allowed") }
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationStatus()
    }
    
    @objc private func checkLocationStatus() {
        let status = locationManager.authorizationStatus
        DispatchQueue.main.async {
            self.isDenied = (status == .denied || status == .restricted)
        }
    }
}
