//
//  FocalNode.swift
//  drawabox
//
//  Created by pappar on 21/03/2018.
//  Copyright © 2018 zou yun. All rights reserved.
//

import Foundation
import SceneKit

class FocalNode: SCNNode {
    
    let size: CGFloat = 0.1
    let segmentWidth: CGFloat = 0.004
    
    private let colorMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellow
        return material
    }()
    
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func createSegment(width: CGFloat, height: CGFloat) -> SCNNode {
        let segment = SCNPlane(width: width, height: height)
        segment.materials = [colorMaterial]
        
        return SCNNode(geometry: segment)
    }
    
    private func addHorizontalSegment() {
        let segmentNode = createSegment(width: segmentWidth, height: size)
        
        
        addChildNode(segmentNode)
    }
    
    private func addVerticalSegment() {
        let segmentNode = createSegment(width: size, height: segmentWidth)
        
        addChildNode(segmentNode)
    }
    
    private func setup() {
//        let dist = Float(size) / 2.0
        addHorizontalSegment()
        addVerticalSegment()
        
        // Rotate the node so the square is flat against the floor
        transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
    }
    
}
