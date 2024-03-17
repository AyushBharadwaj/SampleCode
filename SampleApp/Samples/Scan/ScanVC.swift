//
//  ScanVC.swift
//  SampleApp
//
//  Created by Ayush on 15/03/24.
//

import UIKit
import SceneKit

class ScanVC: UIViewController {

    var sceneView: SCNView!
    var usdzFileURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let usdzFileURL = usdzFileURL else {
            print("No USDZ file URL provided")
            return
        }
        sceneView = SCNView(frame: view.bounds)
        view.addSubview(sceneView)
        if let scene = try? SCNScene(url: usdzFileURL, options: nil) {
            sceneView.scene = scene
            sceneView.autoenablesDefaultLighting = true
            sceneView.allowsCameraControl = true
            sceneView.backgroundColor = .white
            sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // Add pinch gesture recognizer for zooming
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            sceneView.addGestureRecognizer(pinchGesture)
        } else {
            print("Failed to load scene from \(usdzFileURL)")
        }
        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        dismissButton.frame = CGRect(x: 20, y: 20, width: 100, height: 40)
        view.addSubview(dismissButton)
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let cameraNode = sceneView.pointOfView else { return }
        var newFieldOfView = cameraNode.camera!.fieldOfView / CGFloat(gesture.scale)
        newFieldOfView = min(max(newFieldOfView, 5.0), 120.0)
        cameraNode.camera?.fieldOfView = newFieldOfView
        gesture.scale = 1.0
    }

    @objc func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
}
