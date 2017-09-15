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

    override init() {
        super.init()
        let bandGeometry = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
        bandGeometry.firstMaterial?.diffuse.contents = UIColor.red
        let sampleNode = SCNNode(geometry: bandGeometry)
        self.addChildNode(sampleNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func resizeTrackerNode(extent:Float){
        var (min, max) = boundingBox
        max.x = extent

        update(minExtents: min, maxExtents: max)
    }

    func update(minExtents: SCNVector3, maxExtents: SCNVector3) {
        guard let scnBox = self.childNodes.first?.geometry as? SCNBox else {
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
        self.childNodes.first?.position = vector + SCNVector3(x: offset, y: 0, z: 0)
//        self.position = vector + SCNVector3(x: offset, y: 0, z: 0)

    }
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}
