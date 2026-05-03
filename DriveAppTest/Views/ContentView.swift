import SwiftUI
import HealthKit
import CoreLocation
import Combine

// Codable allows the trip data to be converted saved permanently to the iPhone's storage. (should change to swiftdata)
struct Trip: Identifiable, Codable {
    var id = UUID(); var date: String; var duration: String; var avgSpeed: Int; var avgHR: Int; var hadSleepWarning: Bool
}

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @StateObject private var connectivity = ConnectivityManager.shared
    
    var body: some View {
        if !hasCompletedOnboarding {
            MasterOnboardingView(hasCompleted: $hasCompletedOnboarding)
        } else if !connectivity.isWatchAppInstalled {
            WatchSetupView()
        } else if connectivity.isDriving {
            DriveModeView()
        } else {
            HomeView()
        }
    }
}

struct MasterOnboardingView: View {
    @Binding var hasCompleted: Bool
    @State private var step = 1
    @AppStorage("userName") var userName: String = ""
    
    var body: some View {
        VStack {
            if step == 1 {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "info.circle.fill").font(.system(size: 80)).foregroundColor(.blue)
                    Text("The Reality").font(.largeTitle).fontWeight(.black)
                    VStack(alignment: .leading, spacing: 15) {
                        Text("According to the World Health Organization, sleepiness while driving may contribute to more than 30% of road traffic accidents worldwide, causing 1.3 million deaths every year.")
                        Text("In the United States alone, drowsy driving has been linked to around 100,000 crashes annually, causing thousands of injuries and hundreds of deaths.")
                    }.font(.subheadline).padding(30).background(Color.blue.opacity(0.1)).cornerRadius(15).padding(.horizontal, 20)
                    Spacer()
                    Button(action: { step = 2 }) { Text("I Understand").font(.headline).bold().foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.blue).cornerRadius(15).padding(.horizontal, 40) }.padding(.bottom, 40)
                }
            } else if step == 2 {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "brain.head.profile").font(.system(size: 80)).foregroundColor(.purple)
                    Text("How WakeDrive Works").font(.largeTitle).fontWeight(.black)
                    VStack(alignment: .leading, spacing: 20) {
                        HStack { Image(systemName: "heart.text.square"); Text("Monitors sudden drops in your heart rate.") }
                        HStack { Image(systemName: "steeringwheel"); Text("Tracks steering wheel micro-movements.") }
                        HStack { Image(systemName: "bell.and.waveform"); Text("Delivers physical haptics and voice alerts if you drift off.") }
                    }.font(.headline).padding(.horizontal, 40)
                    Spacer()
                    Button(action: { step = 3 }) { Text("Next").font(.headline).bold().foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.blue).cornerRadius(15).padding(.horizontal, 40) }.padding(.bottom, 40)
                }
            } else if step == 3 {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "heart.text.square.fill").font(.system(size: 80)).foregroundColor(.red)
                    Text("Health Access").font(.largeTitle).fontWeight(.black)
                    Text("WakeDrive needs access to your Heart Rate data to accurately calculate your sleep risk score in real-time.").multilineTextAlignment(.center).padding(.horizontal, 40).foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        let healthStore = HKHealthStore()
                        let readTypes = Set([HKObjectType.quantityType(forIdentifier: .heartRate)!])
                        // Requests heart rate access to establish a baseline and detect drops caused by drowsiness.
                        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, _ in DispatchQueue.main.async { step = 4 } }
                    }) { Text("Grant Health Access").font(.headline).bold().foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.red).cornerRadius(15).padding(.horizontal, 40) }.padding(.bottom, 40)
                }
            } else if step == 4 {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "location.fill").font(.system(size: 80)).foregroundColor(.green)
                    Text("Location Access").font(.largeTitle).fontWeight(.black)
                    Text("WakeDrive needs access to your location to track your driving speed and keep the app active in the background.").multilineTextAlignment(.center).padding(.horizontal, 40).foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        let manager = CLLocationManager()
                        // Requests location access to measure driving speed and keep the iOS app active in the background.
                        manager.requestWhenInUseAuthorization()
                        step = 5
                    }) { Text("Grant Location Access").font(.headline).bold().foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.green).cornerRadius(15).padding(.horizontal, 40) }.padding(.bottom, 40)
                }
            } else if step == 5 {
                VStack(spacing: 30) {
                    Spacer()
                    Image(systemName: "person.crop.circle").font(.system(size: 80)).foregroundColor(.blue)
                    Text("Who is driving?").font(.largeTitle).fontWeight(.black)
                    TextField("Tap here to enter your name", text: $userName).font(.title3).padding(20).background(Color(UIColor.systemGray5)).cornerRadius(15).padding(.horizontal, 40).autocorrectionDisabled().submitLabel(.done)
                    Spacer()
                    Button(action: { hasCompleted = true }) { Text("Finish Setup").font(.headline).bold().foregroundColor(.white).frame(maxWidth: .infinity).padding().background(userName.isEmpty ? Color.gray : Color.blue).cornerRadius(15).padding(.horizontal, 40) }.disabled(userName.isEmpty).padding(.bottom, 40)
                }
            }
        }
    }
}

struct WatchSetupView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "applewatch.radiowaves.left.and.right").font(.system(size: 90)).foregroundColor(.orange)
            Text("Connect Watch").font(.title).bold()
            Text("WakeDrive needs the Apple Watch app to monitor your heart rate and arm movement.").multilineTextAlignment(.center).padding(.horizontal, 40).foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 15) {
                HStack { Image(systemName: "1.circle.fill"); Text("Close this app and open the 'Watch' app.") }
                HStack { Image(systemName: "2.circle.fill"); Text("Scroll to the bottom & tap 'Install'.") }
            }.font(.headline).padding(.vertical, 20)
            Spacer()
            HStack { ProgressView().padding(.trailing, 5); Text("Waiting for installation...").font(.caption).foregroundColor(.gray) }.padding(.bottom, 40)
        }
    }
}

struct HomeView: View {
    @AppStorage("userName") var userName: String = ""
    @StateObject private var connectivity = ConnectivityManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 15) {
                        Image(systemName: "car.fill").font(.system(size: 40)).foregroundColor(.green)
                        Text("Ready to Drive").font(.title2).bold()
                        Text("Start the trip from your Apple Watch.").multilineTextAlignment(.center).foregroundColor(.secondary).font(.subheadline).padding(.horizontal)
                    }.frame(maxWidth: .infinity).padding(.vertical, 30).background(Color(UIColor.secondarySystemBackground)).cornerRadius(20).padding(.horizontal, 20)
                    
                    Text("Recent Trips").font(.title3).bold().padding(.horizontal, 20).padding(.top, 10)
                    
                    if connectivity.pastTrips.isEmpty {
                        Text("No trips recorded yet. Start driving to see your data!").foregroundColor(.secondary).padding(.horizontal, 20)
                    } else {
                        ForEach(connectivity.pastTrips) { trip in TripCardView(trip: trip) }
                    }
                    
                }.padding(.bottom, 30)
            }
            // Gracefully falls back to "Hello, Driver" if the user left the name field blank during setup.
            .navigationTitle(userName.isEmpty ? "Hello, Driver" : "Hello, \(userName)")
        }
    }
}

struct TripCardView: View {
    let trip: Trip
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack { Text(trip.date).font(.headline); Spacer(); Text(trip.duration).font(.subheadline).foregroundColor(.secondary) }
            HStack(spacing: 20) {
                VStack(alignment: .leading) { Text("AVG SPEED").font(.caption2).foregroundColor(.secondary).bold(); Text("\(trip.avgSpeed) km/h").font(.headline) }
                VStack(alignment: .leading) { Text("AVG HR").font(.caption2).foregroundColor(.secondary).bold(); Text("\(trip.avgHR) BPM").font(.headline) }
            }
            HStack(alignment: .top) {
                Image(systemName: trip.hadSleepWarning ? "exclamationmark.triangle.fill" : "checkmark.shield.fill").foregroundColor(trip.hadSleepWarning ? .orange : .green)
                Text(trip.hadSleepWarning ? "Alarm Triggered. Sleep risk detected." : "Perfectly alert. Safe driving patterns detected.").font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
            }.padding(10).background(trip.hadSleepWarning ? Color.orange.opacity(0.1) : Color.green.opacity(0.1)).cornerRadius(8)
        }.padding().background(Color(UIColor.tertiarySystemBackground)).cornerRadius(15).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5).padding(.horizontal, 20)
    }
}

struct DriveModeView: View {
    @StateObject private var connectivity = ConnectivityManager.shared
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("LIVE TELEMETRY").font(.headline).foregroundColor(connectivity.currentSleepScore == -1 ? .blue : .green).padding(.top, 60)
            
            VStack(spacing: 5) {
                if connectivity.currentSleepScore == -1 {
                    Image(systemName: "waveform.path.ecg").font(.system(size: 40)).foregroundColor(.blue)
                    Text("CALIBRATING").font(.system(size: 40, weight: .black, design: .rounded)).foregroundColor(.blue).padding(.vertical, 10)
                    Text("Establishing vital baselines...").font(.subheadline).bold().foregroundColor(.secondary)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 40))
                        // Controls the UI color of the risk score based on the current stage danger level.
                        .foregroundColor(connectivity.currentSleepScore >= 70 ? .red : (connectivity.currentSleepScore >= 40 ? .orange : .green))
                    Text("\(connectivity.currentSleepScore)").font(.system(size: 100, weight: .black, design: .rounded))
                    Text("SLEEP RISK SCORE").font(.subheadline).bold().foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 40).background(Color(UIColor.secondarySystemBackground)).cornerRadius(30).padding(.horizontal, 20)
            
            HStack(spacing: 15) {
                StatusBubble(title: "Heart Rate", value: "\(Int(connectivity.currentHeartRate))", unit: "BPM", icon: "heart.fill", color: .red)
                StatusBubble(title: "Motion", value: connectivity.isStill ? "Still" : "Active", unit: "Wrist", icon: connectivity.isStill ? "hand.raised.slash.fill" : "hand.wave.fill", color: .orange)
                StatusBubble(title: "Speed", value: "\(locationManager.currentSpeed < 5 ? 0 : locationManager.currentSpeed)", unit: "km/h", icon: "speedometer", color: .blue)
            }.padding(.horizontal, 20)
            
            Spacer()
            
            Button(action: {
                connectivity.sendDriveStatus(isStarting: false)
            }) {
                Text("End Drive Mode").font(.title3).bold().foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.red).cornerRadius(15).padding(.horizontal, 20)
            }.padding(.bottom, 20)
        }
        // Records the driver's current speed and heart rate every 5 seconds to calculate the final trip averages.
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            let cleanSpeed = locationManager.currentSpeed < 5 ? 0 : locationManager.currentSpeed
            connectivity.addTelemetry(speed: cleanSpeed, hr: connectivity.currentHeartRate)
        }
    }
}

struct StatusBubble: View {
    var title: String; var value: String; var unit: String; var icon: String; var color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.headline).foregroundColor(color)
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.5)
            VStack(spacing: 2) { Text(title).font(.system(size: 10, weight: .bold)); Text(unit).font(.system(size: 9)).foregroundColor(.secondary) }
        }.frame(maxWidth: .infinity).padding(.vertical, 15).background(Color(UIColor.secondarySystemBackground)).cornerRadius(20)
    }
}
