import SwiftUI

extension Color {
    static var strokeColor: Color { white.opacity(0.5) }
    static var translucentBlack: Color { black.opacity(0.5) }
    static var accent: Color { Color.indigo }
    static var labelAccent: Color { Color(red: 0.224, green: 0.0, blue: 0.263) }
}

struct CameraFrameOverlay: View {
    @ScaledMetric private var cornerRadius: CGFloat = 15
    @ScaledMetric private var padding: CGFloat = 100
    @ScaledMetric private var lineWidth: CGFloat = 4.0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                .trim(from: 0.05, to: 0.2)
                .stroke(Color.strokeColor, lineWidth: lineWidth)
            
            RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                .trim(from: 0.3, to: 0.45)
                .stroke(Color.strokeColor, lineWidth: lineWidth)
            
            RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                .trim(from: 0.55, to: 0.7)
                .stroke(Color.strokeColor, lineWidth: lineWidth)
            
            RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                .trim(from: 0.8, to: 0.95)
                .stroke(Color.strokeColor, lineWidth: lineWidth)
        }
        .aspectRatio(1.0, contentMode: .fit)
        .padding(padding)
        .overlay(alignment: .top) {
            warningView()
                .padding()
        }
    }
    
    private func warningView() -> some View {
        Text("Place hand in frame")
            .font(.caption)
            .padding(10)
            .foregroundColor(.white)
            .background(Color.black.opacity(0.4))
            .cornerRadius(5.0)
    }
}
