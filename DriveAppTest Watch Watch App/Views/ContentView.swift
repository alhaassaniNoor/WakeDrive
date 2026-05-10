import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WatchDriveViewModel()
    
    var body: some View {
        Group {
            if viewModel.isDriving {
                TabView {
                    AlertColorScreen(viewModel: viewModel)
                    WatchLiveDashboard(viewModel: viewModel)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "steeringwheel").font(.title).foregroundColor(.blue)
                    Text("Ready").font(.headline)
                    Button(action: {
                        viewModel.startTripFromWatch()
                    }) {
                        Text("Start Drive Mode")
                            .font(.subheadline).bold().foregroundColor(.black).frame(maxWidth: .infinity)
                            .padding().background(Color.yellow).cornerRadius(12)
                    }.buttonStyle(PlainButtonStyle())
                }.padding()
            }
        }
    }
}

struct AlertColorScreen: View {
    @ObservedObject var viewModel: WatchDriveViewModel
    
    var riskColor: Color {
        if viewModel.currentScore >= 90 { return .red }
        if viewModel.currentScore >= 70 { return .orange }
        if viewModel.currentScore >= 40 { return .yellow }
        return .green
    }
    
    var body: some View {
        ZStack {
            riskColor.edgesIgnoringSafeArea(.all)
            VStack {
                if viewModel.currentScore >= 90 {
                    VStack(spacing: 8) {
                        Image(systemName: "waveform.path.ecg.rectangle.fill").font(.system(size: 40)).foregroundColor(.white)
                        Text("SHAKE WRIST").font(.headline).fontWeight(.black).foregroundColor(.white)
                        Text("to dismiss alarm").font(.caption).foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    Spacer()
                    Image(systemName: "car.fill").font(.system(size: 60)).foregroundColor(.white.opacity(0.9))
                    Spacer()
                }
            }
        }
    }
}

struct WatchLiveDashboard: View {
    @ObservedObject var viewModel: WatchDriveViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("LIVE TELEMETRY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(viewModel.currentScore == -1 ? .blue : .green)
                
                VStack(spacing: 5) {
                    if viewModel.currentScore == -1 {
                        Image(systemName: "waveform.path.ecg").font(.system(size: 24)).foregroundColor(.blue)
                        Text("CALIBRATING").font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(.blue)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(viewModel.currentScore >= 70 ? .red : (viewModel.currentScore >= 40 ? .orange : .green))
                        Text("\(viewModel.currentScore)")
                            .font(.system(size: 45, weight: .black, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                
                HStack(spacing: 8) {
                    WatchStatusBubble(title: "HR", value: "\(Int(viewModel.currentBPM))", unit: "BPM", icon: "heart.fill", color: .red)
                    WatchStatusBubble(title: "Motion", value: viewModel.isStill ? "Still" : "Active", unit: "Wrist", icon: viewModel.isStill ? "hand.raised.slash.fill" : "hand.wave.fill", color: .orange)
                }
            }
            .padding(.horizontal, 5)
        }
    }
}

struct WatchStatusBubble: View {
    var title: String; var value: String; var unit: String; var icon: String; var color: Color
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundColor(color)
            Text(value).font(.system(size: 16, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.5)
            VStack(spacing: 0) { Text(title).font(.system(size: 8, weight: .bold)); Text(unit).font(.system(size: 7)).foregroundColor(.secondary) }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
