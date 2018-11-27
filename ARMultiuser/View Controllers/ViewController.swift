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

    // MARK: - Actions and Outlets
    
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var restartMapButton: UIButton!
    @IBOutlet weak var saveMapButton: UIButton!
    @IBOutlet weak var sendMapButton: UIButton!
    @IBOutlet weak var showCloudPointsButton: UIButton!
    
    @IBOutlet weak var mappingStatusLabel: UILabel!

    @IBAction func didPressRestartMap(_ sender: Any) {
        shouldRestartMap.toggle()
    }
    
    private var shouldRestartMap: Bool {
        get {
            return UserDefaults.standard.value(forKey: "ShouldRestartMap") as? Bool ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ShouldRestartMap")
            restartMapButton.setTitle("ShouldRestartMap = \(newValue)", for: .normal)
        }
    }
    
    private var multipeerSession: MultipeerSession!
	
	private var cloudPoints = CloudPoints()
    
    private var featurePointsCloudParent = SCNNode()
    
    private var mapProvider: MCPeerID?
	
	
	
    
//    private var imageSampler: CapturedImageSampler? = nil
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        restartMapButton.setTitle("ShouldRestartMap = \(shouldRestartMap)", for: .normal) // TODO refactor
        showCloudPointsButton.setTitle("Show Cloud Points", for: .normal)
		
		// Hide this button for now. It's for WIP feature.
//        showCloudPointsButton.isHidden = true
		
        // Loading from other users
		multipeerSession = MultipeerSession(receivedDataHandler: receivedData)

		resetFeaturePointsCloudParent()
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
            runNewSession()
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

    
    // MARK: - Multiuser shared session
    
    /// - Tag: PlaceCharacter
    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {
        
        // Hit test to find a place for a virtual object.
        guard let hitTestResult = sceneView
            .hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
            .first
            else { return }
        
        // Place an anchor for a virtual character. The model appears in renderer(_:didAdd:for:).
		guard let currentFrame = sceneView.session.currentFrame else {
			return
		}

		let arCamera = currentFrame.camera
		let rotation = simd_float4x4(SCNMatrix4MakeRotation(arCamera.eulerAngles.y, 0, 1, 0))
		let finalTransform = simd_mul(hitTestResult.worldTransform, rotation)

	    let anchor = ARAnchor(name: "panda", transform: finalTransform)
        sceneView.session.add(anchor: anchor)
        
        // Send the anchor info to peers, so they can place the same content.
//        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
//            else { fatalError("can't encode anchor") }
//        self.multipeerSession.sendToAllPeers(data)
    }
    
    /// - Tag: GetWorldMap
    @IBAction func shareSession(_ button: UIButton) {
		// sharing doesn't work right now
//        sceneView.session.getCurrentWorldMap { worldMap, error in
//            guard let map = worldMap
//                else { print("Error: \(error!.localizedDescription)"); return }
//            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
//                else { fatalError("can't encode map") }
//            self.multipeerSession.sendToAllPeers(data)
//        }
    }
    
    @IBAction func saveMap(_ button: UIButton) {
        
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            
            print("Saving map with \(map.anchors.count) anchors")

            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: false) else {
				fatalError("can't encode map")
            }
            LocalDataManager.saveData(data)
        }
    }
    
    @IBAction func showCloudPoints(_ button: UIButton) {
        
        sceneView.session.getCurrentWorldMap { [weak self] worldMap, error in
    
            print("Got world map")
            
            guard let strongSelf = self else {
                return
            }
            
            guard let map = worldMap else {
                print("Error: \(error!.localizedDescription)")
                return
            }
			
			strongSelf.samplePointsInFrame()
			// strongSelf.sampleAllPoints(map: map)
        }
    }
	
	private func resetFeaturePointsCloudParent() {
		
		featurePointsCloudParent.removeFromParentNode()
		
		featurePointsCloudParent = SCNNode()
		sceneView.scene.rootNode.addChildNode(featurePointsCloudParent)
	}
	
	private func samplePointsInFrame() {
		guard let frame = sceneView.session.currentFrame,
			let imageSampler = createImageSampler(from: frame),
			let cloudToDraw = frame.rawFeaturePoints else {
			return
		}
		
		let screenFrameWidth = Float(view.frame.width)
		let screenFrameHeight = Float(view.frame.height)
		
		for point in cloudToDraw.points {
			
			let pointOn2DScreen = sceneView.projectPoint(SCNVector3(point))

			let scalarX = CGFloat(pointOn2DScreen.x / screenFrameWidth)
			let scalarY = CGFloat(pointOn2DScreen.y / screenFrameHeight)
			
			if let colorAtPoint = imageSampler.getColor(atX: scalarX, y: scalarY) {

				let anchor = ColorBoxAnchor(color: colorAtPoint, position: point)
				sceneView.session.add(anchor: anchor)
				
//				let childNode = NodeCreator.box(color: colorAtPoint, size: 0.003)
//				childNode.name = "Feature Point Box"
//				childNode.position = SCNVector3Make(point.x, point.y, point.z)
//				featurePointsCloudParent.addChildNode(childNode)
			}
		}
	}
	
	private func sampleAllPoints(map: ARWorldMap) {
		if let currentFrame = sceneView.session.currentFrame,
			let imageSampler = createImageSampler(from: currentFrame) {
			
			print("MAP rawFeaturePoints: \(map.rawFeaturePoints.points.count) points. \n\tFRAME rawFeaturePoints \(String(describing: sceneView.session.currentFrame?.rawFeaturePoints?.points.count)) points")
			
			drawFeaturePoints(cloudToDraw: map.rawFeaturePoints, imageSampler: imageSampler)
		}
	}
	
	private func createImageSampler(from frame: ARFrame) -> CapturedImageSampler? {
		do {
			return try CapturedImageSampler(frame: frame)
		} catch {
			print("Error: Could not initialize image sampler \(error)")
			return nil
		}
	}
	
    private func drawFeaturePoints(cloudToDraw: ARPointCloud, imageSampler: CapturedImageSampler) {
        
        featurePointsCloudParent.removeFromParentNode()
        
        featurePointsCloudParent = SCNNode()
        sceneView.scene.rootNode.addChildNode(featurePointsCloudParent)
        
//        let screenFrameWidth = Float(view.frame.width)
//        let screenFrameHeight = Float(view.frame.height)
		
        for point in cloudToDraw.points {
            
//            let pointOn2DScreen = sceneView.projectPoint(SCNVector3(point))
			
            let colorAtPoint: UIColor
//            if pointOn2DScreen.x < 0.0 || pointOn2DScreen.x > screenFrameWidth ||
//               pointOn2DScreen.y < 0.0 || pointOn2DScreen.y > screenFrameHeight {
                colorAtPoint = .green // Point out of screen
//            } else {
//                let scalarX = CGFloat(pointOn2DScreen.x / screenFrameWidth)
//                let scalarY = CGFloat(pointOn2DScreen.y / screenFrameHeight)
//                colorAtPoint = imageSampler.getColor(atX: scalarX, y: scalarY) ?? .red // Point on screen but we couldn't get the color
//            }
			
            let childNode = NodeCreator.box(color: colorAtPoint, size: 0.003)
            childNode.name = "Feature Point Box"
            childNode.position = SCNVector3Make(point.x, point.y, point.z)
            featurePointsCloudParent.addChildNode(childNode)
        }
    }
    
    func receivedData(_ data: Data, from peer: MCPeerID) {
        if let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [ARWorldMap.classForKeyedUnarchiver()], from: data),
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
        } else if let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [ARAnchor.classForKeyedUnarchiver()], from: data),
            let anchor = unarchived as? ARAnchor {
            
            sceneView.session.add(anchor: anchor)
        } else {
			print("ERROR: unknown data recieved from \(peer)")
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
       runNewSession()
    }
    
    private func runNewSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}

extension ViewController: ARSessionDelegate {
    
    // MARK: Session Frame and Camera
	
	func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
		updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
	}
	
	func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
//        if imageSampler != nil {
//            imageSampler == nil
//        }
        
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

    // MARK: ARSessionObserver
    
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
//
//    private func initizalizeImageSampler(frame: ARFrame) {
//        print("Initializing image sampler")
//        do {
//            imageSampler = try CapturedImageSampler(frame: frame)
//        } catch {
//            print("Error: Could not initialize image sampler \(error)")
//        }
//    }
}

// MARK: - Adding Nodes

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		
        if let name = anchor.name, name.hasPrefix("panda") {
            node.addChildNode(NodeCreator.createRedPandaModel())
			node.addChildNode(NodeCreator.createAxesNode(quiverLength: 0.3, quiverThickness: 0.4))
		} else if let colorAnchor = anchor as? ColorBoxAnchor {
			let boxNode = NodeCreator.box(color: colorAnchor.color, size: 0.003)
			boxNode.name = "Feature Point Box"
			node.addChildNode(boxNode)
		} else {
            node.addChildNode(NodeCreator.createAxesNode(quiverLength: 0.3, quiverThickness: 1.0))
        }
    }
}
