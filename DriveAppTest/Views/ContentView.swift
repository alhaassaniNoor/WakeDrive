import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PermissionsViewModel()
    @State private var permissionsRequested = false
    @AppStorage("userName") var userName: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Spacer()
                Image(systemName: "steeringwheel")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                Text("WakeDrive")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Identify yourself:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Enter your name", text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 50)
                
                Text("We monitor your wrist movement and speed to keep you safe. Please keep your phone mounted and focus on the road.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !permissionsRequested {
                    Button(action: {
                        viewModel.requestAllPermissions()
                        permissionsRequested = true
                    }) {
                        Text("Grant Permissions")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(userName.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .disabled(userName.isEmpty)
                } else {
                    NavigationLink(destination: DriveModeView()) {
                        Text("Start Trip")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }
                Spacer()
            }
        }
    }
}

struct DriveModeView: View {
    @StateObject private var connectivity = ConnectivityManager.shared
    @StateObject private var locationManager = LocationManager()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text(connectivity.isDriving ? "LIVE TELEMETRY" : "TRIP ENDED")
                .font(.headline)
                .foregroundColor(connectivity.isDriving ? .green : .secondary)
                .padding(.top, 10)
            
            // 1. MASSIVE CENTER BUBBLE: RISK LEVEL
            VStack(spacing: 5) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(connectivity.currentSleepScore > 70 ? .red : (connectivity.currentSleepScore > 40 ? .orange : .green))
                
                Text("\(connectivity.currentSleepScore)")
                    .font(.system(size: 90, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("SLEEP RISK SCORE")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(30)
            .padding(.horizontal, 20)
            
            // 2. SMALLER METRIC BUBBLES
            HStack(spacing: 15) {
                StatusBubble(
                    title: "Heart Rate",
                    value: "\(Int(connectivity.currentHeartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                StatusBubble(
                    title: "Motion",
                    value: connectivity.isStill ? "Still" : "Active",
                    unit: "Wrist",
                    icon: connectivity.isStill ? "hand.raised.slash.fill" : "hand.wave.fill",
                    color: .orange
                )
                
                StatusBubble(
                    title: "Speed",
                    value: "\(Int(locationManager.currentSpeed))",
                    unit: "km/h",
                    icon: "speedometer",
                    color: .blue
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 3. THE KILL SWITCH
            Button(action: {
                connectivity.isDriving = false
                connectivity.sendDriveStatus(isStarting: false)
                locationManager.stopTracking()
                AlertManager.shared.stopAllAlerts()
                
                // Reset bubbles visually
                connectivity.currentSleepScore = 0
                connectivity.currentHeartRate = 0
                connectivity.isStill = false
                
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("End Drive Mode")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(15)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 30)
        .navigationBarBackButtonHidden(true)
    }
}

// BUBBLE UI COMPONENT
struct StatusBubble: View {
    var title: String
    var value: String
    var unit: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                Text(unit)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
    }
}
