import SwiftUI
import Vision
import CoreML

final class AppModel: ObservableObject { 
    static let defaultMLModelName = "ASLMLModel.mlmodel"
    let camera = MLCamera()
    let predictionTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    @Published var currentMLModel: HandPoseMLModel? { 
        didSet { 
            guard let model = currentMLModel else { return }
            camera.mlDelegate?.updateMLModel(with: model)
        }
    }
    
    
    @Published var defaultMLModel: HandPoseMLModel?
    @Published var availableHandPoseMLModels = Set<HandPoseMLModel>()
    
    @Published var nodePoints: [CGPoint] = []
    @Published var isHandInFrame: Bool = false
    
    @Published var predictionProbability = PredictionMetrics()
    @Published var canPredict: Bool = false
    @Published var predictionLabel: String = ""
    @Published var isGatheringObservations: Bool = true
    
    @Published var viewfinderImage: Image?
    @Published var shouldPauseCamera: Bool = false {
        didSet {
            if shouldPauseCamera {
                camera.stop()
                isGatheringObservations = false
            } else {
                Task {
                    await camera.start()
                }
            }
        }
    }
    
    private var handposeMLModelURLs: [URL] {
        let urls = availableHandPoseMLModels.map { $0.url }
        return urls
    }
    
    init() {
        camera.mlDelegate = self
        setDefaultMLModel()
        Task {
            await handleCameraPreviews()
        }
    }
    
    func findExistingModels() async {
        let models = await HandPoseMLModel.findExistingModels(exclude: handposeMLModelURLs)
        for model in models {
            availableHandPoseMLModels.insert(model)
        }
    }
    
    func useLastTrainedModel() async {
        guard let lastTrained = await HandPoseMLModel.getLastTrainedModel() else {
            print("Couldn't find any recently trained ML models.")
            return
        }
        
        Task { @MainActor in
            self.currentMLModel = lastTrained
            print("Using last trained ML model in your RPS game: \(lastTrained.name)")
        }
    }
    
    private func handleCameraPreviews() async {
        let imageStream = camera.previewStream.map { $0.image }
        for await image in imageStream {
            Task { @MainActor in
                self.viewfinderImage = image
            }
        }
    }
    
    private func setDefaultMLModel()   {
        Task {
            guard let mlModel = await HandPoseMLModel.getDefaultMLModel() else { return }
            Task { @MainActor in
                self.defaultMLModel = mlModel
                self.currentMLModel = mlModel
                self.availableHandPoseMLModels.insert(mlModel)
            }
        }
    }
}

struct PredictionMetric: Identifiable {
    var id: String { category }
    let category: String
    let value: Double
}

extension PredictionMetric: Equatable {
    static func == (lhs: PredictionMetric, rhs: PredictionMetric) -> Bool {
        return lhs.id == rhs.id &&
        lhs.category == rhs.category &&
        lhs.value == rhs.value
    }
}

class PredictionMetrics: ObservableObject, Identifiable {
    var data = [PredictionMetric]()
    var dictionary: [String : Double] = [:]
    init() {}
    
    func getNewPredictions(from probabilities: [String: Double]) {
        var tempData = [PredictionMetric]()
        dictionary = probabilities
        
        _ = dictionary.map { (key: String, value: Double) in
            tempData.append(PredictionMetric(category: key, value: value))
        }
        data = tempData.sorted(by: { $0.category > $1.category })
    }
}

extension AppModel: MLDelegate {
    func updateMLModel(with model: NSObject) {
        guard let mlModel = model as? HandPoseMLModel else { return }
        camera.currentMLModel = mlModel
    }
    
    func gatherObservations(pixelBuffer: CVImageBuffer) async {
        guard canPredict else { return }
        
        Task { @MainActor in
            canPredict = false
        }
        
        guard let mlModel = camera.currentMLModel else {
            await resetPrediction()
            return
        }
        
        Task {
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
            do {
                try imageRequestHandler.perform([camera.handPoseRequest])
                guard/*#-code-walkthrough(ml.observation)*/ let observation = camera.handPoseRequest.results?.first /*#-code-walkthrough(ml.observation)*/else {
                    await resetPrediction()
                    return
                }
                
                Task { @MainActor in
                    isHandInFrame = true
                    isGatheringObservations = true
                }
                
                /*#-code-walkthrough(ml.multiarray)*/
                let poseMultiArray = try observation.keypointsMultiArray()
                /*#-code-walkthrough(ml.multiarray)*/
                
                let input = HandPoseInput(poses: poseMultiArray)
                guard let output = try mlModel.predict(poses: input) else { return }
                await updatePredictions(output: output)
                
                let jointPoints = try gatherHandPosePoints(from: observation)
                await updateNodes(points: jointPoints)
            } catch {
                print("Error performing request: \(error)")
            }
        }
        
    }
    
    private func gatherHandPosePoints(from observation: VNHumanHandPoseObservation) throws -> [CGPoint] {
        let allPointsDict = try observation.recognizedPoints(.all)
        var allPoints: [VNRecognizedPoint] = Array(allPointsDict.values)
        allPoints = allPoints.filter { $0.confidence > 0.5 }
        let points: [CGPoint] = allPoints.map { $0.location }
        return points
    }
    
    @MainActor
    private func updateNodes(points: [CGPoint]) {
        self.nodePoints = points
    }
    
    @MainActor
    private func updatePredictions(output: HandPoseOutput) {
        predictionLabel = output.label.capitalized
        predictionProbability.getNewPredictions(from: output.labelProbabilities)
    }
    
    @MainActor
    private func resetPrediction() {
        nodePoints = []
        predictionLabel = ""
        predictionProbability = PredictionMetrics()
        isHandInFrame = false
    }
}

fileprivate extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}
