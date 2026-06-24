import SwiftUI
import Combine
import WatchKit

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
    @StateObject private var viewModel = WatchDriveViewModel()
    
    var body: some View {
        Group {
            if viewModel.isDriving {
                TabView {
                    AlertDialScreen(viewModel: viewModel)
                    WatchLiveDashboard(viewModel: viewModel)
                    WatchControlsScreen(viewModel: viewModel)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            } else {
                StartScreen(viewModel: viewModel)
            }
        }
    }
}

// MARK: - 1. The Start Screen
struct StartScreen: View {
    @ObservedObject var viewModel: WatchDriveViewModel
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image("bird")
                .resizable()
                .scaledToFill()
                .scaleEffect(1.05)
                .offset(x: -10, y: 50)
                .ignoresSafeArea()
            
            // The Start Button (Acting as the Eye)
            Button(action: {
                viewModel.startTripFromWatch()
            }) {
                ZStack {
                    Circle().fill(Color.black)
                    Text("Start")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 75, height: 75)
            .buttonStyle(PlainButtonStyle())
            .offset(x: -41, y: -10)
        }
    }
}

// MARK: - 2. The Alert Dial Screen
struct AlertDialScreen: View {
    @ObservedObject var viewModel: WatchDriveViewModel
    
    var stageColor: Color {
        if viewModel.currentScore >= 90 { return Color(hex: "D20A0A") }
        if viewModel.currentScore >= 70 { return Color(hex: "FF8104") }
        if viewModel.currentScore >= 40 { return Color(hex: "FEB504") }
        return Color(hex: "00D543")
    }
    
    var stageText: String {
        if viewModel.currentScore == -1 { return "Calibrating..." }
        if viewModel.currentScore >= 90 { return "SHAKE WRIST" }
        if viewModel.currentScore >= 70 { return "Unstable" }
        if viewModel.currentScore >= 40 { return "Losing Focus" }
        return "Stable"
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            let safeScore = max(0.0, min(100.0, Double(viewModel.currentScore)))
            let progress = safeScore / 100.0
            
            let arcWidth: CGFloat = 200
            
            ZStack {
                // The Colored Dome Background
                Circle()
                    .fill(stageColor)
                    .frame(width: 230, height: 230)
                
                // The Faded Background Track
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: arcWidth, height: arcWidth)
                
                // The Filled White Progress Track
                Circle()
                    .trim(from: 0.5, to: 0.5 + (0.5 * progress))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: arcWidth, height: arcWidth)
                
                // The Bird Dot
                BirdDot()
                    .offset(x: -(arcWidth / 2))
                    .rotationEffect(.degrees(180 * progress))
            }
            .offset(y: 85)
            
            // Stage Text
            VStack(spacing: 2) {
                Text(stageText)
                    .font(.system(size: viewModel.currentScore >= 90 ? 18 : 22, weight: .bold))
                    .foregroundColor(.white)
                
                if viewModel.currentScore >= 90 {
                    Text("to dismiss alarm")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .offset(y: 65)
        }
    }
}

// MARK: - The Bird Dot Component
struct BirdDot: View {
    var body: some View {
        ZStack {
            // Beak
            Path { p in
                p.move(to: CGPoint(x: 6, y: 18))
                p.addLine(to: CGPoint(x: 18, y: -4))
                p.addLine(to: CGPoint(x: 30, y: 18))
            }
            .fill(Color(hex: "FEB504"))
            
            // White Eye
            Circle()
                .fill(Color.white)
                .frame(width: 26, height: 26)
            
            // Black Pupil
            Circle()
                .fill(Color.black)
                .frame(width: 14, height: 14)
        }
        .frame(width: 36, height: 36)
    }
}

// MARK: - 3. The Live Telemetry Dashboard
struct WatchLiveDashboard: View {
    @ObservedObject var viewModel: WatchDriveViewModel
    
    // 🚨 ADDED: Connect to the master source of truth for the speed
    @StateObject private var connectivity = ConnectivityManager.shared
    
    var stageColor: Color {
        if viewModel.currentScore >= 90 { return Color(hex: "D20A0A") }
        if viewModel.currentScore >= 70 { return Color(hex: "FF8104") }
        if viewModel.currentScore >= 40 { return Color(hex: "FEB504") }
        return Color(hex: "00D543")
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Left Side: Metrics Stack
                VStack(alignment: .leading, spacing: 14) {
                    
                    // Heart Rate
                    VStack(alignment: .leading, spacing: -2) {
                        Text("heart rate")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "D20A0A"))
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("\(Int(viewModel.currentBPM))")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            Text("bpm")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Speed
                    VStack(alignment: .leading, spacing: -2) {
                        Text("speed")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "247FA6"))
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            // 🚨 FIXED: Now pulls live speed instead of hardcoded "0"
                            Text("\(connectivity.currentSpeedKMH)")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            // 🚨 FIXED: Updated unit label to km/h
                            Text("km/h")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Wrist Activity
                    VStack(alignment: .leading, spacing: 2) {
                        Text("wrist activity")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "00D543"))
                        Text(viewModel.isStill ? "Still" : "Active")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.leading, 10)
                
                Spacer()
                
                // Right Side: Risk Circle
                Circle()
                    .fill(stageColor)
                    .frame(width: 85, height: 85)
                    .overlay(
                        Text(viewModel.currentScore == -1 ? "--%" : "\(viewModel.currentScore)%")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .padding(.trailing, 10)
            }
        }
    }
}

// MARK: - 4. NEW: Watch Controls Screen
struct WatchControlsScreen: View {
    @ObservedObject var viewModel: WatchDriveViewModel
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Button(action: {
                    viewModel.endTripFromWatch()
                }) {
                    Text("End Drive")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: 48)
                        .background(Color(hex: "247FA6"))
                        .cornerRadius(24)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
            }
        }
    }
}
