import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentSpeed: Int = 0
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 10
        
        // Match the Always strategy used in your Permissions view model
        manager.requestAlwaysAuthorization()
        manager.allowsBackgroundLocationUpdates = true
        
        // This allows iOS to pause updates if the user stops moving for a long time, saving battery
        manager.pausesLocationUpdatesAutomatically = true
        manager.activityType = .automotiveNavigation
        
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Convert meters per second to km/h
        let speedInKmH = location.speed * 3.6
        let calculatedSpeed = speedInKmH > 0 ? Int(speedInKmH) : 0
        
        DispatchQueue.main.async {
            self.currentSpeed = calculatedSpeed
            
            if ConnectivityManager.shared.isDriving {
                ConnectivityManager.shared.addSpeedReading(calculatedSpeed)
            }
        }
    }
}
