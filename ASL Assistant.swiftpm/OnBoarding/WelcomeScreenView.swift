import SwiftUI

struct WelcomeScreenView: View {
    @State private var presentNextScreen = false
    @State private var isHandEmojiShowing = false
    @State private var isShowingStartButton = false
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appModel: AppModel
    @AppStorage("needsAppOnboarding") private var needsAppOnboarding: Bool = true
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                
                HStack { 
                    Text("Hello!")
                        .font(.largeTitle)
                        .foregroundLinearGradient(
                            colors: [.red, .blue, .green, .yellow], 
                            startPoint: .leading, 
                            endPoint: .trailing
                        )
                    
                    if isHandEmojiShowing {
                        Text("👋🏽")
                    }
                }
                .font(.largeTitle)
                .padding()
                .overlay {
                    ButtonGradient(type: .capsule)
                }
                .animation(.linear, value: isHandEmojiShowing)
                
                Text("Welcome to your personal **ASL AI Assistant** 🤖")
                    .font(.title)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button("Let's Begin") { 
                        presentNextScreen = true
                    }
                    .font(.headline)
                    .padding()
                    .frame(height: 50)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .containerShape(Capsule(style: .circular))
                    .overlay {
                        ButtonGradient(type: .capsule)
                    }
                    .offset(y: isHandEmojiShowing ? 10.0 : 100)
                    .animation(.linear, value: isHandEmojiShowing)
                }
                .padding([.bottom, .trailing], 20)
            }
            .padding()
            .onAppear(perform: {
                Task {
                    await delayAnimation()
                }
            })
            .navigationDestination(isPresented: $presentNextScreen) { 
                if needsAppOnboarding {
                    InformationView()
                        .environmentObject(appModel)
                        .navigationBarBackButtonHidden(true)
                } else { 
                    MainAppView()
                        .environmentObject(appModel)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
    
    func delayAnimation() async { 
        try? await Task.sleep(for: .seconds(1))
        isHandEmojiShowing = true
        try? await Task.sleep(for: .seconds(1))
        isShowingStartButton = true
    }
}

struct WelcomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreenView()
            .environmentObject(AppModel())
    }
}
