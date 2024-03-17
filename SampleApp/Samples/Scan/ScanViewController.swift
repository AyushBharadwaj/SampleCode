//
//  ScanViewController.swift
//  SampleApp
//
//  Created by Ayush on 15/03/24.
//

import RealityKit
import ARKit

class LabelScene: SKScene {
    let label = SKLabelNode()
    var onTapped: (() -> Void)? = nil

    override public init(size: CGSize){
        super.init(size: size)

        self.scaleMode = SKSceneScaleMode.resizeFill

        label.fontSize = 65
        label.fontColor = .blue
        label.position = CGPoint(x:frame.midX, y: label.frame.size.height + 50)

        self.addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not been implemented")
    }
    
    convenience init(size: CGSize, onTapped: @escaping () -> Void) {
        self.init(size: size)
        self.onTapped = onTapped
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let onTapped = self.onTapped {
            onTapped()
        }
    }
    
    func setText(text: String) {
        label.text = text
    }
}
class ScanViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    enum ScanMode {
        case noneed
        case doing
        case done
    }
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var sceneBtn: UIButton!
    @IBOutlet weak var exportBtn: UIButton!
    var scanMode: ScanMode = .noneed
    var originalSource: Any? = nil
    var path :URL?
    lazy var label = LabelScene(size:sceneView.bounds.size) { [weak self] in
        self?.rotateMode()
    }

    override func viewDidLoad() {
        func setARViewOptions() {
            sceneView.scene = SCNScene()
        }
        func buildConfigure() -> ARWorldTrackingConfiguration {
            let configuration = ARWorldTrackingConfiguration()

            configuration.environmentTexturing = .automatic
            configuration.sceneReconstruction = .mesh
            if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
               configuration.frameSemantics = .sceneDepth
            }

            return configuration
        }
        func setControls() {
            label.setText(text: "Scan")
            sceneView.overlaySKScene = label
        }
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session.delegate = self
        setARViewOptions()
        let configuration = buildConfigure()
        sceneView.session.run(configuration)
        setControls()
    }
    
    func rotateMode() {
        switch self.scanMode {
        case .noneed:
            self.scanMode = .doing
            label.setText(text: "Reset")
            sceneBtn.isHidden = false
            exportBtn.isHidden = false
            originalSource = sceneView.scene.background.contents
            sceneView.scene.background.contents = UIColor.black
        case .doing:
            break
        case .done:
            scanAllGeometry(needTexture: false)
            self.scanMode = .noneed
            sceneBtn.isHidden = true
            exportBtn.isHidden = true
            label.setText(text: "Scan")
            sceneView.scene.background.contents = originalSource
        }
    }
    
    @IBAction func tappedExportButton(_ sender: UIButton) {
        scanAllGeometryWithExport(needTexture: true)
    }
    
    @IBAction func tappedSceneButton(_ sender: UIButton) {
        let scanVC = ScanVC()
        scanVC.usdzFileURL = path
        self.present(scanVC, animated: true, completion: nil)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard scanMode == .noneed else {
            return nil
        }
        guard let anchor = anchor as? ARMeshAnchor ,
              let frame = sceneView.session.currentFrame else { return nil }

        let node = SCNNode()
        let geometry = scanGeometory(frame: frame, anchor: anchor, node: node)
        node.geometry = geometry

        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard scanMode == .noneed else {
            return
        }
        guard let frame = self.sceneView.session.currentFrame else { return }
        guard let anchor = anchor as? ARMeshAnchor else { return }
        let geometry = self.scanGeometory(frame: frame, anchor: anchor, node: node)
        node.geometry = geometry
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if (self.scanMode == .doing) {
            self.scanAllGeometry(needTexture: true)
            self.scanMode = .done
        }
    }
    
    func scanGeometory(frame: ARFrame, anchor: ARMeshAnchor, node: SCNNode, needTexture: Bool = false, cameraImage: UIImage? = nil) -> SCNGeometry {

        let camera = frame.camera

        let geometry = SCNGeometry(geometry: anchor.geometry, camera: camera, modelMatrix: anchor.transform, needTexture: needTexture)

        if let image = cameraImage, needTexture {
            geometry.firstMaterial?.diffuse.contents = image
        } else {
            geometry.firstMaterial?.diffuse.contents = UIColor(red: 0.5, green: 1.0, blue: 0.0, alpha: 0.7)
        }
        node.geometry = geometry

        return geometry
    }
    func scanAllGeometryWithExport(needTexture: Bool) {
        guard let frame = sceneView.session.currentFrame else { return }
        guard let cameraImage = captureCamera() else { return }

        guard let anchors = sceneView.session.currentFrame?.anchors else { return }
        let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
        for anchor in meshAnchors {
            guard let node = sceneView.node(for: anchor) else { continue }
            let geometry = scanGeometory(frame: frame, anchor: anchor, node: node, needTexture: needTexture, cameraImage: cameraImage)
            node.geometry = geometry
        }

        let fileName = "Mesh"
        let documentDirURL = try! FileManager.default.url(for: .documentDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: true)
        let fileURL = documentDirURL.appendingPathComponent(fileName).appendingPathExtension("usdz")
        self.sceneView.scene.write(to: fileURL, options: nil, delegate: nil, progressHandler: nil)

        // Share the USDZ file on the main thread
        DispatchQueue.main.async {
            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view // For iPad
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    func scanAllGeometry(needTexture: Bool) {
        guard let frame = sceneView.session.currentFrame else { return }
        guard let cameraImage = captureCamera() else {return}
        
        guard let anchors = sceneView.session.currentFrame?.anchors else { return }
        let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor}
        for anchor in meshAnchors {
            guard let node = sceneView.node(for: anchor) else { continue }
            let geometry = scanGeometory(frame: frame, anchor: anchor, node: node, needTexture: needTexture, cameraImage: cameraImage)
            node.geometry = geometry
        }
        
        let fileName = "Mesh"
        let documentDirURL = try! FileManager.default.url(for: .documentDirectory,
                                                          in: .userDomainMask,
                                                          appropriateFor: nil,
                                                          create: true)
        let fileURL = documentDirURL.appendingPathComponent(fileName).appendingPathExtension("usdz")
        path = fileURL
        self.sceneView.scene.write(to: fileURL, options: nil, delegate: nil, progressHandler: nil)
    }
    
    
    func captureCamera() -> UIImage? {
        guard let frame = sceneView.session.currentFrame else {return nil}
        
        let pixelBuffer = frame.capturedImage
        
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        
        let context = CIContext(options:nil)
        guard let cameraImage = context.createCGImage(image, from: image.extent) else {return nil}
        
        return UIImage(cgImage: cameraImage)
    }
}

class TextureScene: SKScene {
    let textureSprite = SKSpriteNode()
    var onDismiss: (() -> Void)? = nil
    
    init(size: CGSize, texture: UIImage?) {
        super.init(size: size)
        
        self.scaleMode = .resizeFill
        
        if let texture = texture {
            textureSprite.texture = SKTexture(image: texture)
            textureSprite.size = size
            textureSprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
            self.addChild(textureSprite)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let onDismiss = self.onDismiss {
            onDismiss()
        }
    }
}
