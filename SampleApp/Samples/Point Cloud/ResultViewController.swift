//
//  ResultViewController.swift
//  SampleApp
//
//  Created by Ayush on 16/03/24.
//

import UIKit
import QuartzCore
import SceneKit


class ResultViewController: UIViewController {

    var scene: SCNScene!
    var pcNode: SCNNode!
    var pointCloudString = ""
    
    override func loadView() {
        let scnView = SCNView()
        self.view = scnView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scene = SCNScene()
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.0
        cameraNode.camera?.zFar = 10.0
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0.3)
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 3, z: 3)
        scene.rootNode.addChildNode(lightNode)
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        if let fileURL = pointCloudString as? String,
           let points = parseTextFile(fileURL: fileURL) {
            if let geometry = createGeometry(from: points) {
                pcNode = SCNNode(geometry: geometry)
                pcNode.position = SCNVector3(x: 0, y: -0.1, z: 0)
                scene.rootNode.addChildNode(pcNode)
            } else {
                print("Failed to create geometry from point cloud data.")
            }
        } else {
            print("Failed to parse text file.")
        }
        
        guard let scnView = self.view as? SCNView else {
            fatalError("View is not an SCNView")
        }
        
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.showsStatistics = true
        scnView.backgroundColor = .black
        
        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        dismissButton.frame = CGRect(x: 20, y: 20, width: 100, height: 40)
        self.view.addSubview(dismissButton)
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func createGeometry(from points: [Point]) -> SCNGeometry? {
        var vertices: [SCNVector3] = []
        var colors: [SCNVector4] = []
        
        for point in points {
            vertices.append(SCNVector3(point.x, point.y, point.z))
            colors.append(SCNVector4(point.r / 255.0, point.g / 255.0, point.b / 255.0, 1.0))
        }
        
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let colorSource = SCNGeometrySource(
            data: NSData(bytes: colors, length: MemoryLayout<SCNVector4>.size * colors.count) as Data,
            semantic: .color,
            vectorCount: colors.count,
            usesFloatComponents: true,
            componentsPerVector: 4,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SCNVector4>.size
        )
        
        var indices: [Int32] = []
        for i in 0..<points.count {
            indices.append(Int32(i))
        }
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .point)
        let geometry = SCNGeometry(sources: [vertexSource, colorSource], elements: [element])
        return geometry
    }

    
    func parseTextFile(fileURL: String) -> [Point]? {
        do {
            let contents = fileURL
            let lines = contents.components(separatedBy: .newlines)
            
            var points: [Point] = []
            
            for line in lines {
                let components = line.components(separatedBy: " ")
                if components.count >= 3 {
                    if let x = Float(components[0]), let y = Float(components[1]), let z = Float(components[2]),let r = Float(components[3]), let g = Float(components[4]), let b = Float(components[5]){
                        let point = Point(x: x, y: y, z: z,r: r,g: g,b: b)
                        points.append(point)
                    }
                }
            }
            
            return points
        }
    }
    
    @objc func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
}
