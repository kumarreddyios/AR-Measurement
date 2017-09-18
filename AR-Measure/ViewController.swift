//
//  ViewController.swift
//  AR-Measure
//
//  Created by Birapuram Kumar Reddy on 9/14/17.
//  Copyright © 2017 Myntra Design Pvt Ltd. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var tracker: UIButton!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var infoView: UIVisualEffectView!
    @IBOutlet weak var shoeStatsView: UIVisualEffectView!
    @IBOutlet weak var distanceInCms: UILabel!
    @IBOutlet weak var ukSize: UILabel!

    var isPlaneDetected : Bool = false
    var trackerNode:TrackerNode?
    //the start position in real world
    var startPosition : SCNVector3?
    var endPosition : SCNVector3?

    //the user touch point respective to 2D space
    var tappedPoint : CGPoint?
    var resetTracking : Bool = true

    var shoeSizeInCms : [Float] = [22.5,23.5,24.5,25.5,26.5,27.5,28.5,29.5,30.5]
    var bandName : [String] = ["4","5","6","7","8","9","10","11","12"]

    let standardConfiguration : ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        return configuration
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        let scene = SCNScene()
        sceneView.scene = scene
        //hide the tracker and statsview
        tracker.isHidden = true
        shoeStatsView.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        if ARWorldTrackingConfiguration.isSupported {
            sceneView.session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
        }else{
            infoView.isHidden = false
            infoLabel.text = "This app requires world tracking. World tracking is only available on iOS devices with A9 processor or newer."
        }
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }

    @IBAction func resetTracking(_ sender: Any) {
        sceneView.session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
        shoeStatsView.isHidden = true
        resetTracking = true
        isPlaneDetected = false
    }
}


extension ViewController:ARSCNViewDelegate{
    // once the plane detected, we start the fuctionality.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else{
            return
        }
        DispatchQueue.main.async {
            self.infoLabel.text = " surface detected.  "
            self.isPlaneDetected = true
            self.shoeStatsView.isHidden = false
        }
    }

    //every time, check the screen center button and perform hit test and change the box accordingly.
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async { [unowned self] in
            //startPosition will be nil either plane not detected or user clicked on resetTracking
            if self.startPosition != nil  {
                // create the band node and add it to the rootnode.
                if self.trackerNode == nil {
                    self.trackerNode = TrackerNode()
                    self.trackerNode?.delegate = self
                    self.trackerNode?.position = self.startPosition!
                    self.sceneView.scene.rootNode.addChildNode(self.trackerNode!)
                }

                //get the world tracking location from the tapped point.
                let hitResults = self.sceneView.hitTest(self.tappedPoint!, types: .existingPlaneUsingExtent)
                guard let hitResult = hitResults.last else {
                    return
                }
                self.endPosition = SCNVector3(hitResult.worldTransform.columns.3.x,hitResult.worldTransform.columns.3.y,hitResult.worldTransform.columns.3.z)
                let distance = self.startPosition?.distanceBetween(receiver: self.endPosition!)
                let angle = self.startPosition?.calculateAngleInRadians(receiver: self.endPosition!)
                self.trackerNode?.rotation = SCNVector4(0,1,0,-(Float.pi+angle!))
                self.trackerNode?.resizeTrackerNode(extent:distance!)
            }
        }
    }
}

extension ViewController{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        //if resetTracking is true then only we allo touch events.
        if !resetTracking {
            return
        }

        //if the plane detected then only go for hitTest
        if !isPlaneDetected {
            return
        }

        //take the first touch
        guard let touch = touches.first else {
            return
        }

        resetTracking = false
        tappedPoint = touch.location(in: sceneView)

        //place the crosshair at this point
        self.tracker.isHidden = false
        self.tracker.frame = CGRect(x: ((tappedPoint?.x)!-11), y: (tappedPoint?.y)!, width: 22, height: 22)

        //perform the hitTest on existingPlaneWithExtent
        let hitResults = sceneView.hitTest(tappedPoint!, types: .existingPlaneUsingExtent)

        guard let hitPosition = hitResults.last else {
            return
        }
        startPosition = SCNVector3(hitPosition.worldTransform.columns.3.x,hitPosition.worldTransform.columns.3.y,hitPosition.worldTransform.columns.3.z)

        // remove the node which added previously
        if trackerNode != nil {
            trackerNode?.removeFromParentNode()
        }
    }
}

extension ViewController {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let message: String
        // Inform the user of their camera tracking state.
        switch camera.trackingState {
        case .notAvailable:
            message = "Tracking unavailable"
        case .normal:
            message = "Tracking normal"
        case .limited(.excessiveMotion):
            message = "Tracking limited - Too much camera movement"
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Not enough surface detail"
        case .limited(.initializing):
            message = "Initializing AR Session"
        }
        infoLabel.text = message
    }
}

extension ViewController : TrackerNodeProtocol {
    func updateDistacne(distance: Float) {
        let inCms = distance * 100
        self.distanceInCms.text = String(format: "%.0f", inCms)
        self.ukSize.text = updateUKSize(distInCms: inCms)
    }

    func updateUKSize(distInCms:Float) -> String {
        if (distInCms < shoeSizeInCms[0]){
            return "NA"
        }else{
            for (index,_) in shoeSizeInCms.enumerated() {
                if ( (index + 1) < shoeSizeInCms.count && shoeSizeInCms[index+1] > distInCms ){
                    let low = distInCms - shoeSizeInCms[index]
                    let high = shoeSizeInCms[index+1] - distInCms
                    if ( low == high){
                        return bandName[index+1]
                    }else if(low < high){
                        return bandName[index]
                    }else{
                        return bandName[index+1]
                    }
                }
            }
        }
        return "NA"
    }
}
