//
//  CloudPoints.swift
//  ARMultiuser
//
//  Created by Pei Sun on 2018-06-25.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation
import SceneKit

class CloudPoints {
	private var _points = Set<vector_float3>()

	func addIfNeeded(_ point: vector_float3) -> Bool {
		if !_points.contains(point) {
			_points.insert(point)
			return true
		}
		return false
	}
}

extension vector_float3: Hashable {
	public var hashValue: Int {
		return x.hashValue ^ y.hashValue ^ z.hashValue
	}
}
