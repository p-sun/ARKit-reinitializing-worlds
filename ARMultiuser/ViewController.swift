/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import SceneKit
import ARKit
import MultipeerConnectivity

class ViewController: UIViewController {
    // MARK: - IBOutlets
    
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var sendMapButton: UIButton!
    @IBOutlet weak var saveMapButton: UIButton!

    @IBOutlet weak var mappingStatusLabel: UILabel!
    
    @IBOutlet weak var restartMapButton: UIButton!
    var shouldRestartMap: Bool {
        get {
            return UserDefaults.standard.value(forKey: "ShouldRestartMap") as? Bool ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ShouldRestartMap")
            restartMapButton.setTitle("ShouldRestartMap = \(newValue)", for: .normal)
        }
    }
    
    @IBAction func didPressRestartMap(_ sender: Any) {
        shouldRestartMap.toggle()
    }
    
    // MARK: - View Life Cycle
    
    var multipeerSession: MultipeerSession!
	
	var cloudPoints = CloudPoints()
	
    override func viewDidLoad() {
        super.viewDidLoad()
        restartMapButton.setTitle("ShouldRestartMap = \(shouldRestartMap)", for: .normal) // TODO refactor

        // Loading from other users
       multipeerSession = MultipeerSession(receivedDataHandler: receivedData)

		Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
			
			guard let strongSelf = self else { return }
			
			if let cloud = strongSelf.sceneView.session.currentFrame?.rawFeaturePoints {
				for point in cloud.points {
					let didAddPoint = strongSelf.cloudPoints.addIfNeeded(point)
					if didAddPoint {
						let childNode = NodeCreator.box(color: .purple)
						childNode.position = SCNVector3Make(point.x, point.y, point.z)
						strongSelf.sceneView.scene.rootNode.addChildNode(childNode)
					}
				}
				
				print("There are features \(cloud.points.count)")
			}
		}
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self

        // Start the view's AR session.
        if shouldRestartMap {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            sceneView.session.run(configuration)
        } else {
            LocalDataManager.loadLocalMapData(receivedDataHandler: receivedData)
        }
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's AR session.
        sceneView.session.pause()
    }
	
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking(nil)
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    // MARK: - Multiuser shared session
    
    /// - Tag: PlaceCharacter
    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {
        
        // Hit test to find a place for a virtual object.
        guard let hitTestResult = sceneView
            .hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
            .first
            else { return }
        
        // Place an anchor for a virtual character. The model appears in renderer(_:didAdd:for:).
        let anchor = ARAnchor(name: "panda", transform: hitTestResult.worldTransform)
        sceneView.session.add(anchor: anchor)
        
        // Send the anchor info to peers, so they can place the same content.
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
            else { fatalError("can't encode anchor") }
        self.multipeerSession.sendToAllPeers(data)
    }
    
    /// - Tag: GetWorldMap
    @IBAction func shareSession(_ button: UIButton) {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            self.multipeerSession.sendToAllPeers(data)
        }
    }
    
    @IBAction func saveMap(_ button: UIButton) {
        
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            
            print("Saving map with \(map.anchors.count) anchors")
            
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            LocalDataManager.saveData(data)
        }
    }
    
    var mapProvider: MCPeerID?

    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        
        if let unarchived = try? NSKeyedUnarchiver.unarchivedObject(of: ARWorldMap.classForKeyedUnarchiver(), from: data),
            let worldMap = unarchived as? ARWorldMap {
            
            // Run the session with the received world map.
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            configuration.initialWorldMap = worldMap
            
            print("Loading map with \(worldMap.anchors.count) anchors")
            
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            
            for anchor in worldMap.anchors {
                sceneView.session.add(anchor: anchor)
            }
            
            // Remember who provided the map for showing UI feedback.
            mapProvider = peer
        }
        else
        if let unarchived = try? NSKeyedUnarchiver.unarchivedObject(of: ARAnchor.classForKeyedUnarchiver(), from: data),
            let anchor = unarchived as? ARAnchor {
            
            sceneView.session.add(anchor: anchor)
        }
        else {
            print("unknown data recieved from \(peer)")
        }
    }
}

// MARK: - AR session management

extension ViewController {
	
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
            
        case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            message = "Connected with \(peerNames)."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            message = "Received map from \(mapProvider!.displayName)."
            
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
    
    @IBAction func resetTracking(_ sender: UIButton?) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}

extension ViewController: ARSCNViewDelegate {
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		
		print("Did add node for anchor name \(anchor.name)")
		
		if let name = anchor.name, name.hasPrefix("panda") {
			node.addChildNode(NodeCreator.createRedPandaModel())
		} else {
			node.addChildNode(NodeCreator.createAxesNode(quiverLength: 0.3, quiverThickness: 1.0))
		}
	}
}

extension ViewController: ARSessionDelegate {
	
	func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
		updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
	}
	
	func session(_ session: ARSession, didUpdate frame: ARFrame) {
		switch frame.worldMappingStatus {
		case .notAvailable, .limited:
			sendMapButton.isEnabled = false
			saveMapButton.isEnabled = false
		case .extending:
			sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
			saveMapButton.isEnabled = true
		case .mapped:
			sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
			saveMapButton.isEnabled = true
		}
		mappingStatusLabel.text = frame.worldMappingStatus.description
		updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
	}
	
}
