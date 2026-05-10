import Foundation
import SwiftData

@Model
class Trip: Identifiable {
    var id: UUID
    var date: String
    var duration: String
    var avgSpeed: Int
    var avgHR: Int
    var hadSleepWarning: Bool

    init(date: String, duration: String, avgSpeed: Int, avgHR: Int, hadSleepWarning: Bool) {
        self.id = UUID()
        self.date = date
        self.duration = duration
        self.avgSpeed = avgSpeed
        self.avgHR = avgHR
        self.hadSleepWarning = hadSleepWarning
    }
}
