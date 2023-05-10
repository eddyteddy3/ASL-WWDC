import SwiftUI

struct Word: Identifiable {
    var id = UUID()
    var image: String
    var letter: String
    var isMarked: Bool = false
    
    init(image: String, letter: String, isMarked: Bool = false) {
        self.image = image
        self.letter = letter
        self.isMarked = isMarked
    }
}

struct TextToASLView: View {
    @State private var text = ""
    @State private var isListShowing = true
    @State private var words: [Word] = []
    @State private var showClearButton = false
    
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 100, maximum: 170))]
    }
    
    var body: some View { 
        VStack(alignment: .leading) {

            Text("Convert your sentences to ASL Letter")
                .font(.custom("", size: 50))
                .foregroundLinearGradient(
                    colors: [.red, .teal], startPoint: .leading, endPoint: .trailing
                )
            
            Spacer()
            
            TextField("", text: $text)
                .placeholder(when: text.isEmpty, alignment: .leading) { 
                    Text("Enter your sentence here...")
                        .foregroundLinearGradient(
                            colors: [.red, .orange, .teal], 
                            startPoint: .leading, 
                            endPoint: .trailing
                        )
                        .opacity(0.3)
                }
                .padding()
                .overlay {
                    ButtonGradient(type: .rectangle)
                }
                
            if !text.isEmpty {
                HStack(spacing: 10) {
                    Button {
                        processSentence(text) 
                        isListShowing = true
                    } label: {
                        Text("Translate")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(.yellow)
                            .foregroundColor(.black)
                            .cornerRadius(25)
                    }
                    
                    if showClearButton { 
                        Button { 
                            isListShowing  = false   
                            showClearButton = false
                            text = ""
                        } label: {
                            Text("Clear All")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(25)
                        }
                    }
                }
                .animation(.easeIn, value: showClearButton)
            }
                
            if isListShowing {
                LazyVGrid(columns: columns) {
                    ForEach(words, id: \.id) { word in
                        ASLLetterView(text: word.letter, imageName: word.image)
                            .frame(width: 100, height: 100)
                    }
                    .onAppear(perform: {
                        print("appeared")
                        showClearButton = true
                    })
                }
                .padding(.top, 30)
            }
            
            Spacer()
        }
        .animation(.easeIn, value: text.isEmpty)
        .frame(maxHeight: .infinity)
        .padding()
        .background(
            Rectangle()
                .fill(
                    Gradient(
                        colors: [.blue.opacity(0.5), .teal.opacity(0.7)]
                    )
                )
        )
    }
    
    func processSentence(_ sentence: String) {
        let filteredResult = sentence.filter({ charater in
            charater.isLetter
        }) 
        words = filteredResult.map {
            Word(
                image: String($0).uppercased(), 
                letter: String($0).uppercased()
            )
        }
    }
}

struct ASLLetterView: View {
    let text: String
    let imageName: String?
    
    init(text: String, imageName: String? = nil) {
        self.text = text
        self.imageName = imageName
    } 
    
    var body: some View { 
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.cyan)
            
            VStack {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                }
                
                Text(text)
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
        }
    }
}

struct TextToASLView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TextToASLView()
        }
    }
}
