//
//  WaypointLineAnchor.swift
//  ARMultiuser
//
//  Created by Paige Sun on 2018-11-26.
//  Copyright © 2018 Apple. All rights reserved.
//

import ARKit

class WaypointLineAnchor: ARAnchor {
	
	enum Keys: String {
		case lengthKey = "lengthKey"
	}
	
	var length: Float
	
	init(length: Float, transform: simd_float4x4) {
		self.length = length
		super.init(name: "Waypoint Anchor", transform: transform)
	}
	
	required init(anchor: ARAnchor) {
		length = (anchor as! WaypointLineAnchor).length
		super.init(anchor: anchor)
	}
	
	required init?(coder aDecoder: NSCoder) {
		length = aDecoder.decodeFloat(forKey: Keys.lengthKey.rawValue)
		
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		aCoder.encode(length, forKey: Keys.lengthKey.rawValue)
		
		super.encode(with: aCoder)
	}
	
	override static var supportsSecureCoding: Bool {
		return true
	}
}
