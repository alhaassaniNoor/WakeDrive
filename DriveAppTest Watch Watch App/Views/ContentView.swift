import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WatchDriveViewModel()
    
    var riskColor: Color {
        if viewModel.currentScore >= 90 { return .red }
        if viewModel.currentScore >= 70 { return .orange }
        if viewModel.currentScore >= 40 { return .yellow }
        return .green
    }
    
    var body: some View {
        ZStack {
            if viewModel.isDriving {
                riskColor.edgesIgnoringSafeArea(.all)
                
                VStack {
                    if viewModel.currentScore >= 90 {
                        // 🚨 NEW SHAKE UI
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
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "steeringwheel").font(.title).foregroundColor(.blue)
                    Text("Ready").font(.headline)
                    Button(action: {
                        viewModel.startTripFromWatch()
                    }) {
                        Text("Start Drive Mode")
                            .font(.subheadline).bold().foregroundColor(.black).frame(maxWidth: .infinity)
                            .padding().background(Color.green).cornerRadius(12)
                    }.buttonStyle(PlainButtonStyle())
                }.padding()
            }
        }
    }
}
