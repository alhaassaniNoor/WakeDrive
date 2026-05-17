import SwiftUI
import SwiftData
import HealthKit
import CoreLocation
import Combine

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @StateObject private var connectivity = ConnectivityManager.shared
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                MasterOnboardingView(hasCompleted: $hasCompletedOnboarding)
            } else if !connectivity.isWatchAppInstalled {
                WatchSetupView()
            } else {
                HomeView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Onboarding Flow
struct MasterOnboardingView: View {
    @Binding var hasCompleted: Bool
    @State private var step = 1
    @StateObject private var permissions = PermissionsViewModel()
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userGender") var userGender: String = "Not Specified"
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "000000").edgesIgnoringSafeArea(.all)
                
                if step == 1 {
                    VStack(alignment: .leading) {
                        Text("Smart alerts,\nKeep you focused.")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 80)
                            .padding(.horizontal, 30)
                        Spacer()
                        
                        HStack(spacing: 0) {
                            Image("bird")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.85)
                            Spacer(minLength: 0)
                        }
                        .edgesIgnoringSafeArea(.bottom)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { step = 2 }
                        }
                    }
                    
                } else if step == 2 {
                    VStack(alignment: .leading) {
                        Text("Let's keep you safe on\nthe road")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 80)
                            .padding(.horizontal, 30)
                        
                        Text("We just need a couple of things\nto watch out for you while driving.")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 10)
                            .padding(.horizontal, 30)
                        
                        Spacer()
                        
                        HStack(spacing: 0) {
                            Image("bird")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.85)
                            Spacer(minLength: 0)
                        }
                        .edgesIgnoringSafeArea(.bottom)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation { step = 3 } }
                    
                } else if step == 3 {
                    VStack(alignment: .leading, spacing: 35) {
                        Text("Welcome to\nDREM")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 60)
                        
                        VStack(spacing: 35) {
                            PermissionRow(icon: "heart.text.square", title: "Connect to Health", desc: "We use your heart rate & sleep data to detect when you're getting tired.")
                            PermissionRow(icon: "location", title: "Driving Activity", desc: "We track your drive to send you smart alerts in real-time.")
                            PermissionRow(icon: "bell", title: "Notifications", desc: "We want to send you smart alerts in real-time.")
                        }
                        .padding(.top, 40)
                        
                        Spacer()
                        
                        Button(action: {
                            permissions.requestAllPermissions()
                            withAnimation { step = 4 }
                        }) {
                            Text("Continue")
                                .font(.headline).bold()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "247FA6"))
                                .cornerRadius(30)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 30)
                    
                } else if step == 4 {
                    VStack(alignment: .leading, spacing: 30) {
                        Text("Almost there")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 60)
                        
                        Text("Tell us a bit about yourself to personalize your experience.")
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Name")
                                .font(.headline)
                                .foregroundColor(.white)
                            TextField("Enter your name", text: $userName)
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(15)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Gender")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 15) {
                                GenderButton(title: "Female", selected: $userGender)
                                GenderButton(title: "Male", selected: $userGender)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            hasCompleted = true
                        }) {
                            Text("Finish")
                                .font(.headline).bold()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(userName.isEmpty || userGender == "Not Specified" ? Color.gray : Color(hex: "247FA6"))
                                .cornerRadius(30)
                        }
                        .disabled(userName.isEmpty || userGender == "Not Specified")
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 30)
                }
            }
        }
    }
}

// MARK: - Components for Onboarding
struct PermissionRow: View {
    let icon: String; let title: String; let desc: String
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(Color(hex: "FEB504"))
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline).foregroundColor(.white)
                Text(desc).font(.subheadline).foregroundColor(.gray)
            }
        }
    }
}

struct GenderButton: View {
    let title: String
    @Binding var selected: String
    var body: some View {
        Button(action: { selected = title }) {
            Text(title)
                .font(.headline)
                .foregroundColor(selected == title ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(selected == title ? Color(hex: "247FA6").opacity(0.3) : Color(UIColor.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(selected == title ? Color(hex: "247FA6") : Color.clear, lineWidth: 2)
                )
                .cornerRadius(15)
        }
    }
}

// MARK: - Watch Setup
struct WatchSetupView: View {
    var body: some View {
        ZStack {
            Color(hex: "000000").edgesIgnoringSafeArea(.all)
            VStack(spacing: 40) {
                Spacer()
                
                Image(systemName: "applewatch.and.arrow.forward")
                    .font(.system(size: 100))
                    .foregroundColor(Color(hex: "FEB504"))
                
                Text("Connect Apple Watch")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                
                Text("DREM needs the Apple Watch app to monitor heart rate and arm movement.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                
                VStack(alignment: .center, spacing: 25) {
                    Text("1) Close this app and open the 'Watch' app.")
                    Text("2) Scroll to the bottom and tap 'Install'.")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                Spacer()
                
                HStack {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .gray)).padding(.trailing, 5)
                    Text("Waiting for connection...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Main Home Dashboard
struct HomeView: View {
    @AppStorage("userName") var userName: String = ""
    @StateObject private var connectivity = ConnectivityManager.shared
    @StateObject private var locationManager = LocationManager()
    @StateObject private var sleepManager = SleepManager()
    
    @State private var showProfileEdit = false
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.date, order: .reverse) private var pastTrips: [Trip]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "000000").edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        // Header
                        HStack {
                            Text("Hello \(userName.isEmpty ? "Driver" : userName),")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            
                            Button(action: { showProfileEdit = true }) {
                                Circle()
                                    .fill(Color(hex: "247FA6"))
                                    .frame(width: 40, height: 40)
                                    .overlay(Text(String(userName.prefix(1).uppercased())).font(.headline).foregroundColor(.white))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Main Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("• APPLE WATCH PAIRED")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "247FA6"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(hex: "247FA6").opacity(0.2))
                                .cornerRadius(10)
                            
                            Text(connectivity.isDriving ? "Active Trip" : "Ready to Drive")
                                .font(.title3).bold()
                                .foregroundColor(.white)
                            
                            Text("Start the trip directly from your Apple Watch. Your phone will automatically become your dashboard.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(25)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        
                        // Quick State Section
                        Text("Today's Overview")
                            .font(.title3).bold()
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        
                        // HealthKit Sleep Risk Card
                        HStack {
                            Circle()
                                .fill(Color(hex: "5E5CE6"))
                                .frame(width: 50, height: 50)
                                .overlay(Image(systemName: "bed.double.fill").foregroundColor(.white))
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Sleep Readiness").font(.headline).foregroundColor(.white)
                                
                                HStack(alignment: .lastTextBaseline, spacing: 2) {
                                    Text(sleepManager.sleepText).font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                                }
                                Text("Total Rest").font(.caption).foregroundColor(.gray)
                            }
                            .padding(.leading, 10)
                            
                            Spacer()
                            
                            if sleepManager.sleepText != "Not Recorded" {
                                VStack(alignment: .trailing, spacing: 15) {
                                    HStack(spacing: 5) {
                                        Circle().fill(sleepManager.statusColor).frame(width: 8, height: 8)
                                        Text(sleepManager.statusText).font(.caption).bold().foregroundColor(.white)
                                    }
                                    Text(sleepManager.badgeText)
                                        .font(.caption2).bold()
                                        .foregroundColor(sleepManager.statusColor)
                                        .padding(.horizontal, 10).padding(.vertical, 4)
                                        .background(sleepManager.statusColor.opacity(0.2)).cornerRadius(5)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        
                        // Summary Navigation Card
                        NavigationLink(destination: SummaryView()) {
                            HStack {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Summary").font(.headline).foregroundColor(.white)
                                    
                                    if pastTrips.isEmpty && !connectivity.isDriving {
                                        Text("Not Recorded").font(.caption).foregroundColor(.gray.opacity(0.7))
                                    } else {
                                        HStack(spacing: 5) {
                                            Circle().fill(Color(hex: "FEB504")).frame(width: 8, height: 8)
                                            Text("Weekly View").font(.caption).foregroundColor(.gray)
                                        }
                                    }
                                }
                                Spacer()
                                
                                HStack(alignment: .bottom, spacing: 4) {
                                    let emptyHeights: [CGFloat] = [10, 15, 12, 20, 25, 18, 15, 10]
                                    ForEach(0..<8) { i in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(pastTrips.isEmpty && !connectivity.isDriving ? Color.gray.opacity(0.2) : (i == 6 ? Color(hex: "247FA6") : Color.gray.opacity(0.3)))
                                            .frame(width: 4, height: pastTrips.isEmpty && !connectivity.isDriving ? emptyHeights[i] : CGFloat.random(in: 10...30))
                                    }
                                }
                                .padding(.trailing, 10)
                                
                                HStack {
                                    Text("Today").font(.subheadline).foregroundColor(.white)
                                    Image(systemName: "arrow.right").font(.subheadline).foregroundColor(.white)
                                }
                            }
                            .padding(20)
                            .background(Color(red: 0.12, green: 0.12, blue: 0.13))
                            .cornerRadius(20)
                            .padding(.horizontal, 20)
                        }
                        
                        if connectivity.isDriving {
                            Button(action: {
                                connectivity.sendDriveStatus(isStarting: false)
                            }) {
                                Text("END THE DRIVE")
                                    .font(.headline).bold()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color(hex: "D20A0A"))
                                    .cornerRadius(30)
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                        }
                        
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showProfileEdit) {
                EditProfileView()
            }
            .onAppear {
                sleepManager.fetchSleepData()
            }
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

// MARK: - Sleep Data Manager
class SleepManager: ObservableObject {
    @Published var sleepText: String = "Not Recorded"
    @Published var statusText: String = "Unknown"
    @Published var statusColor: Color = .gray
    @Published var badgeText: String = "NO DATA"
    
    private let healthStore = HKHealthStore()
    
    func fetchSleepData() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard error == nil, let sleepSamples = samples as? [HKCategorySample] else { return }
            
            let asleepSamples = sleepSamples.filter {
                $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
            }
            
            let totalSleepInterval = asleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            let totalHours = totalSleepInterval / 3600.0
            
            DispatchQueue.main.async {
                if totalHours == 0 {
                    self.sleepText = "Not Recorded"
                    self.statusText = "Unknown"
                    self.statusColor = .gray
                    self.badgeText = "NO DATA"
                } else {
                    let h = Int(totalHours)
                    let m = Int((totalHours - Double(h)) * 60)
                    self.sleepText = "\(h)hr \(m)min"
                    
                    if totalHours >= 8 {
                        self.statusText = "Well Rested"
                        self.statusColor = Color(hex: "00D543")
                        self.badgeText = "SAFE"
                    } else if totalHours >= 5 {
                        self.statusText = "Moderate Risk"
                        self.statusColor = Color(hex: "FEB504")
                        self.badgeText = "MODERATE"
                    } else {
                        self.statusText = "High Risk"
                        self.statusColor = Color(hex: "D20A0A")
                        self.badgeText = "HIGH"
                    }
                }
            }
        }
        healthStore.execute(query)
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userGender") var userGender: String = "Not Specified"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "000000").edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .leading, spacing: 30) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Name").font(.headline).foregroundColor(.white)
                        TextField("Enter your name", text: $userName)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(15)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Gender").font(.headline).foregroundColor(.white)
                        HStack(spacing: 15) {
                            GenderButton(title: "Female", selected: $userGender)
                            GenderButton(title: "Male", selected: $userGender)
                        }
                    }
                    Spacer()
                }
                .padding(30)
                .padding(.top, 20)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(Color(hex: "247FA6"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Interactive Summary Screen
struct SummaryView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let days = ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"]
    @State private var selectedDay: String = "Fri"
    
    var body: some View {
        ZStack {
            Color(hex: "000000").edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left").font(.title2).foregroundColor(.white)
                        }
                        Text("Summary")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.leading, 10)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    VStack(spacing: 20) {
                        // 🚨 FIX: Reduced spacing, enforced single line, allowing scale down
                        HStack(spacing: 8) {
                            ForEach(days, id: \.self) { day in
                                Text(day)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .foregroundColor(selectedDay == day ? .white : .gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(selectedDay == day ? Color(hex: "D9D9D9").opacity(0.3) : Color.clear)
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        withAnimation { selectedDay = day }
                                    }
                            }
                        }
                        .padding(.top, 10)
                        
                        HStack(alignment: .bottom, spacing: 18) {
                            let heights: [CGFloat] = [50, 0, 60, 120, 90, 80, 40]
                            ForEach(0..<7) { i in
                                ChartBar(
                                    height: heights[i],
                                    color: selectedDay == days[i] ? Color(hex: "247FA6") : Color.gray.opacity(0.4)
                                )
                                .onTapGesture {
                                    withAnimation { selectedDay = days[i] }
                                }
                            }
                        }
                        .frame(height: 150)
                        .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.12, green: 0.12, blue: 0.13))
                    .cornerRadius(25)
                    .padding(.horizontal, 20)
                    
                    Text("Trips on \(selectedDay)")
                        .font(.title3).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 15) {
                        if selectedDay == "Sun" {
                            Text("No driving recorded on Sunday.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                        } else if selectedDay == "Tue" {
                            DailyTripRow(tripNum: "Trip 1", duration: "1hr 15m", highestStage: "Drowsy (Stage 2)", color: Color(hex: "FF8104"))
                            DailyTripRow(tripNum: "Trip 2", duration: "45m", highestStage: "Fully Alert", color: Color(hex: "00D543"))
                        } else {
                            DailyTripRow(tripNum: "Trip 1", duration: "30m", highestStage: "Fully Alert", color: Color(hex: "00D543"))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Text("Driving Focus Breakdown")
                        .font(.title3).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    VStack(spacing: 15) {
                        AlertLevelRow(color: Color(hex: "00D543"), title: "Fully Alert", time: "8hr 10m", percentage: "80%")
                        AlertLevelRow(color: Color(hex: "FEB504"), title: "Mild Fatigue", time: "1hr 5m", percentage: "12%")
                        AlertLevelRow(color: Color(hex: "FF8104"), title: "Drowsy", time: "30m", percentage: "6%")
                        AlertLevelRow(color: Color(hex: "D20A0A"), title: "Critical Risk", time: "15m", percentage: "2%")
                    }
                    .padding(.horizontal, 20)
                    
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
}

// Components for Summary
struct ChartBar: View {
    let height: CGFloat
    let color: Color
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: 8, height: max(height, 5))
    }
}

struct DailyTripRow: View {
    let tripNum: String; let duration: String; let highestStage: String; let color: Color
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tripNum).font(.headline).foregroundColor(.white)
                Text(duration).font(.subheadline).foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                // 🚨 FIX: Changed to "Max Risk Reached"
                Text("Max Risk Reached").font(.caption).foregroundColor(.gray)
                HStack(spacing: 5) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(highestStage).font(.subheadline).bold().foregroundColor(.white)
                }
            }
        }
        .padding(15)
        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
        .cornerRadius(15)
    }
}

struct AlertLevelRow: View {
    let color: Color; let title: String; let time: String; let percentage: String
    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundColor(.white)
                Text(time).font(.caption).foregroundColor(.gray)
            }
            .padding(.leading, 5)
            Spacer()
            Text(percentage)
                .font(.subheadline).bold()
                .foregroundColor(.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(Color(hex: "D9D9D9").opacity(0.3))
                .cornerRadius(15)
        }
        .padding(15)
        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
        .cornerRadius(15)
    }
}
