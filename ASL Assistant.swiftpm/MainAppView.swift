import SwiftUI
import Combine

enum PickerItem {
    case practice
    case translation
}

struct MainAppView: View {
    @EnvironmentObject var appModel: AppModel

    @State private var practiceText = ""
    @State private var letters: [String] = []
    
    @State private var translatedLettersArray: [Word] = []
    
    @State private var lastPrediction: (key: String, value: Double) = ("", 0)
    
    @State private var handInFrameCount = 0
    
    @State private var pickerSelection: PickerItem = .practice

    @State private var startPractice = false
    @State private var isPracticeCompleted = false
    @State private var tempCount = false
    @State private var shouldShowSignImage = false
    
    @FocusState private var isKeyboardHidden: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Convert your ASL Actions to Letters")
                .font(.custom("", size: 50))
                .foregroundLinearGradient(
                    colors: [.yellow, .teal], 
                    startPoint: .leading, 
                    endPoint: .trailing
                )
                .padding()
            
            
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 10, content: {
                    Text("Mode")
                        .font(.title2)
                    Picker("", selection: $pickerSelection) { 
                        Text("Practice")
                            .tag(PickerItem.practice)
                        Text("Translation (Bonus) ")
                            .tag(PickerItem.translation)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                })
                
                if pickerSelection == .practice {
                    TextField("", text: $practiceText)
                        .placeholder(when: practiceText.isEmpty, alignment: .leading) { 
                            Text("Enter a word here to translate into ASL...")
                                .font(.title2)
                                .foregroundLinearGradient(
                                    colors: [.red, .orange, .teal], 
                                    startPoint: .leading, 
                                    endPoint: .trailing
                                )
                                .opacity(0.2)
                        }
                        .padding(.top, 10)
                        .focused($isKeyboardHidden, equals: true)
                    
                    if !practiceText.isEmpty { 
                        HStack {
                            Button {
                                processSentence(practiceText)
                                startPractice = true
                                isKeyboardHidden = false
                            } label: {
                                Text("Translate")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(.yellow)
                                    .foregroundColor(.black)
                                    .cornerRadius(10)
                            }
                            
                            if startPractice {
                                Button {
                                    startPractice = false
                                    practiceText = ""
                                } label: {
                                    Text("Reset")
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(.yellow)
                                        .foregroundColor(.black)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .animation(.easeIn, value: startPractice)
                    }
                }
            }
            .padding()
            .zIndex(1)
            
            CameraView(
                isMatchModeOn: startPractice, 
                letters: letters, 
                isPracticeCompleted: $isPracticeCompleted,
                pickerItem: $pickerSelection
            )
            .environmentObject(appModel)
            .onDisappear { 
                appModel.camera.stop()
                appModel.camera.isPreviewPaused = true
                appModel.canPredict = false
                appModel.isGatheringObservations = false
                appModel.shouldPauseCamera = true
            }
            .onAppear { 
                Task { 
                    await appModel.camera.start()
                    appModel.camera.isPreviewPaused = false
                    appModel.canPredict = true
                    appModel.isGatheringObservations = true
                    appModel.shouldPauseCamera = false
                }
            }
            .cornerRadius(10)
        }
        .animation(.linear.speed(2), value: practiceText.isEmpty)
        .onChange(of: isPracticeCompleted) { value in
            practiceText = ""
            startPractice = false
            isPracticeCompleted = false
            Task { 
                await appModel.camera.start()
                appModel.camera.isPreviewPaused = false
                appModel.canPredict = true
                appModel.isGatheringObservations = true
                appModel.shouldPauseCamera = false
            }
        }
        .background(
            Rectangle()
                .fill(
                    Gradient(colors: [.blue.opacity(0.5), .teal.opacity(0.7)])
                )
        )
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
    
    func processSentence(_ sentence: String) {
        let filteredResult = sentence.filter({ charater in
            charater.isLetter
        }) 
        letters = filteredResult.map { String($0).uppercased() }
    }
}

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
            .environmentObject(AppModel())
    }
}
