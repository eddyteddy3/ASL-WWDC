import SwiftUI

struct HandPoseNodeOverlay: View {
    var size: CGSize
    var points: [CGPoint] = []
    
    private let radius: CGFloat = 4
    
    private var imageAspectRatio: CGFloat {
        size.width / size.height
    }
    
    var body: some View {
        GeometryReader { geo in
            if points.isEmpty {
                EmptyView()
            } else {
                VStack {
                    Path {
                        path in
                        path.move(to: points[0])
                        for point in points {
                            let updatedPoint = updatePoint(point, viewSize: geo.frame(in: .local).size)
                            path.addEllipse(in: CGRect(x: updatedPoint.x - radius,
                                                       y: updatedPoint.y - radius,
                                                       width: radius * 2,
                                                       height: radius * 2))
                        }
                    }
                    .foregroundColor(.black)
                    .clipped()
                }
//                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            }
        }
    }
    
    private func updatePoint(_ point: CGPoint, viewSize: CGSize) -> CGPoint {
        let currentFrameAspectRatio = viewSize.width / viewSize.height
        if currentFrameAspectRatio > imageAspectRatio {
            return CGPoint(x: (point.x * viewSize.width),
                           y: ((1 - point.y) * scaledHeight(viewSize)) - yOffset(viewSize))
        }
        
        return CGPoint(x: (point.x * scaledWidth(viewSize)) - xOffset(viewSize),
                       y: (1 - point.y) * viewSize.height)
    }
    
    private func scaledWidth(_ viewSize: CGSize) -> CGFloat {
        return imageAspectRatio * viewSize.height
    }
    
    private func scaledHeight(_ viewSize: CGSize) -> CGFloat {
        return (1 / imageAspectRatio) * viewSize.width
    }
    
    private func xOffset(_ viewSize: CGSize) -> CGFloat {
        return (scaledWidth(viewSize) - viewSize.width) / 2
    }
    
    private func yOffset(_ viewSize: CGSize) -> CGFloat {
        return (scaledHeight(viewSize) - viewSize.height) / 2
    }
}
