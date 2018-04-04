//
//  SCNNode+Extensions.swift
//  drawabox
//
//  Created by pappar on 2018/4/2.
//  Copyright © 2018 zou yun. All rights reserved.
//


import SceneKit

extension SCNBoundingVolume {
    // Returns a point at a specified normalized location within the bounds of the volume, where 0 is min and 1 is max.
    func pointInBounds(at normalizedLocation: SCNVector3) -> SCNVector3 {
        let boundsSize = boundingBox.max - boundingBox.min
        let locationInPoints = boundsSize*normalizedLocation
        return locationInPoints + boundingBox.min
    }
}

// MARK: - Extensions
extension SCNNode {
    func displacement(to destination: SCNNode)->SCNVector3{
        let dis=position-destination.position
        return dis
    }
    
    // Gets distance between two SCNNodes
    func distance(to destination: SCNNode) -> CGFloat {
        
        // Meters to inches conversion
        //let inches: Float = 39.3701
        
        // Difference between x-positions
        let dx = destination.position.x - position.x
        
        // Difference between x-positions
        let dy = destination.position.y - position.y
        
        // Difference between x-positions
        let dz = destination.position.z - position.z
        
        // Formula to get meters
        let meters = sqrt(dx*dx + dy*dy + dz*dz)
        
        // Returns meters
        return CGFloat(meters)
    }
    
    func findheight(point1 dest1: SCNNode, point2 dest2: SCNNode) -> SCNVector3 {
        
        //dest1: a dest2: b, current c
        //used dotproduct to find the vector from line to p3
        let ac=position-dest1.position
        let ab=dest2.position-dest1.position
        let abunit=ab.normalized()
        let ad=abunit*(ac.dot(abunit))
        let dc=ac-ad
        // Returns vector
        return dc
    }
    //assume only x and z varies,
    func findcenter(point1 dest1: SCNNode, point2 dest2: SCNNode) -> SCNVector3 {
        let p3=findp3(point1: dest1, point2: dest2)
        let center=SCNVector3((p3.x+dest1.position.x)/2, dest1.position.y , (p3.z+dest1.position.z)/2)
        
        // Returns center
        return center
    }
    func findp3(point1 dest1: SCNNode, point2 dest2: SCNNode) -> SCNVector3 {
        
        let heightvector=findheight(point1: dest1, point2: dest2)
        let p3=dest2.position+heightvector
        
        // Returns p3
        return p3
    }
    func angletorotate(point1 dest1: SCNNode, point2 dest2: SCNNode) -> Float {
        let d=SCNVector3(dest2.position.x,dest1.position.y,dest1.position.z)// extension of p1 in x direction with same z coordinate as p2
        let ad=d-dest1.position
        let ab=dest2.position-dest1.position
        var angle=ad.angleBetweenVectors(ab)
        // Returns angle between points
        if (dest1.position.z-dest2.position.z<0){
            angle = (-angle)
        }
        if(dest1.position.x-dest2.position.x<0){
            angle = (-angle)
        }
        
        return -angle
    }
}
