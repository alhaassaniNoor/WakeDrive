import SwiftUI
import SwiftData
import HealthKit
import CoreLocation
import Combine

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @StateObject private var connectivity = ConnectivityManager.shared
    
    var body: some View {
        if !hasCompletedOnboarding {
            MasterOnboardingView(hasCompleted: $hasCompletedOnboarding)
        } else if !connectivity.isWatchAppInstalled {
            WatchSetupView()
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
            HStack { ProgressView().padding(.trailing, 5); Text("Waiting for connection...").font(.caption).foregroundColor(.gray) }.padding(.bottom, 40)
        }
    }
}

struct HomeView: View {
    @AppStorage("userName") var userName: String = ""
    @StateObject private var connectivity = ConnectivityManager.shared
    @StateObject private var locationManager = LocationManager()
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.date, order: .reverse) private var pastTrips: [Trip]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    // 🚨 Fixed: Added top padding so it doesn't suffocate the "Hello Juri" title
                    if connectivity.isDriving {
                        ActiveTripCard(connectivity: connectivity)
                            .padding(.top, 20)
                    } else {
                        ReadyToDriveCard()
                            .padding(.top, 20)
                    }
                    
                    Text("Recent Trips")
                        .font(.title3).bold()
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    // 🚨 Fixed: Always shows recent trips, no matter if driving or not!
                    if pastTrips.isEmpty {
                        Text("No trips recorded yet. Start driving to see your data!")
                            .foregroundColor(.secondary).padding(.horizontal, 20)
                    } else {
                        ForEach(pastTrips) { trip in
                            TripCardView(trip: trip)
                        }
                    }
                    
                }.padding(.bottom, 30)
            }
            .navigationTitle(userName.isEmpty ? "Hello, Driver" : "Hello, \(userName)")
            .onChange(of: connectivity.newlyCompletedTripData) { oldValue, newValue in
                if let data = newValue {
                    let newTrip = Trip(date: data.date, duration: data.duration, avgSpeed: data.speed, avgHR: data.hr, hadSleepWarning: data.warning)
                    modelContext.insert(newTrip)
                    connectivity.newlyCompletedTripData = nil
                }
            }
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            if connectivity.isDriving {
                let cleanSpeed = locationManager.currentSpeed < 5 ? 0 : locationManager.currentSpeed
                connectivity.addTelemetry(speed: cleanSpeed, hr: connectivity.currentHeartRate)
            }
        }
    }
}

struct ReadyToDriveCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ready to Drive")
                .font(.title3).bold()
                .foregroundColor(.black)
            
            HStack(alignment: .bottom) {
                Text("Start the trip directly from your Apple Watch. Your phone will automatically become your dashboard.")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.8))
                
                Spacer()
                
                Image(systemName: "car.top.radiowaves.rear.left.and.rear.right")
                    .font(.system(size: 40))
                    .foregroundColor(.black)
            }
        }
        .padding(20)
        .background(Color.yellow)
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
}

struct ActiveTripCard: View {
    @ObservedObject var connectivity: ConnectivityManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Active Trip")
                .font(.title2)
                .foregroundColor(.white)
            
            Image(systemName: "steeringwheel")
                .font(.system(size: 50))
                .foregroundColor(.green)
                .padding(.vertical, 10)
            
            Button(action: {
                connectivity.sendDriveStatus(isStarting: false)
            }) {
                Text("End Trip")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(15)
            }
        }
        .padding(25)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(25)
        .padding(.horizontal, 20)
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
