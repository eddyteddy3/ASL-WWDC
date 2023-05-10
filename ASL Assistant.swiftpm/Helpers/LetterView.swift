import SwiftUI

struct LetterView: View { 
    private let letter: String
    private let imageName: String?
    
    init(letter: String, imageName: String? = nil) {
        self.letter = letter
        self.imageName = imageName
    }
    
    var body: some View {
        VStack {
            if let imageName { 
                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            
            Text(letter)
                .font(.largeTitle)
        }
    }
}
