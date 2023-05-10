import SwiftUI

struct ViewfinderView: View {
    @Binding var image: Image?
    
    var body: some View {
        GeometryReader { geometry in
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .contentShape(Rectangle())
                    .zIndex(0)
            } else {
                ZStack {
                    ProgressView()
                        .position(
                            x: geometry.frame(in: .local).midX,
                            y: geometry.frame(in: .local).midY
                        )
                }
                .zIndex(1)
            }
        }
    }
}
