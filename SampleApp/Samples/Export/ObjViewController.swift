//
//  ObjViewController.swift
//  SampleApp
//
//  Created by Ayush on 15/03/24.
//

import UIKit
import SceneKit
import SceneKit.ModelIO

class ObjViewController: UIViewController {

    var objFileURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        let scene = SCNScene()

        do {
            let asset = MDLAsset(url: objFileURL ?? URL(fileURLWithPath: ""))
            guard let object = asset.object(at: 0) as? MDLMesh
                 else { fatalError("Failed to get mesh from asset.") }

            let newNode  = SCNNode(mdlObject: object)
            scene.rootNode.addChildNode(newNode)
            let sceneView = SCNView(frame: self.view.frame)
            sceneView.scene = scene
            sceneView.autoenablesDefaultLighting = true
            sceneView.allowsCameraControl = true
            sceneView.backgroundColor = .white
            sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(sceneView)
        } 
        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        dismissButton.frame = CGRect(x: 20, y: 20, width: 100, height: 40)
        self.view.addSubview(dismissButton)
    }

    @objc func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
}
