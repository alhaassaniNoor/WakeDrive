import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WatchDriveViewModel()
    
    // Smooth transition colors based on the score
    var riskColor: Color {
        if viewModel.currentScore >= 90 { return .red }
        if viewModel.currentScore >= 70 { return .orange }
        if viewModel.currentScore >= 40 { return .yellow }
        return .green
    }
    
    var body: some View {
        ZStack {
            // Full background color fills the whole watch
            if viewModel.isDriving {
                riskColor.edgesIgnoringSafeArea(.all)
                
                VStack {
                    if viewModel.currentScore >= 90 {
                        // EMERGENCY BUTTON
                        Button(action: {
                            viewModel.resetScoreManually()
                        }) {
                            VStack(spacing: 5) {
                                Image(systemName: "hand.tap.fill").font(.title)
                                Text("I'M AWAKE").font(.headline).fontWeight(.black)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                        
                    } else {
                        // NORMAL GLANCE SCREEN
                        Spacer()
                        Image(systemName: "car.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        
                        // Watch control to end the trip
                        Button(action: {
                            viewModel.endTripFromWatch()
                        }) {
                            Text("End Drive Mode")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 10)
                    }
                }
            } else {
                // STANDBY
                VStack(spacing: 15) {
                    Image(systemName: "steeringwheel")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("Ready")
                        .font(.headline)
                    
                    Button(action: {
                        viewModel.startTripFromWatch()
                    }) {
                        Text("Start Drive Mode")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
        }
    }
}
