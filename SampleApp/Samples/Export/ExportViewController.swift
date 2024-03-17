//
//  ExportViewController.swift
//  SampleApp
//
//  Created by Ayush on 15/03/24.
//

import RealityKit
import ARKit

class ExportViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    
    var orientation: UIInterfaceOrientation {
        guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
            fatalError()
        }
        return orientation
    }
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    lazy var imageViewSize: CGSize = {
        CGSize(width: view.bounds.size.width, height: imageViewHeight.constant)
    }()

    override func viewDidLoad() {
        func setARViewOptions() {
            arView.debugOptions.insert(.showSceneUnderstanding)
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
        func initARView() {
            setARViewOptions()
            let configuration = buildConfigure()
            arView.session.run(configuration)
        }
        arView.session.delegate = self
        super.viewDidLoad()
        initARView()
    }
    @IBAction func tappedSceneButton(_ sender: UIButton){
        guard let camera = arView.session.currentFrame?.camera else {return}
        if let meshAnchors = arView.session.currentFrame?.anchors.compactMap({ $0 as? ARMeshAnchor }),
           let asset = convertToAsset(meshAnchors: meshAnchors, camera: camera) {
            do {
                let url = try export(asset: asset)
                let objViewController = ObjViewController()
                objViewController.objFileURL = url
                self.present(objViewController, animated: true, completion: nil)
            } catch {
                print("export error")
            }
        }
    
        
    }
    
    @IBAction func tappedExportButton(_ sender: UIButton) {
        guard let camera = arView.session.currentFrame?.camera else {return}
        if let meshAnchors = arView.session.currentFrame?.anchors.compactMap({ $0 as? ARMeshAnchor }),
           let asset = convertToAsset(meshAnchors: meshAnchors, camera: camera) {
            do {
                let url = try export(asset: asset)
                share(url: url)
            } catch {
                print("export error")
            }
        }
        func share(url: URL) {
            let vc = UIActivityViewController(activityItems: [url],applicationActivities: nil)
            vc.popoverPresentationController?.sourceView = sender
            self.present(vc, animated: true, completion: nil)
        }
    }

    func convertToAsset(meshAnchors: [ARMeshAnchor],camera: ARCamera) -> MDLAsset? {
        guard let device = MTLCreateSystemDefaultDevice() else {return nil}

        let asset = MDLAsset()

        for anchor in meshAnchors {
            let mdlMesh = anchor.geometry.toMDLMesh(device: device, camera: camera, modelMatrix: anchor.transform)
            asset.add(mdlMesh)
        }
        
        return asset
    }
    func export(asset: MDLAsset) throws -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = directory.appendingPathComponent("scaned.obj")

        try asset.export(to: url)

        return url
    }
  
    
}
