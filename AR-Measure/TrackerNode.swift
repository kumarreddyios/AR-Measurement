//
//  BandNode.swift
//  AR-Measure
//
//  Created by Birapuram Kumar Reddy on 9/14/17.
//  Copyright © 2017 Myntra Design Pvt Ltd. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class TrackerNode: SCNNode {

    lazy var childNode : SCNNode = createChildNode()
    weak var viewController : ViewController?
    var scaleNodes : [SCNNode]!
    var textNodes : [SCNNode]!
    var delegate : TrackerNodeProtocol?

    override init() {
        super.init()
        self.geometry?.firstMaterial?.diffuse.contents = UIColor.brown
        scaleNodes = [SCNNode]()
        textNodes = [SCNNode]()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createChildNode() -> SCNNode{
        let bandGeometry = SCNBox(width: 0.007, height: 0.001, length: 0.007, chamferRadius: 0)
        bandGeometry.firstMaterial?.diffuse.contents = UIColor.red
        let sampleNode = SCNNode(geometry: bandGeometry)
        self.addChildNode(sampleNode)
        return sampleNode
    }

    func resizeTrackerNode(extent:Float){
        var (min, max) = boundingBox
        max.x = extent
        update(minExtents: min, maxExtents: max)
    }

    func update(minExtents: SCNVector3, maxExtents: SCNVector3) {
        guard let scnBox = childNode.geometry as? SCNBox else {
            fatalError("Geometry is not SCNBox")
        }

        // Normalize the bounds so that min is always < max
        let absMin = SCNVector3(x: min(minExtents.x, maxExtents.x), y: min(minExtents.y, maxExtents.y), z: min(minExtents.z, maxExtents.z))
        let absMax = SCNVector3(x: max(minExtents.x, maxExtents.x), y: max(minExtents.y, maxExtents.y), z: max(minExtents.z, maxExtents.z))

        // Set the new bounding box
        boundingBox = (absMin, absMax)

        // Calculate the size vector
        let size = absMax - absMin

        // Take the absolute distance
        let absDistance = CGFloat(abs(size.x))

        // The new width of the box is the absolute distance
        scnBox.width = absDistance

        // Give it a offset of half the new size so they box remains fixed
        let offset = size.x * 0.5

        // Create a new vector with the min position of the new bounding box
        let vector = SCNVector3(x: absMin.x, y: absMin.y, z: absMin.z)

        // And set the new position of the node with the offset
        childNode.position = vector + SCNVector3(x: offset, y: 0, z: 0)
        self.drawScale(position: vector, distance:Float(absDistance))
        self.delegate?.updateDistacne(distance: Float(absDistance))
    }
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}


let bandWidth:CGFloat = 0.1
let bandHeight:CGFloat = 0.001
let dottedBoxWidth:CGFloat = 0.05
let dottedBoxHeight: CGFloat = 0.005
let dottedBoxLength: CGFloat = 0.001
extension TrackerNode {
    func drawScale(position : SCNVector3, distance : Float){

        //clear the previously added scale nodes
        for scaleNode in scaleNodes {
            scaleNode.removeFromParentNode()
        }

        for textNode in textNodes {
            textNode.removeFromParentNode()
        }

        var prevWidth:Float = position.x
        var distanceCovered:Float = 0
        let scalePoint:Float = 0.05
        var index = 0

        while distanceCovered < distance {
            let xPosition = prevWidth + (scalePoint)
            prevWidth = xPosition
            distanceCovered = abs(prevWidth)
            let tempNode = createScaleNode()
            tempNode.position = SCNVector3(x:xPosition,y:position.y+0.05,z:position.z+0.05)
            tempNode.eulerAngles = SCNVector3Make(0,Float(Double.pi/2),0)

            let textNode = createTextNode(text: "5 CM")
            textNode.position = tempNode.position + SCNVector3(x:0.01,y:0,z:0)
            textNode.eulerAngles = SCNVector3Make(-Float(Double.pi/2),-Float(Double.pi/2),Float(Double.pi/2))

            index += 1
            self.addChildNode(tempNode)
            self.addChildNode(textNode)
            scaleNodes.append(tempNode)
            textNodes.append(textNode)
        }
    }

    func createScaleNode() -> SCNNode {
        let scaleBox = SCNBox(width: dottedBoxWidth, height: dottedBoxHeight, length: dottedBoxLength, chamferRadius: 0)
        scaleBox.firstMaterial?.diffuse.contents = UIColor.blue
        return SCNNode(geometry: scaleBox)
    }

    func createTextNode(text : String) -> SCNNode {
        let textGeo = SCNText(string: text, extrusionDepth: 1.0)
        textGeo.firstMaterial?.diffuse.contents = UIColor.white
        textGeo.firstMaterial?.ambientOcclusion.contents=UIColor.white
        textGeo.firstMaterial?.transparent.contents=UIColor.white
        textGeo.font = UIFont.systemFont(ofSize: 6.0)
        textGeo.flatness=1.0

        let textNode = SCNNode(geometry: textGeo)
//        textNode.position = SCNVector3(position.x, position.y,position.z+(0.03*position.z))
//        textNode.eulerAngles = SCNVector3(-0.5*Double.pi,0.0,0.0)
        textNode.scale = SCNVector3(0.003,0.003,0.003)
        return textNode
    }
}

