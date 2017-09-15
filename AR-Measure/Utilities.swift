//
//  Utilities.swift
//  AR-Measure
//
//  Created by Birapuram Kumar Reddy on 9/14/17.
//  Copyright © 2017 Myntra Design Pvt Ltd. All rights reserved.
//

import Foundation
import SceneKit

extension SCNVector3 {
    func distanceBetween(receiver destination:SCNVector3) -> Float {
        let x = self.x - destination.x
        let y = self.y - destination.y
        let z = self.z - destination.z

        return sqrtf( (x * x) + (y * y) + (z * z))
    }

    func calculateAngleInRadians(receiver destination: SCNVector3) -> Float {
        let x = self.x - destination.x
        let z = self.z - destination.z

        return atan2(z, x)
    }
}
