//
//  NodeCreator.swift
//  ARMultiuser
//
//  Created by TSD064 on 2018-06-25.
//  Copyright © 2018 Apple. All rights reserved.
//

import SceneKit
import UIKit

struct NodeCreator {
    static func createAxesNode(quiverLength: CGFloat, quiverThickness: CGFloat) -> SCNNode {
        let quiverThickness = (quiverLength / 50.0) * quiverThickness
        let chamferRadius = quiverThickness / 2.0
        
        let xQuiverBox = SCNBox(width: quiverLength, height: quiverThickness, length: quiverThickness, chamferRadius: chamferRadius)
        xQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.red, respondsToLighting: false)]
        let xQuiverNode = SCNNode(geometry: xQuiverBox)
        xQuiverNode.position = SCNVector3Make(Float(quiverLength / 2.0), 0.0, 0.0)
        
        let yQuiverBox = SCNBox(width: quiverThickness, height: quiverLength, length: quiverThickness, chamferRadius: chamferRadius)
        yQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.green, respondsToLighting: false)]
        let yQuiverNode = SCNNode(geometry: yQuiverBox)
        yQuiverNode.position = SCNVector3Make(0.0, Float(quiverLength / 2.0), 0.0)
        
        let zQuiverBox = SCNBox(width: quiverThickness, height: quiverThickness, length: quiverLength, chamferRadius: chamferRadius)
        zQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.blue, respondsToLighting: false)]
        let zQuiverNode = SCNNode(geometry: zQuiverBox)
        zQuiverNode.position = SCNVector3Make(0.0, 0.0, Float(quiverLength / 2.0))
        
        let quiverNode = SCNNode()
        quiverNode.addChildNode(xQuiverNode)
        quiverNode.addChildNode(yQuiverNode)
        quiverNode.addChildNode(zQuiverNode)
        quiverNode.name = "Axes"
        return quiverNode
    }
    
    static func axesBox() -> SCNNode {
        let box = SCNBox(width: 0.3, height: 0.01, length: 0.01, chamferRadius: 0.01)
        box.materials = [SCNMaterial.material(withDiffuse: UIColor.red, respondsToLighting: false)]
        return SCNNode(geometry: box)
    }
    
    static func blueBox() -> SCNNode {
        let box = SCNBox(width: 0.03, height: 0.09, length: 0.15, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIColor.blue
        
        let node = SCNNode()
        node.geometry = box
        return node

    }
}
