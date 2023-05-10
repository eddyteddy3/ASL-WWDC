import SwiftUI
import Combine 

struct CameraView: View {
    @EnvironmentObject var appModel: AppModel
    
    @State private var shouldShowLastText = false    
    @State private var shouldShowVictoryText = false
    @State private var shouldShowVictoryTextAnimation = false
    @State private var count = 0
    @State private var shouldStopComparision = false
    @State private var isDebugMode = false
    
    let isMatchModeOn: Bool
    let letters: [String]
    
    @State var letterIndex = 0
    
    @State private var lastPrediction: (key: String, value: Double) = ("", 0)
    @State private var tempCount = false
    @State private var handInFrameCount = 0
    
    @State private var translatedLettersArray: [Word] = []
    
    @Binding private var isPracticeCompleted: Bool
    @State private var tempNavBool = false
    @State private var shouldShowSignImage = false
    @State private var shouldEnlargeCurrentInfoView = false
    @State private var showNodes = false
    
    @Binding private var pickerItem: PickerItem
    
    init() { 
        self.init(
            isMatchModeOn: false, 
            letters: [""], 
            isPracticeCompleted: .constant(false),
            pickerItem: .constant(.practice)
        )
    }
    
    init(
        letters: [String]
    ) {
        self.init(
            isMatchModeOn: true, 
            letters: letters, 
            isPracticeCompleted: .constant(false),
            pickerItem: .constant(.practice)
        )
    }
    
    init(
        isMatchModeOn: Bool,
        letters: [String], 
        isPracticeCompleted: Binding<Bool>,
        pickerItem: Binding<PickerItem>
    ) {
        self.isMatchModeOn = isMatchModeOn
        self.letters = letters
        self._isPracticeCompleted = isPracticeCompleted
        self._pickerItem = pickerItem
    }
    
    private var showWarning: Bool {
        appModel.viewfinderImage != nil && 
        appModel.currentMLModel != nil &&
        !appModel.isHandInFrame
    }
    
    private var previewImageSize: CGSize {
        appModel.camera.previewImageSize
    }
    
    private var handJointPoints: [CGPoint] {
        appModel.nodePoints
    }
    
    @State private var lettersObject: [Word] = []
    
    var body: some View {
        ViewfinderView(image: $appModel.viewfinderImage)
            .onChange(of: isMatchModeOn, perform: { value in
                if !value { 
                    lettersObject.removeAll()
                    letterIndex = 0
                }
            })
            .onChange(of: letters, perform: { value in
                letterIndex = 0
                lettersObject.removeAll()
                
                self.lettersObject = value.map { 
                    Word(
                        image: String($0), 
                        letter: String($0), 
                        isMarked: false
                    )
                }
            })
            .overlay(alignment: .center)  {
                if showNodes {
                    HandPoseNodeOverlay(
                        size: previewImageSize,
                        points: handJointPoints
                    )
                }
            }
            .overlay(alignment: .center) {
                if showWarning {
                    CameraFrameOverlay()
                        .animation(
                            .default, 
                            value: appModel.isHandInFrame
                        )
                }
            }
            .task {
                await appModel.camera.start()
            }
            .onReceive(appModel.predictionTimer) { _ in
                guard appModel.currentMLModel != nil, 
                        !shouldShowLastText else { return }
                guard count <= 10 else {
//                    appModel.camera.stop()
                    shouldStopComparision = true
                    return
                }
                appModel.canPredict = true
                if isMatchModeOn {
                    Task {
                        await compare(
                            predictionLabel: appModel.predictionLabel,
                            to: letters[letterIndex]
                        )
                    }
                }
            }
            .onDisappear {
                appModel.canPredict = false
            }
            .overlay(alignment: .topTrailing) {
                if isMatchModeOn {
                    VStack {
                        Text("Current")
                            .font(.largeTitle)
                        
                        LetterView(
                            letter: letters[letterIndex], 
                            imageName: letters[letterIndex]
                        )
                        .frame(width: 150, height: 150)
                        .background(.ultraThickMaterial)
                        .cornerRadius(10)
                        
                        Button {
                            //skip the word
                            Task { 
                                await appModel.camera.start()
                            }
                            
                            count = 0
                            guard letterIndex != (letters.count - 1) else {
                                
                                lettersObject.removeAll()
                                letterIndex = 0
                                
                                isPracticeCompleted = true
                                
                                return
                            }
                            
                            letterIndex += 1
                        } label: {
                            Text("Skip")
                                .padding()
                        }
                    }
                    .background(.ultraThickMaterial)
                    .cornerRadius(10)
                    .padding()
                }
            }
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading) {
                    VStack {
                        Toggle(isOn: $isDebugMode, label: {
                            Text("Enable Debug Mode")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.blue)
                        })
                        .fixedSize()
                        
                        if isDebugMode {
                            Toggle(isOn: $showNodes, label: {
                                Text("Show hand points")
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.blue)
                            })
                            .fixedSize()
                            
                            VStack {
                                Text("Letter you are making")
                                LetterView(letter: appModel.predictionLabel)
                                    .frame(width: 100, height: 100)
                                    .background(.ultraThickMaterial)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(10)
                    .onChange(of: isDebugMode) { value in
                        if !value { 
                            showNodes = false
                        }
                    }
                    
                    if isMatchModeOn { 
                        HStack {
                            Text(Image(systemName: "info.circle"))
                            Text("Try switching hands")
                        }
                        .padding()
                        .background(.ultraThickMaterial)
                        .cornerRadius(10)
                    }
                }
                .padding(10)
                .animation(.easeInOut, value: isDebugMode)
            }
            .overlay(alignment: .center) {
                if shouldShowVictoryText {
                    Text("Nice Job! 🎉")
                        .scaleEffect(shouldShowVictoryTextAnimation ? 3 : 0)
                }
            }
            .onReceive(appModel.predictionTimer) { _ in
                if pickerItem == .translation {
                    Task { 
                        await translateASL()
                    }
                }
            }
            .onChange(of: shouldStopComparision) { value in
                guard value, isMatchModeOn else { return }
                Task {
                    await changeLetterWithPause()
                }
            }
            .overlay(alignment: .center) {
                if shouldShowLastText {
                    HStack {
                        Text("Kudos you did it!")
                            .font(.largeTitle)
                            .foregroundLinearGradient(
                                colors: [.red, .blue, .green, .yellow], 
                                startPoint: .leading, 
                                endPoint: .trailing
                            )
                        Text("🥳")
                            .font(.largeTitle)
                    }
                }
            }
            .animation(.linear, value: shouldShowVictoryTextAnimation)
            .onChange(of: handInFrameCount) { value in
                print("Times, hand were in the frame", value)
            }
            .overlay(alignment: .bottomLeading) {
                if pickerItem == .translation {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            Text("Predicted Translation")
                                .font(.body)
                                .bold()
                                .padding(8)
                                .background(
                                    ButtonGradient(
                                        myGradient: Gradient(colors: [.red, .teal]), 
                                        type: .capsule
                                    )
                                )
                            
                            HStack(spacing: 20) {
                                Toggle(
                                    "Show Sign Images", 
                                    isOn: $shouldShowSignImage
                                )
                                .bold()
                                .fixedSize()
                                
                                if !translatedLettersArray.isEmpty {
                                    Button { 
                                        translatedLettersArray.removeAll()
                                    } label: {
                                        Text("Clear List")
                                            .frame(width: 100, height: 40)
                                            .background(.yellow)
                                            .foregroundColor(.black)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThickMaterial)
                        .cornerRadius(10)
                        
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(translatedLettersArray, id: \.id) { letter in
                                    LetterView(
                                        letter: letter.letter, 
                                        imageName: shouldShowSignImage ? letter.image : nil
                                    )
                                    .frame(
                                        width: shouldShowSignImage ? 100 : 50,
                                        height: shouldShowSignImage ? 100 : 50
                                    )
                                    .background(.ultraThickMaterial)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding()
                    .animation(.easeIn, value: translatedLettersArray.isEmpty)
                } else if pickerItem == .practice {
                    if !lettersObject.isEmpty { 
                        
                        VStack(alignment: .leading) {
                            VStack(alignment: .leading) {
                                Text("Status")
                                    .font(.body)
                                    .bold()
                                    .padding(8)
                                    .background(
                                        ButtonGradient(
                                            myGradient: Gradient(colors: [.red, .teal]), 
                                            type: .capsule
                                        )
                                    )
                                
                                HStack(spacing: 20) {
                                    Toggle(
                                        "Show Sign Images",
                                        isOn: $shouldShowSignImage
                                    )
                                    .bold()
                                    .fixedSize()
                                    
                                    if !translatedLettersArray.isEmpty {
                                        Button { 
                                            translatedLettersArray.removeAll()
                                        } label: {
                                            Text("Clear List")
                                                .frame(width: 100, height: 40)
                                                .background(.yellow)
                                                .foregroundColor(.black)
                                                .cornerRadius(10)
                                            
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(.ultraThickMaterial)
                            .cornerRadius(10)
                            
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(lettersObject, id: \.id) { letter in
                                        LetterView(
                                            letter: letter.letter, 
                                            imageName: shouldShowSignImage ? letter.image : nil
                                        )
                                        .frame(
                                            width: shouldShowSignImage ? 100 : 70,
                                            height: shouldShowSignImage ? 100 : 70
                                        )
                                        .background(.ultraThickMaterial)
                                        .cornerRadius(10)
                                        .overlay(alignment: .topTrailing) {
                                            if letter.isMarked {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        .animation(.linear.speed(3), value: letter.isMarked)
                                    }
                                }
                            }
                        }
                        .animation(.easeInOut.speed(2), value: shouldShowSignImage)
                        .padding()
                        .animation(.easeIn, value: letters.isEmpty)
                    }
                }
            }
            .animation(.linear.speed(2), value: pickerItem)
    }
    
    func compare(predictionLabel: String, to nameLetter: String) async {
        guard count <= 10 else { 
//            appModel.camera.stop()
            await changeLetterWithPause()
            shouldStopComparision = true
            return
        }
        
        if predictionLabel == nameLetter {
            count += 1
        }
    }
    
    func translateASL() async {
        if appModel.isHandInFrame {
            let probability = appModel
                .predictionProbability
                .dictionary
                .filter { $0.value > 0.90 }
                .first
            if let probability { 
                lastPrediction.key = probability.key
                lastPrediction.value = probability.value
                tempCount = true
            }
        } else if !appModel.isHandInFrame {
            if tempCount {
                translatedLettersArray.append(
                    Word(
                        image: lastPrediction.key, 
                        letter: lastPrediction.key
                    )
                )
                handInFrameCount += 1
                tempCount = false
            }
        }
    }
    
    func changeLetterWithPause() async { 
        try? await Task.sleep(for: .seconds(0.3))
        
        shouldStopComparision = false
        count = 0
        
        guard letterIndex != (letters.count - 1) else {
            lettersObject[letterIndex].isMarked = true
            
            lettersObject.removeAll()
            letterIndex = 0
            
            isPracticeCompleted = true
            
//            await appModel.camera.start()
            
            return
        }
        lettersObject[letterIndex].isMarked = true
        
        letterIndex += 1
//        await appModel.camera.start()
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CameraView(letters: ["L", "O", "L"])
                .environmentObject(AppModel())
        }
    }
}
