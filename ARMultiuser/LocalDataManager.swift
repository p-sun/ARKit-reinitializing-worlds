//
//  LocalDataManager.swift
//  ARMultiuser
//
//  Created by TSD064 on 2018-06-25.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation
import ARKit
import MultipeerConnectivity

struct LocalDataManager {
    
    static var filePath: URL {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        
        return url!.appendingPathComponent("MapData")
    }
    
    static func saveData(_ data: Data) {
        do {
          try data.write(to: filePath)
        } catch {
            print("Could not save data. \(error)")
        }
    }
    
    static func loadLocalMapData(receivedDataHandler: @escaping (Data, MCPeerID) -> Void) {
        do {
            let data = try Data(contentsOf: filePath)
            receivedDataHandler(data, MCPeerID(displayName: "LocalMapData"))
        } catch {
            print("Could not load data. \(error)")
        }
    }
}
