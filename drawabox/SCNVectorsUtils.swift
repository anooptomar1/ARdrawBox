//
//  SCNVectorsUtils.swift
//  drawabox
//
//  Created by pappar on 20/03/2018.
//  Copyright © 2018 zou yun. All rights reserved.
//
// from https://gist.github.com/jeremyconkin/a3909b2d3276d1b6fbff02cefecd561a

import Foundation
import SceneKit


import SceneKit

extension SCNVector3 {
    enum Axis {
        case x, y, z
    }
    
    static let zero = SCNVector3Zero
    static let one = SCNVector3(x: 1, y: 1, z: 1)
    
    static let axisX = SCNVector3(x: 1, y: 0, z: 0)
    static let axisY = SCNVector3(x: 0, y: 1, z: 0)
    static let axisZ = SCNVector3(x: 0, y: 0, z: 1)
    
    init(_ vec: vector_float3) {
        self.x = vec.x
        self.y = vec.y
        self.z = vec.z
    }
    
    init(_ value: Float) {
        self.x = value
        self.y = value
        self.z = value
    }
    
    init(_ value: CGFloat) {
        self.x = Float(value)
        self.y = Float(value)
        self.z = Float(value)
    }
    
    var length: Float {
        get {
            return sqrtf(x * x + y * y + z * z)
        }
        set {
            self.normalize()
            self *= length
        }
    }
    
    mutating func clamp(to maxLength: Float) {
        if self.length <= maxLength {
            return
        } else {
            self.normalize()
            self *= maxLength
        }
    }
    
    func normalized() -> SCNVector3 {
        let length = self.length
        guard length != 0 else {
            return self
        }
        
        return self / length
    }
    
    mutating func normalize() {
        self = self.normalized()
    }
    
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return transform.position
    }
    
    var description: String {
        return "(\(String(format: "%.2f", x)), \(String(format: "%.2f", y)), \(String(format: "%.2f", z)))"
    }
    
    func dot(_ vec: SCNVector3) -> Float {
        return (self.x * vec.x) + (self.y * vec.y) + (self.z * vec.z)
    }
    
    func cross(_ vec: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            self.y * vec.z - self.z * vec.y,
            self.z * vec.x - self.x * vec.z,
            self.x * vec.y - self.y * vec.x
        )
    }
    /**
     Calculate the angle between two vectors
     
     - parameter vectorB: Other vector in the calculation
     */
    func angleBetweenVectors(_ vec:SCNVector3) -> SCNFloat {
        
        //cos(angle) = (A.B)/(|A||B|)
        let cosineAngle = (dot(vec) / (self.length * vec.length))
        return SCNFloat(acos(cosineAngle))
    }
    
    func value(for axis: Axis) -> Float {
        switch axis {
        case .x: return x
        case .y: return y
        case .z: return z
        }
    }
    
    mutating func setAxis(_ axis: Axis, to value: Float) {
        switch axis {
        case .x: x = value
        case .y: y = value
        case .z: z = value
        }
    }
    
}

//MARK: - Vector arithmetic

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

func += (left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}

func -= (left: inout SCNVector3, right: SCNVector3) {
    left = left - right
}

func / (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x / right, left.y / right, left.z / right)
}

func * (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

func /= (left: inout SCNVector3, right: Float) {
    left = left / right
}

func *= (left: inout SCNVector3, right: Float) {
    left = left * right
}

func / (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x / right.x, left.y / right.y, left.z / right.z)
}

func * (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x * right.x, left.y * right.y, left.z * right.z)
}

func /= (left: inout SCNVector3, right: SCNVector3) {
    left = left / right
}

func *= (left: inout SCNVector3, right: SCNVector3) {
    left = left * right
}

// MARK: - Vectors from matrices

extension matrix_float4x4 {
    var position: SCNVector3 {
        return SCNVector3(x: columns.3.x,
                          y: columns.3.y,
                          z: columns.3.z)
    }
}






///**
// Multiply a vector times a constant
//
// - parameter vector: Vector to modify
// - parameter constant: Multiplier
// */
//func *(vector:SCNVector3, multiplier:SCNFloat) -> SCNVector3 {
//
//    return SCNVector3(vector.x * multiplier, vector.y * multiplier, vector.z * multiplier)
//}
//
///**
// Multiply a vector times a constant and update the vector inline
//
// - parameter vector: Vector to modify
// - parameter constant: Multiplier
// */
//func *=(vector: inout SCNVector3, multiplier:SCNFloat) {
//
//    vector = vector * multiplier
//}



