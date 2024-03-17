//
//  MenuDataSource.swift
//  SampleApp
//
//  Created by Ayush on 15/03/24.
//

import UIKit
import SwiftUI

struct MenuItem {
    let title: String
    let description: String
    let prefix: String
    var isSwiftUIView: Bool = false
    
    func viewController() -> UIViewController {
        if isSwiftUIView{
            let rootView = ContentView()
            let hostingController = UIHostingController(rootView: rootView)
            hostingController.title = title
            
            return hostingController
        }else {
            let storyboard = UIStoryboard(name: prefix, bundle: nil)
            let vc = storyboard.instantiateInitialViewController()!
            vc.title = title
            return vc
        }
    }
}

class MenuViewModel {
    private let dataSource = [
        MenuItem (
            title: "Mesh Acquisition",
            description: "Export scaned object to .obj file.",
            prefix: "Export"
        ),
        MenuItem (
            title: "Mesh Acquisition with color",
            description: "Scan object with color texture.",
            prefix: "Scan"
        ),
        MenuItem (
            title: "Point Cloud Renedering",
            description: "Creating point cloud and rendering on view .",
            prefix: "PointCloud"
        ),
        MenuItem (
            title: "Object Capture",
            description: "Scan Object through Lidar Sensor.",
            prefix: "ContentView",
            isSwiftUIView: true
        )
    ]
    
    var count: Int {
        dataSource.count
    }
    
    func item(row: Int) -> MenuItem {
        dataSource[row]
    }
    
    func viewController(row: Int) -> UIViewController {
        dataSource[row].viewController()
    }
}
