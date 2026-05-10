import SwiftUI
import SwiftData

@main
struct DriveAppTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Wires up SwiftData to the entire app
        .modelContainer(for: Trip.self)
    }
}
