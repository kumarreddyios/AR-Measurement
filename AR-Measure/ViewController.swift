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

    var trackerNode : SCNNode!

    var isPlaneDetected : Bool = false

    //the start position in real world
    var startPosition : SCNVector3?

    var endPosition : SCNVector3?

    //the user touch point respective to 2D space
    var tappedPoint : CGPoint?

    var resetTracking : Bool = true


    private var bandSizeInMeters=[CGFloat]() // will store the distance for the specific bands, 23.5 cm to 24.1 is UK 6
    private var bandNames=[String]() // will store the names of the bands UK5,UK6,UK7

    var scaleNodes : [SCNNode]!


    var rootScaleNode : SCNNode!

    
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

        bandSizeInMeters = [0.05,0.05,0.05,0.05,0.05,0.05]
        bandNames=["UK 5","UK 6","UK 7","UK 8","UK 9","UK 10","UK 11","UK 12"]
        scaleNodes = [SCNNode]()

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

        rootScaleNode = sceneView.scene.rootNode
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
        print("plane detected ")
    }


    //every time, check the screen center button and perform hit test and change the box accordingly.
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {

        DispatchQueue.main.async {
            // run async on DispatchQueue

            //startPosition will be nil either plane not detected or user clicked on resetTracking
            if self.startPosition != nil  {
                // create the band node and add it to the rootnode.
                if self.trackerNode == nil {
                    let bandGeometry = SCNBox(width: 0.005, height: 0.001, length: 0.005, chamferRadius: 0)
                    bandGeometry.firstMaterial?.diffuse.contents = UIColor.red
                    self.trackerNode = SCNNode(geometry: bandGeometry)
                    self.trackerNode.position = self.startPosition!
                    self.sceneView.scene.rootNode.addChildNode(self.trackerNode)
                }

                //get the world tracking location from the tapped point.

                let hitResults = self.sceneView.hitTest(self.tappedPoint!, types: .existingPlaneUsingExtent)
                guard let hitResult = hitResults.last else {
                    return
                }

                self.endPosition = SCNVector3(hitResult.worldTransform.columns.3.x,hitResult.worldTransform.columns.3.y,hitResult.worldTransform.columns.3.z)
                self.updateNode(startPoint: self.startPosition!, endpoint: self.endPosition!)

                 let angle = self.startPosition?.calculateAngleInRadians(receiver: self.endPosition!)
                 self.trackerNode?.rotation = SCNVector4(0,0,1,-(Float.pi+angle!))
            }
        }
    }
}

extension ViewController{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

       /* if startPosition != nil {
            let hitResults = sceneView.hitTest(tappedPoint!, types: .existingPlaneUsingExtent)
            guard let hitResult = hitResults.last else {
                return
            }

            endPosition = SCNVector3(hitResult.worldTransform.columns.3.x,hitResult.worldTransform.columns.3.y,hitResult.worldTransform.columns.3.z)
            print("start position \(String(describing: startPosition!))")
            print("end position \(String(describing: endPosition!))")
            self.updateNode(startPoint: startPosition!, endpoint: endPosition!)
        }*/

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
       /* if trackerNode != nil {
            trackerNode?.removeFromParentNode()
        }*/

    }
}


extension ViewController{

    func updateNode(startPoint:SCNVector3,endpoint:SCNVector3) {
        guard let scnBox = trackerNode.geometry as? SCNBox else {
            fatalError("Geometry is not SCNBox")
        }

        let distance=startPoint.distanceBetween(receiver: endpoint)

        print("\ndistance in meters \(distance)")
        print("distance is centimeters \(distance * 100) cms \n")

        //know the direction of vector
        let xDistance = abs(endpoint.x - startPoint.x)
        let yDistance = abs(endpoint.y - startPoint.y)
        let zDistance = abs(endpoint.z - startPoint.z)

//        print("before tracker node geometry \(scnBox)")
        print("before tracker node position \(trackerNode.position)\n")
        //vector is in z-Direction
        if (zDistance >= xDistance && zDistance >= yDistance){
            let tempDistance = distance - Float(scnBox.length)

            let startZPostion = trackerNode.position.z
            let endZPostion = endpoint.z

            var newZPosition: Float = 0
            var newZPositionForBand : Float = 0

            if (startZPostion < 0 && endZPostion < 0){
                if (startZPostion > endZPostion) {
                    newZPosition = (trackerNode.position.z - (tempDistance/2))
                    newZPositionForBand = (newZPosition + (distance/2))
                    newZPositionForBand = newZPositionForBand - Float(bandSizeInMeters[0]/2)

                    for node in scaleNodes {
                        node.removeFromParentNode()
                    }
//                    drawScale(hitPosition: SCNVector3(x: trackerNode.position.x-0.1, y: trackerNode.position.y, z: newZPositionForBand))
                }else{
                    newZPosition = (trackerNode.position.z + (tempDistance/2))
                    newZPositionForBand = (newZPosition - (distance/2))
                    newZPositionForBand = newZPositionForBand + Float(bandSizeInMeters[0]/2)
//                    drawScale(hitPosition: SCNVector3(x: trackerNode.position.x, y: trackerNode.position.y, z: newZPositionForBand))
                }
            }
            scnBox.length = CGFloat(distance)
            trackerNode.position = SCNVector3(x: trackerNode.position.x, y: trackerNode.position.y, z: newZPosition)
            print("moving in Z direction")
        } else if (xDistance >= yDistance && xDistance >= zDistance){
            /*scnBox.width = absDistance
            trackerNode.position = trackerNode.position + SCNVector3(x: offset, y: 0, z: 0)*/
            print("moving in X direction")
        }else if(yDistance >= xDistance && yDistance >= zDistance){
            /*scnBox.height = absDistance
            trackerNode.position = trackerNode.position + SCNVector3(x:0, y: offset, z: 0)*/
            print("moving in Y direction")
        }

        //print("after tracker node geometry \(scnBox)")
        print("after tracker node position \(trackerNode.position)")
    }
}




let bandWidth:CGFloat = 0.1
let bandHeight:CGFloat = 0.001
let dottedBoxWidth:CGFloat = 0.01
let dottedBoxHeight: CGFloat = 0.001
let dottedBoxLength: CGFloat = 0.001
extension ViewController {
    func drawScale(hitPosition:SCNVector3) {
        var index=0
        let x=hitPosition.x
        let y=hitPosition.y
        var z=hitPosition.z
        //
        while index < bandSizeInMeters.count {
            let length=bandSizeInMeters[index]
            let bandBox:SCNBox!
            if index == 0 {
                bandBox=SCNBox(width: bandWidth, height: bandHeight, length: length, chamferRadius: 0)
                bandBox.firstMaterial?.diffuse.contents=UIColor(red: 185/255, green: 78/255, blue: 63/255, alpha: 0.5)
                bandBox.firstMaterial?.ambientOcclusion.contents=UIColor.red
                bandBox.firstMaterial?.transparent.contents=UIColor.red
            }else if index % 2 == 0 {
                bandBox=SCNBox(width: bandWidth, height: bandHeight, length: length, chamferRadius: 0)
                bandBox.firstMaterial?.diffuse.contents=UIColor(red: 228/255, green: 184/255, blue: 191/255, alpha: 0.8)
            }else{
                bandBox=SCNBox(width: bandWidth, height: bandHeight, length: length, chamferRadius: 0)
                bandBox.firstMaterial?.diffuse.contents=UIColor(red: 200/255, green: 166/255, blue: 154/255, alpha: 0.9)
            }
            bandBox.firstMaterial?.readsFromDepthBuffer=false
            bandBox.firstMaterial?.writesToDepthBuffer=false

            let bandNode = SCNNode(geometry: bandBox)
            bandNode.position = SCNVector3(x,y,z)
            rootScaleNode.addChildNode(bandNode)
            var dottedLines=0
            if index == 0 {
                dottedLines=3
            }else{
                dottedLines=index*2+2
            }
//            drawDottedLines(mainNode: rootScaleNode, position: bandNode.position,width: 0.1,length: length,dottedLines: dottedLines,text:bandNames[index])
            index=index+1
            if index < bandSizeInMeters.count {
                let currentLength=Float(length/2)
                let nextLength=Float(bandSizeInMeters[index]/2)
                z=z-currentLength-nextLength
            }
        }
        sceneView.scene.rootNode.addChildNode(rootScaleNode)
    }

    func drawDottedLines(mainNode:SCNNode,position:SCNVector3,width:CGFloat,length:CGFloat,dottedLines:Int,text:String){
        var index=0
        var x=position.x-Float(width/2)
        let z=position.z-Float(length/2)
        while(index < dottedLines){
            let box=SCNBox(width: dottedBoxWidth, height: dottedBoxHeight, length: dottedBoxLength, chamferRadius: 0.0)
            box.firstMaterial?.diffuse.contents=UIColor.white
            let node=SCNNode(geometry: box)
            node.position=SCNVector3(x,position.y,z)
            x=x-0.02 // gap between the dots
            index=index+1
            mainNode.addChildNode(node)
        }
        let newposition=SCNVector3(x, position.y, position.z)
//        createTextNodes(node: mainNode, position: newposition, text: text)
    }

    func drawStartLines(mainNode:SCNNode,position:SCNVector3,width:CGFloat,length:CGFloat,dottedLines:Int,text:String){
        var index=0
        var x=position.x-Float(width/2)
        let z=position.z+Float(length/2)
        while(index < dottedLines){
            let box=SCNBox(width: dottedBoxWidth, height: dottedBoxHeight, length: dottedBoxLength, chamferRadius: 0.0)
            box.firstMaterial?.diffuse.contents=UIColor.white
            let node=SCNNode(geometry: box)
            node.position=SCNVector3(x,position.y,z)
            x=x-0.02 // gap between the dots
            index=index+1
            mainNode.addChildNode(node)
        }
        let newposition=SCNVector3(x, position.y, z)
//        createTextNodes(node: mainNode, position: newposition, text: text)
    }

    func createTextNodes(node:SCNNode,position:SCNVector3,text:String,width:CGFloat=0.1,height:CGFloat=0.01,length:CGFloat=0.2){
        let textGeo = SCNText(string: text, extrusionDepth: 1.0)
        textGeo.firstMaterial?.diffuse.contents = UIColor.white
        textGeo.firstMaterial?.ambientOcclusion.contents=UIColor.white
        textGeo.firstMaterial?.transparent.contents=UIColor.white
        textGeo.font = UIFont.systemFont(ofSize: 6.0)
        textGeo.flatness=1.0

        let textNode = SCNNode(geometry: textGeo)
        textNode.position = SCNVector3(position.x, position.y,position.z+(0.03*position.z))
        textNode.eulerAngles = SCNVector3(-0.5*Double.pi,0.0,0.0)
        textNode.scale = SCNVector3(0.003,0.003,0.003)
        node.addChildNode(textNode)
    }
}

