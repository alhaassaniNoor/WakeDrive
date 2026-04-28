import Foundation
import CoreLocation
import Combine 

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentSpeed: Double = 0 // in km/h
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 10 // Only update every 10 meters to save battery
        manager.allowsBackgroundLocationUpdates = true
    }
    
    func startTracking() {
        manager.startUpdatingLocation()
    }
    
    func stopTracking() {
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Convert m/s to km/h
        let speedInKmH = location.speed * 3.6
        self.currentSpeed = speedInKmH > 0 ? speedInKmH : 0
    }
}
