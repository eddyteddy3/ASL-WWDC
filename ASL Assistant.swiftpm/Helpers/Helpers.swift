import SwiftUI

extension View {
    func isHidden(_ flag: Bool = false) -> some View { 
        modifier(HiddenModifier(isHidden: flag))
    }
}

struct HiddenModifier: ViewModifier {
    private var isHidden: Bool
    
    init(isHidden: Bool = false) {
        self.isHidden = isHidden
    }
    
    func body(content: Content) -> some View {
        switch isHidden {
        case false:
            content
        case true:
            content
                .hidden()
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
            
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}

struct ButtonGradient: View{
    enum `Type` { 
        case capsule
        case rectangle
    }
    
    var type: `Type`
    var myGradient = Gradient(
        colors: [
            Color(.yellow),
            Color(.systemPurple)
        ]
    )
    
    init(
        myGradient: Gradient = Gradient(
            colors: [
                Color(.systemTeal),
                Color(.systemPurple)
            ]
        ),
        type: `Type`
    ) {
        self.myGradient = myGradient
        self.type = type
    }
    
    var body: some View {
        switch type { 
        case .capsule:
            Capsule()
                .stroke(
                    LinearGradient(
                        gradient: myGradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 5
                )
        case .rectangle:
            Rectangle()
                .stroke(
                    LinearGradient(
                        gradient: myGradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 5
                )
        }
    }
}

extension View {
    public func foregroundLinearGradient(
        colors: [Color], 
        startPoint: UnitPoint, 
        endPoint: UnitPoint) -> some View 
    {
        self.overlay {
            
            LinearGradient(
                colors: colors,
                startPoint: startPoint,
                endPoint: endPoint
            )
            .mask(
                self
                
            )
        }
    }
}
