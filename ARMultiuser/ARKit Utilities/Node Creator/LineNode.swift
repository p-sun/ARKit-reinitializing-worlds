//
//  LineNode.swift
//  ARMultiuser
//
//  Created by Paige Sun on 2018-11-26.
//  Copyright © 2018 Apple. All rights reserved.
//

import ARKit

extension NodeCreator {
	static func createWaypointBox(length: CGFloat) -> SCNNode {
		let height: CGFloat = 0.1

		let material = SCNMaterial()
		let diffuseColor = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
		material.diffuse.contents  = diffuseColor
		material.specular.contents = UIColor.green
		let box = SCNBox(width: 0.4, height: height, length: length, chamferRadius: 0.05)
		box.materials = [material]
		box.firstMaterial?.transparency = 0.5
		let boxNode = SCNNode(geometry: box)
		
		// Position the bottom of the box to rest flat against the ground
		boxNode.position.y = Float(height) / 2.0
		
		// Position the start of the box at the origin
		boxNode.position.z = -Float(length) / 2.0
		
		return boxNode
	}
}
