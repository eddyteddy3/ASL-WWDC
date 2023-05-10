import SwiftUI

struct InformationView: View {
    @State private var presentFirstBubble = false
    @State private var presentNextScreen = false
    @State private var isShowingButtonTrailingButton = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appModel: AppModel
    @AppStorage("needsAppOnboarding") private var needsAppOnboarding: Bool = true
    
    @State private var isFirstViewShown = false
    @State private var isThirdViewShown = false
    @State private var isSecondViewShown = false
    
    private struct BubbleView: View { 
        var body: some View { 
            ZStack { 
                Image(systemName: "message.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60, alignment: .center)
                    .foregroundColor(.white)
                
                Text("🤔")
                    .font(.title)
            }
        }
    }
    
    func delayAnimation() async { 
        try? await Task.sleep(for: .seconds(2.0))
        isFirstViewShown = true
        isShowingButtonTrailingButton = true
    }
    
    func presentWithDelay() async { 
        try? await Task.sleep(for: .seconds(1))
        presentFirstBubble = true
    }
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                InfoCardView(
                    text: "How many children are born deaf to hearing parents?", 
                    imageName: "figure.2.and.child.holdinghands",
                    optionalText: "Do you know? 💡"
                )
                .overlay(alignment: .topTrailing) { 
                    BubbleView()
                        .offset(x: 30, y: -40)
                        .scaleEffect(presentFirstBubble ? 1 : 0, anchor: .center)
                        .animation(.easeInOut, value: presentFirstBubble)
                }
                .frame(height: 400)
                .frame(minHeight: isFirstViewShown ? 0 : proxy.size.height) 
                .frame(width: proxy.size.width)
                .onAppear {
                    Task { 
                        await presentWithDelay()
                    }
                }
                .task {
                    await delayAnimation()
                }
                .animation(.linear, value: isFirstViewShown)
                
                VStack(alignment: .center, spacing: 15) {
                    VStack(alignment: .center, spacing: 10) {
                        VStack {
                            Text("According to NIDCD")
                                .font(.title)
                            Text("_(National Institute on Deafness and other Communication Disorder)_")
                                .font(.caption)
                        }
                        
                        switch horizontalSizeClass { 
                        case .compact: 
                            VStack(spacing: 10) {
                                InfoCardView(
                                    text: "Approximately 3 in 1,000 babies are born with permanent hearing loss in the United States.¹",
                                    emojiPicture: "👶"
                                )
                                
                                InfoCardView(
                                    text: "Around 90% of which are born to hearing parents many of which may not know American Sign Language.²",
                                    emojiPicture: "🤟"
                                )
                            }
                        case .regular: 
                            HStack(alignment: .top, spacing: 10) {
                                InfoCardView(
                                    text: "Approximately 3 in 1,000 babies are born with permanent hearing loss in the United States.¹",
                                    emojiPicture: "👶"
                                )
                                
                                InfoCardView(
                                    text: "Around 90% of which are born to hearing parents many of which may not know American Sign Language.²",
                                    emojiPicture: "🤟"
                                )
                            }
                        default:
                            EmptyView()
                        }
                    }
                    
                    VStack(alignment: .center, spacing: 10) {
                        Text("Learning American Sign Language can be challenging³")
                            .font(.title)
                            .multilineTextAlignment(.center)
                        
                        switch horizontalSizeClass {
                        case .compact:
                            VStack(spacing: 10) {
                                InfoCardView(
                                    text: "It demands time and resources which parents usually don't have.",
                                    emojiPicture: "⏰"
                                )
                                
                                InfoCardView(
                                    text: "It requires constant practice.",
                                    emojiPicture: "📖"
                                )
                            }
                        case .regular:
                            HStack(spacing: 10) {
                                InfoCardView(
                                    text: "It demands time and resources which parents usually don't have.",
                                    emojiPicture: "⏰"
                                )
                                
                                InfoCardView(
                                    text: "It requires constant practice.",
                                    emojiPicture: "📖"
                                )
                            }
                        default:
                            EmptyView()
                        }
                    }
                }
                .padding(.bottom, 50)
                .opacity(isSecondViewShown ? 1 : 0)
                .animation(.easeIn, value: isSecondViewShown)
                
                VStack(alignment: .center, spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("So, how this App will help me? 🤔")
                            .font(.title)
                        
                        Text("This app will act as your ASL Assistant and Teacher.\nOkay but how? 😧")
                            .font(.title3)
                    }
                    
                    switch horizontalSizeClass {
                    case .compact:
                        VStack {
                            InfoCardView(
                                text: "When you are in early stage of learning, it will help you translate English sentence into ASL Letters", 
                                optionalText: "How Assist?"
                            )
                            
                            InfoCardView(
                                text: "When you will have time, it will help you learn ASL Letter by leveraging latest technologies provided by Apple ", 
                                optionalText: "How Teach?"
                            )
                        }
                    case .regular:
                        HStack(alignment: .top) {
                            InfoCardView(
                                text: "When you are in an early stage of learning ASL. It will help you translate English sentence into ASL Letters", 
                                optionalText: "How Assist?"
                            )
                            
                            InfoCardView(
                                text: "It will help you learn ASL Letter by leveraging latest technologies provided by Apple ", 
                                optionalText: "How Teach?"
                            )
                        }
                    default: 
                        EmptyView()
                    }
                }
                .opacity(isThirdViewShown ? 1 : 0)
                .animation(.easeIn, value: isThirdViewShown)
            }
            .scrollDisabled(!isSecondViewShown)
            .frame(maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, alignment: .leading) {
            HStack(alignment: .bottom) {
                if isSecondViewShown {
                    DisclosureGroup("Sources") {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("¹ _https://www.kdhe.ks.gov/DocumentCenter/View/8482/Facts-about-Pediatric-Hearing-Loss-PDF_")
                            Text("² _https://www.kdhe.ks.gov/DocumentCenter/View/8482/Facts-about-Pediatric-Hearing-Loss-PDF_")
                            Text("³ _https://www.jstor.org/stable/44392557_")
                        }
                        .font(.caption)
                    }
                    .fixedSize()
                    .padding()
                    .tint(.white)
                }
                
                if isShowingButtonTrailingButton {
                    Spacer()
                    
                    Button {
                        
                        if isFirstViewShown && !isSecondViewShown && !isThirdViewShown { 
                            isSecondViewShown = true
                        } else if isFirstViewShown && isSecondViewShown && !isThirdViewShown { 
                            isThirdViewShown = true
                        } else if isFirstViewShown && isSecondViewShown && isThirdViewShown { 
                            presentNextScreen = true
                            needsAppOnboarding = false
                        }
                        
                    } label: {
                        Text(isThirdViewShown ? "Let's Start Walkthrough" : "Next")
                            .padding()
                            .frame(height: 50)
                            .background(.yellow)
                            .foregroundColor(.black)
                            .cornerRadius(25)
                            .animation(.easeInOut, value: isThirdViewShown)
                    }
                    .padding([.bottom, .trailing], 20)
                    .background(.clear)
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.easeIn, value: isShowingButtonTrailingButton)
            .navigationDestination(isPresented: $presentNextScreen) {
                MainAppView()
                    .environmentObject(appModel)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .background(
            Rectangle()
                .fill(
                    Gradient(colors: [.blue.opacity(0.5), .teal.opacity(0.7)])
                )
        )
    }
}

struct InfoCardView: View {
    let text: String
    let imageName: String?
    let optionalText: String?
    let emojiPicture: String?
    
    init(
        text: String, 
        imageName: String? = nil, 
        optionalText: String? = nil, 
        emojiPicture: String? = nil
    ) {
        self.text = text
        self.imageName = imageName
        self.optionalText = optionalText
        self.emojiPicture = emojiPicture
    }
    
    var body: some View { 
        VStack(spacing: 10) { 
            if let emojiPicture { 
                Text(emojiPicture)
                    .font(.custom("", fixedSize: 70))
            }
            
            if let imageName { 
                Image(systemName: imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
            }
            
            if let optionalText {
                Text(optionalText)
                    .font(.largeTitle)
            }
            
            Text(text)
        }
        .adjustFrame()
        .padding()
        .background(
            Rectangle()
                .fill(
                    Gradient(colors: [.blue.opacity(0.5), .teal.opacity(0.7)])
                )
        )
        .cornerRadius(10)
    }
}

extension View {
    func adjustFrame() -> some View { 
        modifier(FrameAdjustment())
    }
}

struct FrameAdjustment: ViewModifier {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    func body(content: Content) -> some View {
        switch sizeClass { 
        case.compact:
            content
                .frame(width: 300)
        case .regular:
            content
                .frame(minWidth: 0, idealWidth: 200, maxWidth: 270, minHeight: 100, maxHeight: 250)
        default:
            content
        }
    }
}

struct InformationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            InformationView()
                .environmentObject(AppModel())
        }
    }
}
