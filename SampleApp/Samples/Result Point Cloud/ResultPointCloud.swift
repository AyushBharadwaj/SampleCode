//
//  ResultPointCloud.swift
//  SampleApp
//
//  Created by Ayush on 15/03/24.
//

import UIKit
import QuartzCore
import SceneKit

struct Point {
    var x: Float
    var y: Float
    var z: Float
    var r: Float
    var g: Float
    var b: Float
}

class ResultPointCloud: UIViewController {

    var scene: SCNScene!
    var pcNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scene = SCNScene()
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.0
        cameraNode.camera?.zFar = 10.0
        scene.rootNode.addChildNode(cameraNode)
        
        // Place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0.3)
        
        // Create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 3, z: 3)
        scene.rootNode.addChildNode(lightNode)
        
        // Create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Parse the text file containing point cloud data
        if let fileURL = Bundle.main.url(forResource: "Untitled_Scan_17_34_08", withExtension: "txt"),
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
        
        // Export the scene as a 3D model
        exportSceneToDownloadFolder()
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
            colors.append(SCNVector4(point.r, point.g, point.b, 1.0))
        }
        
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let colorData = NSData(bytes: colors, length: MemoryLayout<SCNVector4>.size * colors.count)
        let colorSource = SCNGeometrySource(data: colorData as Data,
                                             semantic: .color,
                                             vectorCount: colors.count,
                                             usesFloatComponents: true,
                                             componentsPerVector: 4,
                                             bytesPerComponent: MemoryLayout<Float>.size,
                                             dataOffset: 0,
                                             dataStride: MemoryLayout<SCNVector4>.size)
        
        var indices: [Int32] = []
        for i in 0..<points.count {
            indices.append(Int32(i))
        }
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .point)
        let geometry = SCNGeometry(sources: [vertexSource, colorSource], elements: [element])
        return geometry
    }
    
    func parseTextFile(fileURL: URL) -> [Point]? {
        do {
            let contents = try String(contentsOf: fileURL)
            let lines = contents.components(separatedBy: .newlines)
            
            var points: [Point] = []
            
            for line in lines {
                let components = line.components(separatedBy: ",")
                if components.count >= 3 {
                    if let x = Float(components[0]), let y = Float(components[1]), let z = Float(components[2]),let r = Float(components[3]), let g = Float(components[4]), let b = Float(components[5]){
                        let point = Point(x: x, y: y, z: z,r: r,g: g,b: b)
                        points.append(point)
                    }
                }
            }
            
            return points
        } catch {
            print("Error reading text file: \(error)")
            return nil
        }
    }
    
    func exportSceneToDownloadFolder() {
        guard let scene = self.scene as? SCNScene else {
            print("Scene is not an SCNScene")
            return
        }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Append the filename to the Documents directory URL
        let outputURL = documentsURL.appendingPathComponent("output.usdz")
        print("Exporting to: \(outputURL)") // Print out the export path
        
        // Export the scene to the Documents directory
        scene.write(to: outputURL, options: nil, delegate: nil) { (progress, error, stop) in
            if let error = error {
                print("Error exporting scene: \(error)")
            } else {
                print("Exporting progress: \(progress * 100)%")
                if progress >= 1.0 {
                    print("Exporting completed!")
                }
            }
        }
    }

}
