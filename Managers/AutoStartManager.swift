import Foundation
import CoreMotion
import UserNotifications
import Combine // 🚨 FIXED: Added this missing import!

class AutoStartManager: ObservableObject {
    static let shared = AutoStartManager()
    
    private let activityManager = CMMotionActivityManager()
    private var isCurrentlyDriving = false
    
    private init() {}
    
    func startMonitoring() {
        // Make sure the device actually supports motion tracking
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            
            // If the iPhone detects car movement and we haven't already fired the alert
            if activity.automotive && !activity.stationary {
                if !self.isCurrentlyDriving {
                    self.isCurrentlyDriving = true
                    
                    // Only send the notification if the app isn't already actively tracking a drive
                    if !ConnectivityManager.shared.isDriving {
                        self.sendDrivingNotification()
                    }
                }
            }
            // Reset the flag if they start walking or stand still
            else if activity.walking || activity.running || activity.stationary {
                self.isCurrentlyDriving = false
            }
        }
    }
    
    private func sendDrivingNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Driving Detected 🚗"
        content.body = "Tap to start Copirrot and stay safe on the road."
        content.sound = .default
        
        // This is the magic line that makes it a "Smart Notification" that breaks through Focus modes
        content.interruptionLevel = .timeSensitive
        
        // A nil trigger means it delivers instantly
        let request = UNNotificationRequest(identifier: "AutoStartPrompt", content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send auto-start notification: \(error.localizedDescription)")
            }
        }
    }
}
