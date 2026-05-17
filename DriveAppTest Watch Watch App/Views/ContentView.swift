import SwiftUI

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
            // 🚨 NUDGED UP AGAIN: Changed y from 0 to -10
            .offset(x: -38, y: -10)
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
    
    var stageColor: Color {
        if viewModel.currentScore >= 90 { return Color(hex: "D20A0A") }
        if viewModel.currentScore >= 70 { return Color(hex: "FF8104") }
        if viewModel.currentScore >= 40 { return Color(hex: "FEB504") }
        return Color(hex: "00D543")
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(stageColor)
                        .frame(width: 90, height: 90)
                    
                    if viewModel.currentScore == -1 {
                        Text("--%")
                            .font(.title).bold()
                            .foregroundColor(.white)
                    } else {
                        Text("\(viewModel.currentScore)%")
                            .font(.title).bold()
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 10)
                
                // Telemetry Stats
                HStack(spacing: 25) {
                    VStack(spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 1) {
                            Text("\(Int(viewModel.currentBPM))").font(.title3).bold().foregroundColor(.white)
                            Text("bpm").font(.system(size: 10)).foregroundColor(.gray)
                        }
                        Text("Heart Rate").font(.system(size: 9, weight: .bold)).foregroundColor(Color(hex: "D20A0A"))
                    }
                    
                    VStack(spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 1) {
                            Text("0").font(.title3).bold().foregroundColor(.white)
                            Text("km").font(.system(size: 10)).foregroundColor(.gray)
                        }
                        Text("Speed").font(.system(size: 9, weight: .bold)).foregroundColor(Color(hex: "247FA6"))
                    }
                }
                
                // Wrist Activity
                VStack(spacing: 2) {
                    Text(viewModel.isStill ? "Still" : "Active").font(.system(size: 14)).foregroundColor(.white)
                    Text("Wrist Activity").font(.system(size: 10, weight: .bold)).foregroundColor(Color(hex: "00D543"))
                }
                
                Spacer()
            }
        }
    }
}
