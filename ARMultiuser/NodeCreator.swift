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
	public static func createAxesNode(quiverLength: CGFloat, quiverThickness: CGFloat) -> SCNNode {
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

    static func blueBox() -> SCNNode {
        let box = SCNBox(width: 0.001, height: 0.001, length: 0.001, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIColor.blue
        
        let node = SCNNode()
        node.geometry = box
        return node
    }
	
	static func createRedPandaModel() -> SCNNode {
		let sceneURL = Bundle.main.url(forResource: "max", withExtension: "scn", subdirectory: "Assets.scnassets")!
		let referenceNode = SCNReferenceNode(url: sceneURL)!
		referenceNode.load()
		
		return referenceNode
	}
}

private extension SCNMaterial {
	static func material(withDiffuse diffuse: Any?, respondsToLighting: Bool = true) -> SCNMaterial {
		let material = SCNMaterial()
		material.diffuse.contents = diffuse
		material.isDoubleSided = true
		if respondsToLighting {
			material.locksAmbientWithDiffuse = true
		} else {
			material.ambient.contents = UIColor.black
			material.lightingModel = .constant
			material.emission.contents = diffuse
		}
		return material
	}
}
