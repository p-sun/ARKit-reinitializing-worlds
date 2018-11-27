//
//  ColorBoxAnchor.swift
//  ARMultiuser
//
//  Created by Paige Sun on 2018-11-26.
//  Copyright © 2018 Apple. All rights reserved.
//

import ARKit

class ColorBoxAnchor: ARAnchor {
	
	enum Keys: String {
		case colorKey = "colorStringKey"
	}
	
	private var _colorString: String
	
	var color: UIColor {
		return UIColor(hexString: _colorString)
	}
	
	init(color: UIColor, position: vector_float3) {
		self._colorString = color.toHexString()
		let translation = float3(position.x, position.y, position.z)
		let transform = simd_float4x4(translation: translation)
		
		super.init(name: "", transform: transform)
	}
	
	required init(anchor: ARAnchor) {
		_colorString = (anchor as! ColorBoxAnchor)._colorString
		super.init(anchor: anchor)
	}
	
	required init?(coder aDecoder: NSCoder) {
		
		guard let colorStringObject = aDecoder.decodeObject(forKey: Keys.colorKey.rawValue) as? String else {
			return nil
		}
		
		_colorString = colorStringObject
		
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		aCoder.encode(_colorString, forKey:  Keys.colorKey.rawValue)
		
		super.encode(with: aCoder)
	}
	
	override static var supportsSecureCoding: Bool {
		return true
	}
}

extension UIColor {
	
	convenience init(hexString: String, alpha: CGFloat = 1.0) {
		let hexStringCleaned = hexString.replacingOccurrences(of: "#", with: "")
		let scanner = Scanner(string: hexStringCleaned)
		var color: UInt32 = 0
		
		scanner.scanHexInt32(&color)
		
		let mask = 0x000000FF
		let r = Int(color >> 16) & mask
		let g = Int(color >> 8) & mask
		let b = Int(color) & mask
		
		let red   = CGFloat(r) / 255.0
		let green = CGFloat(g) / 255.0
		let blue  = CGFloat(b) / 255.0
		
		self.init(red: red, green: green, blue: blue, alpha: alpha)
	}
	
	func toHexString() -> String {
		var r:CGFloat = 0
		var g:CGFloat = 0
		var b:CGFloat = 0
		var a:CGFloat = 0
		
		getRed(&r, green: &g, blue: &b, alpha: &a)
		
		let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
		
		return String(format:"#%06x", rgb)
	}
}
