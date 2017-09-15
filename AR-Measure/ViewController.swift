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

    var isPlaneDetected : Bool = false

    var trackerNode:TrackerNode?

    //the start position in real world
    var startPosition : SCNVector3?

    var endPosition : SCNVector3?

    //the user touch point respective to 2D space
    var tappedPoint : CGPoint?

    var resetTracking : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //hide the tracker, reveal only when plane got detected
        self.tracker.isHidden = true
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        //run the configuration with debug options
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showFeaturePoints]

        //plane detection
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
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
}


extension ViewController:ARSCNViewDelegate{
    // once the plane detected, we start the fuctionality.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        guard let _ = anchor as? ARPlaneAnchor else{
            return
        }

        isPlaneDetected = true
        print(" plane detected ")
    }


    //every time, check the screen center button and perform hit test and change the box accordingly.
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {

        //startPosition will be nil either plane not detected or user clicked on resetTracking
        if startPosition != nil  {

            // create the band node and add it to the rootnode.
            if trackerNode == nil {
                trackerNode = TrackerNode()
                trackerNode?.position = startPosition!
                self.sceneView.scene.rootNode.addChildNode(trackerNode!)
            }

            //get the world tracking location from the tapped point.

            let hitResults = sceneView.hitTest(tappedPoint!, types: .existingPlaneUsingExtent)
            guard let hitResult = hitResults.last else {
                return
            }

            endPosition = SCNVector3(hitResult.worldTransform.columns.3.x,hitResult.worldTransform.columns.3.y,hitResult.worldTransform.columns.3.z)

            let distance = startPosition?.distanceBetween(receiver: endPosition!)
            let angle = startPosition?.calculateAngleInRadians(receiver: endPosition!)
            trackerNode?.rotation = SCNVector4(0,1,0,-(Float.pi+angle!))

            trackerNode?.resizeTrackerNode(extent:distance!)

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
        self.tracker.frame = CGRect(x: ((tappedPoint?.x)!-20), y: (tappedPoint?.y)!, width: 40, height: 40)

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
