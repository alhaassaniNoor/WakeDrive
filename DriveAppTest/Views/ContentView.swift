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
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @StateObject private var connectivity = ConnectivityManager.shared
    @StateObject private var permissions = PermissionsViewModel()
    
    var body: some View {
        Group {
            if permissions.isDenied {
                PermissionsDeniedView()
            } else if !hasCompletedOnboarding {
                MasterOnboardingView(hasCompleted: $hasCompletedOnboarding, permissions: permissions)
            } else if !connectivity.isWatchAppInstalled {
                WatchSetupView()
            } else {
                HomeView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Hard Stop Permissions View
struct PermissionsDeniedView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 30) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "FEB504"))
                
                Text("Access Required")
                    .font(.title).bold()
                    .foregroundColor(.white)
                
                Text("Copirrot requires Location and Health access to monitor driving safety and detect drowsiness in real-time. We cannot protect you without these permissions.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Open Settings to Allow")
                        .font(.headline).bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "247FA6"))
                        .cornerRadius(30)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
        }
    }
}

// MARK: - Onboarding Flow
struct MasterOnboardingView: View {
    @Binding var hasCompleted: Bool
    @ObservedObject var permissions: PermissionsViewModel
    @State private var step = 1
    @AppStorage("userName") var userName: String = ""
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
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
                        Text("Welcome to\nCopirrot")
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
                        
                        Text("We want to know your name to personalize your experience.")
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
                        
                        Spacer()
                        
                        Button(action: {
                            hasCompleted = true
                        }) {
                            Text("Finish")
                                .font(.headline).bold()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(userName.isEmpty ? Color.gray : Color(hex: "247FA6"))
                                .cornerRadius(30)
                        }
                        .disabled(userName.isEmpty)
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

// MARK: - Watch Setup
struct WatchSetupView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 40) {
                Spacer()
                Image(systemName: "applewatch.and.arrow.forward")
                    .font(.system(size: 100))
                    .foregroundColor(Color(hex: "FEB504"))
                Text("Connect Apple Watch")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                Text("Copirrot needs the Apple Watch app to monitor heart rate and arm movement.")
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
    @StateObject private var sleepManager = SleepManager()
    @State private var showProfileEdit = false
    @State private var showInfoSheet = false
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.date, order: .reverse) private var pastTrips: [Trip]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // Header
                        HStack(spacing: 15) {
                            Text("Hello \(userName.isEmpty ? "Driver" : userName),")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            
                            Button(action: { showInfoSheet = true }) {
                                Image(systemName: "info.circle")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                            
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
                            
                            Text("Start the trip directly from your Apple Watch.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(25)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "1C1C1E"))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "247FA6"), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 20)
                        
                        Text("Today's Overview")
                            .font(.title3).bold()
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        
                        // Sleep Card
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .center) {
                                Image(systemName: "bed.double.fill")
                                    .foregroundColor(Color(hex: "5E5CE6"))
                                    .font(.system(size: 15, weight: .medium))
                                
                                Text("Sleep")
                                    .foregroundColor(Color(hex: "5E5CE6"))
                                    .font(.system(size: 15, weight: .medium))
                                
                                Spacer()
                                
                                if sleepManager.hasData {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(sleepManager.statusColor)
                                            .frame(width: 8, height: 8)
                                            .overlay(Circle().stroke(Color.black.opacity(0.4), lineWidth: 1.5))
                                        Text(sleepManager.badgeText)
                                            .font(.caption).bold()
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "2C2C2E"))
                                    .clipShape(Capsule())
                                }
                            }
                            
                            Text("Time Asleep")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                            
                            if sleepManager.hasData {
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text("\(sleepManager.sleepHours)")
                                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("hr")
                                        .font(.body)
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 4)
                                    
                                    Text("\(sleepManager.sleepMinutes)")
                                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("min")
                                        .font(.body)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Text("No data")
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                        }
                        .padding(20)
                        .background(Color(hex: "1C1C1E"))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        
                        // Summary Navigation Card
                        NavigationLink(destination: SummaryView()) {
                            HStack {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Weekly Summary").font(.headline).foregroundColor(.white)
                                    Text("\(pastTrips.count) Trips Recorded").font(.subheadline).foregroundColor(.gray)
                                }
                                Spacer()
                                HStack {
                                    Text("View All").font(.subheadline).foregroundColor(Color(hex: "247FA6"))
                                    Image(systemName: "arrow.right").font(.subheadline).foregroundColor(Color(hex: "247FA6"))
                                }
                            }
                            .padding(20)
                            .background(Color(hex: "1C1C1E"))
                            .cornerRadius(20)
                            .padding(.horizontal, 20)
                        }
                        
                        // Blue End Trip Button
                        if connectivity.isDriving {
                            Button(action: {
                                connectivity.sendDriveStatus(isStarting: false)
                            }) {
                                Text("END THE DRIVE")
                                    .font(.headline).bold()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color(hex: "247FA6"))
                                    .cornerRadius(30)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showProfileEdit) { EditProfileView() }
            .sheet(isPresented: $showInfoSheet) { InfoSheetView() }
            .onAppear { sleepManager.fetchSleepData() }
            .onChange(of: connectivity.newlyCompletedTripData) { oldValue, newValue in
                if let data = newValue {
                    let newTrip = Trip(
                        date: data.date,
                        duration: data.duration,
                        avgSpeed: data.speed,
                        avgHR: data.hr,
                        avgRiskScore: data.avgRiskScore,
                        hadSleepWarning: data.warning
                    )
                    modelContext.insert(newTrip)
                    connectivity.newlyCompletedTripData = nil
                }
            }
        }
    }
}

// MARK: - REAL Sleep Data Manager
class SleepManager: ObservableObject {
    @Published var hasData: Bool = false
    @Published var sleepHours: Int = 0
    @Published var sleepMinutes: Int = 0
    @Published var statusColor: Color = .gray
    @Published var badgeText: String = ""
    
    private let healthStore = HKHealthStore()
    
    func fetchSleepData() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
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
                if totalHours <= 0 {
                    self.hasData = false
                    self.statusColor = Color.gray.opacity(0.3)
                    self.badgeText = ""
                } else {
                    self.hasData = true
                    self.sleepHours = Int(totalHours)
                    self.sleepMinutes = Int((totalHours - Double(self.sleepHours)) * 60)
                    
                    if totalHours >= 6 {
                        self.statusColor = Color(hex: "00D543") // Green
                        self.badgeText = "SAFE"
                    } else if totalHours >= 4 {
                        self.statusColor = Color(hex: "FEB504") // Yellow
                        self.badgeText = "MODERATE RISK"
                    } else {
                        self.statusColor = Color(hex: "D20A0A") // Red
                        self.badgeText = "HIGH RISK"
                    }
                }
            }
        }
        healthStore.execute(query)
    }
}

// MARK: - Edit Profile
struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("userName") var userName: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 30) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Name").font(.headline).foregroundColor(.white)
                        TextField("Enter your name", text: $userName)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(15)
                            .foregroundColor(.white)
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

// MARK: - Summary Screen
struct SummaryView: View {
    @Environment(\.presentationMode) var presentationMode
    @Query(sort: \Trip.date, order: .reverse) private var pastTrips: [Trip]
    
    let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    @State private var selectedDay: String = ""
    @State private var riskScoreOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left").font(.title2).foregroundColor(.white)
                        }
                        Text("Weekly Summary")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.leading, 10)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    VStack(spacing: 25) {
                        
                        // Days Segment Switcher Bar
                        HStack(spacing: 4) {
                            ForEach(days, id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 13, weight: selectedDay == day ? .semibold : .regular))
                                    .foregroundColor(selectedDay == day ? .white : .gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(selectedDay == day ? Color.white.opacity(0.15) : Color.clear)
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        triggerFadeAnimation(for: day)
                                    }
                            }
                        }
                        .padding(6)
                        .background(Color(hex: "2C2C2E").opacity(0.6))
                        .cornerRadius(14)
                        .padding(.horizontal, 15)
                        .padding(.top, 15)
                        
                        // Chart Container
                        ZStack(alignment: .top) {
                            
                            // Floating tooltip overlay text
                            Text("Avg Risk Score = \(getDayAvgRisk(for: selectedDay))%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                                .offset(y: -25)
                                .opacity(riskScoreOpacity)
                                .zIndex(1)
                            
                            // The Bars Layout Loop
                            HStack(alignment: .bottom, spacing: 0) {
                                ForEach(days, id: \.self) { day in
                                    VStack {
                                        Spacer()
                                        Capsule()
                                            .fill(selectedDay == day ? Color(hex: "247FA6") : Color(hex: "3A3A3C"))
                                            .frame(
                                                width: getChartHeight(for: day) == 4 ? 6 : 10,
                                                height: getChartHeight(for: day)
                                            )
                                    }
                                    .frame(maxWidth: .infinity)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        triggerFadeAnimation(for: day)
                                    }
                                }
                            }
                            .frame(height: 140)
                            .padding(.horizontal, 10)
                        }
                        .padding(.bottom, 15)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "1C1C1E"))
                    .cornerRadius(25)
                    .padding(.horizontal, 20)
                    
                    Text("Trips")
                        .font(.title3).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    // Real Trips List for Selected Day
                    VStack(spacing: 15) {
                        let dailyTrips = getTrips(for: selectedDay)
                        
                        if dailyTrips.isEmpty {
                            Text("No driving recorded on \(selectedDay).")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                        } else {
                            ForEach(Array(dailyTrips.enumerated()), id: \.element.id) { index, trip in
                                DailyTripRow(
                                    tripNum: "Trip \(dailyTrips.count - index)",
                                    duration: trip.duration,
                                    avgHR: trip.avgHR,
                                    avgSpeed: trip.avgSpeed,
                                    avgRiskScore: trip.avgRiskScore
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            selectedDay = formatter.string(from: Date())
        }
    }
    
    // MARK: - Logic Helpers
    private func triggerFadeAnimation(for day: String) {
        withAnimation { selectedDay = day }
        withAnimation(.easeIn(duration: 0.2)) { riskScoreOpacity = 1.0 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if selectedDay == day {
                withAnimation(.easeOut(duration: 0.3)) { riskScoreOpacity = 0.0 }
            }
        }
    }
    
    private func getTrips(for dayString: String) -> [Trip] {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        
        return pastTrips.filter { trip in
            if let date = df.date(from: trip.date) {
                return dayFormatter.string(from: date) == dayString
            }
            return false
        }
    }
    
    private func getDayAvgRisk(for dayString: String) -> Int {
        let trips = getTrips(for: dayString)
        if trips.isEmpty { return 0 }
        let totalRisk = trips.reduce(0) { $0 + $1.avgRiskScore }
        return totalRisk / trips.count
    }
    
    private func getChartHeight(for dayString: String) -> CGFloat {
        let trips = getTrips(for: dayString)
        if trips.isEmpty { return 4 }
        let avgRisk = getDayAvgRisk(for: dayString)
        if avgRisk <= 0 { return 4 }
        
        return 4 + (CGFloat(avgRisk) / 100.0 * 130)
    }
}

// MARK: - Trip Row
struct DailyTripRow: View {
    let tripNum: String
    let duration: String
    let avgHR: Int
    let avgSpeed: Int
    let avgRiskScore: Int
    
    var riskData: (title: String, color: Color) {
        switch avgRiskScore {
        case ...39: return ("Stable", Color(hex: "00D543"))
        case 40...69: return ("Losing Focus", Color(hex: "FEB504"))
        case 70...89: return ("Unstable", Color(hex: "FF8104"))
        default: return ("High Risk", Color(hex: "D20A0A"))
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(tripNum).font(.headline).foregroundColor(.white)
                Spacer()
                Text(duration).font(.subheadline).foregroundColor(.gray)
            }
            
            HStack(spacing: 20) {
                // 🚨 THE FIX: Failsafe logic for missing HR data
                HStack(spacing: 4) {
                    if avgHR == 0 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(hex: "FEB504"))
                            .font(.caption)
                        Text("HR Data Missing")
                            .font(.caption)
                            .foregroundColor(Color(hex: "FEB504"))
                    } else {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color(hex: "D20A0A"))
                            .font(.caption)
                        Text("\(avgHR) bpm avg")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "speedometer").foregroundColor(Color(hex: "247FA6")).font(.caption)
                    Text("\(avgSpeed) km/h avg").font(.caption).foregroundColor(.gray)
                }
                Spacer()
            }
            
            HStack {
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(riskData.color)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color.black.opacity(0.4), lineWidth: 1.5))
                    Text(riskData.title).font(.caption).bold().foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: "2C2C2E"))
                .clipShape(Capsule())
            }
        }
        .padding(15)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(15)
    }
}

// MARK: - How It Works (Info Sheet)
struct InfoSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("How Copirrot Protects You")
                            .font(.title2).bold()
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                        
                        StageInfoRow(
                            color: Color(hex: "00D543"),
                            title: "Stable",
                            score: "Score: 0 - 39",
                            desc: "System is quietly monitoring your vitals in the background. No alerts."
                        )
                        
                        StageInfoRow(
                            color: Color(hex: "FEB504"),
                            title: "Losing Focus",
                            score: "Score: 40 - 69",
                            desc: "Apple Watch vibrates gently for 15 seconds to check your responsiveness and encourage movement."
                        )
                        
                        StageInfoRow(
                            color: Color(hex: "FF8104"),
                            title: "Unstable",
                            score: "Score: 70 - 89",
                            desc: "Apple Watch vibrates for 20 seconds. If you remain still, your iPhone's audio system will wake up and speak a warning to fix your posture."
                        )
                        
                        StageInfoRow(
                            color: Color(hex: "D20A0A"),
                            title: "High Risk",
                            score: "Score: 90 - 100",
                            desc: "Continuous loop: 25 seconds of heavy vibration followed by an urgent voice command to pull over. This locks the system and can ONLY be dismissed by vigorously shaking your wrist, dropping your risk score by 50 points."
                        )
                    }
                    .padding(25)
                }
            }
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

struct StageInfoRow: View {
    let color: Color
    let title: String
    let score: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.black.opacity(0.4), lineWidth: 1.5))
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title).font(.headline).bold().foregroundColor(.white)
                    Spacer()
                    Text(score).font(.caption).bold().foregroundColor(color)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(color.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(15)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(15)
    }
}
