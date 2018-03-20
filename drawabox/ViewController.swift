//
//  ViewController.swift
//  drawabox
//
//  Created by pappar on 09/03/2018.
//  Copyright © 2018 zou yun. All rights reserved.
//
//TODO: stretch the size of the plane based on feature points
//change the taphandler to button press
//display the length of the sides
//the two pts set the width, the third point extrapolate the length
//draw a line from pt a to pt b following the button position
//replace the button with a focal pt at the center
//add words to it
//set bounding box instead of drawing a box
//proposal: move the pivot to the first point and rotate around

import UIKit
import SceneKit
import ARKit



class ViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - Interface Builder Connections

    @IBOutlet weak var sceneView: ARSCNView!
    //
    

    @IBOutlet weak var heightSlider: UISlider!

    @IBOutlet weak var selectedpoint: UIButton!
    // Spheres nodes
    var spheres: [SCNNode] = []
    // Measurement label
    var measurementLabel = UILabel()
    

    
    //height slider bar

    var configuration : ARWorldTrackingConfiguration?
    let planeIdentifiers = [UUID]()
    var anchors = [ARAnchor]()
    var nodes = [SCNNode]()
    
    // keep track of number of anchor nodes that are added into the scene
    var planeNodesCount = 0
    let planeHeight: CGFloat = 0.01
    // set isPlaneSelected to true when user taps on the anchor plane to select.
    var isPlaneSelected = false
    var newBox : SCNBox?
    var newBoxNode :SCNNode?
    var center : SCNVector3?
    let formatter = NumberFormatter()
    
    @IBAction func heightchanged(_ sender: UISlider) {
        let heightd=sender.value
        newBoxNode?.position.y = (center?.y)!+heightd/2
        newBox?.height = CGFloat(heightd)

    }
    
    @IBAction func selectpoint(_ sender: UIButton) {
        let location = CGPoint(x: sender.frame.origin.x+15, y: sender.frame.origin.y+15)
        // Gets the location of the tap and assigns it to a constant
       
        // Searches for real world objects such as surfaces and filters out flat surfaces
        let hitTest = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        
        // Assigns the most accurate result to a constant if it is non-nil
        guard let result = hitTest.last else { return }
        
        // Converts the matrix_float4x4 to an SCNMatrix4 to be used with SceneKit
        let hitTransform = result.worldTransform
        let vector = SCNVector3Make(hitTransform.columns.3.x,
                                    hitTransform.columns.3.y,
                                    hitTransform.columns.3.z)
        
        //        let transform = SCNMatrix4.init(result.worldTransform)
        //
        //        // Creates an SCNVector3 with certain indexes in the matrix
        //        let vector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
        
        // Makes a new sphere with the created method
        let sphere = newSphere(at: vector)
        
        // Checks if there is at least one sphere in the array
        if let first = spheres.first {
            
            // Adds a second sphere to the array
            spheres.append(sphere)
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 3
            if spheres.count == 2 {
                let dis12=sphere.displacement(to: first)
                let worldoriginvector=sphere.position-SCNVector3(0,0,0)
                print(dis12)

                measurementLabel.text = "width: "+formatter.string(from: sphere.distance(to: first) as NSNumber)!+"m"
            }
            if spheres.count == 3 {
                print(spheres[0])
                print(spheres[1])
                print(spheres[2])
                
                
                let boxlen=sphere.findheight(point1: first, point2: spheres[1]).magnitude
                let boxwid=first.distance(to: spheres[1])
                let stringlen=formatter.string(from: boxlen as NSNumber)!
                let stringwid=formatter.string(from: boxwid as NSNumber)!

                center=sphere.findcenter(point1: first, point2: spheres[1])
                measurementLabel.text = "width: "+stringwid+"m; length: "+stringlen+"m"
//                print(center)
                let p3 = sphere.findp3(point1: first, point2: spheres[1])
//                print(p3)
                spheres[2]=newSphere(at: p3)
                createBox(position: center!, width: boxwid, length: CGFloat(boxlen))
                let angle=sphere.angletorotate(point1: first, point2: spheres[1])
            
                newBoxNode?.eulerAngles.y+=angle
                heightSlider.isHidden=false
                selectedpoint.isHidden=true
                
            }
            
            
            // If more that two are present...
            if spheres.count > 3 {
                
                // Iterate through spheres array
                for sphere in spheres {
                    
                    // Remove all spheres
                    sphere.removeFromParentNode()
                }
                
                // Remove extraneous spheres
                spheres = [spheres[3]]
            }
            
            // If there are no spheres...
        } else {
            // Add the sphere
            spheres.append(sphere)
            
        }
        
        // Iterate through spheres array
        for sphere in spheres {
            
            // Add all spheres in the array
            self.sceneView.scene.rootNode.addChildNode(sphere)
        }
        
        
    }
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
       initiatelabel()
        
        selectedpoint.frame = CGRect(x: view.frame.size.width/2-30, y: view.frame.size.height/2+30, width: 40, height: 40)
        
        
        selectedpoint.isHidden=true
        
        heightSlider.isHidden=true
        
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        
//        // Creates a tap handler and then sets it to a constant
//        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
//
//        // Sets the amount of taps needed to trigger the handler
//        tapRecognizer.numberOfTapsRequired = 1
//
//        // Adds the handler to the scene view
//        sceneView.addGestureRecognizer(tapRecognizer)
//        print(isPlaneSelected)
      
    }
    func initiatelabel(){
        // Creates a background for the label
        measurementLabel.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 80)
        
        // Makes the background white
        measurementLabel.backgroundColor = .white
        
        // Sets some default text
        measurementLabel.text = "0 meters"
        
        // Centers the text
        measurementLabel.textAlignment = .center
        
        // Adds the text to the
        view.addSubview(measurementLabel)
        
    }
    
//    // selects the anchor at the specified location and removes all other unused anchors
//    func selectExistingPlane(location: CGPoint) {
//        // Hit test result from intersecting with an existing plane anchor, taking into account the plane’s extent.
//        let hitResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
//        if hitResults.count > 0 {
//            let result: ARHitTestResult = hitResults.first!
//            if let planeAnchor = result.anchor as? ARPlaneAnchor {
//                for var index in 0...anchors.count - 1 {
//                    // remove all the nodes from the scene except for the one that is selected
//                    if anchors[index].identifier != planeAnchor.identifier {
//                        sceneView.node(for: anchors[index])?.removeFromParentNode()
//                        sceneView.session.remove(anchor: anchors[index])
//                    }
//                    index += 1
//                }
//                // keep track of selected anchor only
//                anchors = [planeAnchor]
//                // set isPlaneSelected to true
//                isPlaneSelected = true
//                setPlaneTexture(node: sceneView.node(for: planeAnchor)!)
//            }
//        }
//    }
//    func setPlaneTexture(node: SCNNode) {
//        if let geometryNode = node.childNodes.first {
//            if node.childNodes.count > 0 {
//                geometryNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "./art.scnassets/floor.png")
//                geometryNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
//                geometryNode.geometry?.firstMaterial?.diffuse.wrapS = SCNWrapMode.repeat
//                geometryNode.geometry?.firstMaterial?.diffuse.wrapT = SCNWrapMode.repeat
//                geometryNode.geometry?.firstMaterial?.diffuse.mipFilter = SCNFilterMode.linear
//            }
//        }
//    }
    func createBox(position : SCNVector3,width : CGFloat, length: CGFloat) {
        newBox = SCNBox(width: width, height: 0.005, length: length, chamferRadius: 0.001)
        newBoxNode = SCNNode(geometry: newBox)
        newBoxNode?.position = position
        
        self.sceneView.scene.rootNode.addChildNode(newBoxNode!)
        
    }
    
//    // Called when tap is detected
//    @objc func handleTap(sender: UITapGestureRecognizer) {
//
//        // Gets the location of the tap and assigns it to a constant
//        let location = sender.location(in: sceneView)
//
//        // Searches for real world objects such as surfaces and filters out flat surfaces
//        let hitTest = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
//
//        // Assigns the most accurate result to a constant if it is non-nil
//        guard let result = hitTest.last else { return }
//
//        // Converts the matrix_float4x4 to an SCNMatrix4 to be used with SceneKit
//        let hitTransform = result.worldTransform
//        let vector = SCNVector3Make(hitTransform.columns.3.x,
//                                    hitTransform.columns.3.y,
//                                    hitTransform.columns.3.z)
//
//        //        let transform = SCNMatrix4.init(result.worldTransform)
//        //
//        //        // Creates an SCNVector3 with certain indexes in the matrix
//        //        let vector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
//
//        // Makes a new sphere with the created method
//        let sphere = newSphere(at: vector)
//
//        // Checks if there is at least one sphere in the array
//        if let first = spheres.first {
//
//            // Adds a second sphere to the array
//            spheres.append(sphere)
//
//            if spheres.count == 2 {
//                measurementLabel.text = "width: \(sphere.distance(to: first)) meters"
//            }
//            if spheres.count == 3 {
//                print(spheres[0])
//                print(spheres[1])
//                print(spheres[2])
//                let boxlen=sphere.findheight(point1: first, point2: spheres[1])
//                let boxwid=first.distance(to: spheres[1])
//                center=sphere.findcenter(point1: first, point2: spheres[1])
//                measurementLabel.text = "width: \(boxwid) meters;\n length:\(boxlen) meters"
//                print(center)
//                let p3 = sphere.findp3(point1: first, point2: spheres[1])
//                print(p3)
//                spheres[2]=newSphere(at: p3)
//                createBox(position: center!, width: boxwid, length: boxlen)
//                heightSlider.isHidden=false
//            }
//
//
//            // If more that two are present...
//            if spheres.count > 3 {
//
//                // Iterate through spheres array
//                for sphere in spheres {
//
//                    // Remove all spheres
//                    sphere.removeFromParentNode()
//                }
//
//                // Remove extraneous spheres
//                spheres = [spheres[3]]
//            }
//
//            // If there are no spheres...
//        } else {
//            // Add the sphere
//            spheres.append(sphere)
//
//        }
//
//        // Iterate through spheres array
//        for sphere in spheres {
//
//            // Add all spheres in the array
//            self.sceneView.scene.rootNode.addChildNode(sphere)
//        }
//    }
    
    // Creates measuring endpoints
    func newSphere(at position: SCNVector3) -> SCNNode {
        
        // Creates an SCNSphere with a radius of 0.4
        let sphere = SCNSphere(radius: 0.005)
        
        // Converts the sphere into an SCNNode
        let node = SCNNode(geometry: sphere)
        
        // Positions the node based on the passed in position
        node.position = position
        
        // Creates a material that is recognized by SceneKit
        let material = SCNMaterial()
        
        // Converts the contents of the PNG file into the material
        material.diffuse.contents = UIColor.orange
        
        // Creates realistic shadows around the sphere
        material.lightingModel = .blinn
        
        // Wraps the newly made material around the sphere
        sphere.firstMaterial = material
        
        // Returns the node to the function
        return node
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        configuration = ARWorldTrackingConfiguration()
        configuration!.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        sceneView.session.run(configuration!, options: [ARSession.RunOptions.removeExistingAnchors,
                                                        ARSession.RunOptions.resetTracking])
        sceneView.debugOptions  = [SCNDebugOptions.showConstraints, SCNDebugOptions.showLightExtents, ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
        
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
        
    }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // add the anchor node only if the plane is not already selected.
        guard !isPlaneSelected else {
            // we don't session to track the anchor for which we don't want to map node.
            sceneView.session.remove(anchor: anchor)
            return nil
        }
        
        var node:  SCNNode?
        if let planeAnchor = anchor as? ARPlaneAnchor {
            node = SCNNode()
            //            let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let planeGeometry = SCNBox(width: CGFloat(planeAnchor.extent.x), height: planeHeight, length: CGFloat(planeAnchor.extent.z), chamferRadius: 0.0)
            planeGeometry.firstMaterial?.diffuse.contents = UIImage(named: "./art.scnassets/floor.png")
            planeGeometry.firstMaterial?.diffuse.wrapS = SCNWrapMode.repeat
            planeGeometry.firstMaterial?.diffuse.wrapT = SCNWrapMode.repeat
            let planeNode = SCNNode(geometry: planeGeometry)
            planeNode.position = SCNVector3Make(planeAnchor.center.x, Float(planeHeight / 2), planeAnchor.center.z)
            //            since SCNPlane is vertical, needs to be rotated -90 degress on X axis to make a plane
            //            planeNode.transform = SCNMatrix4MakeRotation(Float(-CGFloat.pi/2), 1, 0, 0)
            node?.addChildNode(planeNode)
            anchors.append(planeAnchor)
            isPlaneSelected=true
            print(isPlaneSelected)
            DispatchQueue.main.async {
                self.selectedpoint.isHidden=false
                self.view.layoutIfNeeded()
            }

            
        } else {
            // haven't encountered this scenario yet
            print("not plane anchor \(anchor)")
        }
        
        return node
    }
    
    // Called when a new node has been mapped to the given anchor
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        planeNodesCount += 1
        if node.childNodes.count > 0 && planeNodesCount % 2 == 0 {
            node.childNodes[0].geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        }
    }
    
    // Called when a node has been updated with data from the given anchor
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // update the anchor node size only if the plane is not already selected.
        guard !isPlaneSelected else {
            return
        }
        
        if let planeAnchor = anchor as? ARPlaneAnchor {
            if anchors.contains(planeAnchor) {
                if node.childNodes.count > 0 {
                    let planeNode = node.childNodes.first!
                    planeNode.position = SCNVector3Make(planeAnchor.center.x, Float(planeHeight / 2), planeAnchor.center.z)
                    if let plane = planeNode.geometry as? SCNBox {
                        plane.width = CGFloat(planeAnchor.extent.x)
                        plane.length = CGFloat(planeAnchor.extent.z)
                        plane.height = planeHeight
                    }
                }
            }
        }
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
        
        let ac=position-dest1.position
        let ab=dest2.position-dest1.position
        let abunit=ab.normalized
        let ad=abunit*(ac.dotProduct(abunit))
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
        let d=SCNVector3(dest2.position.x,dest1.position.y,dest1.position.z)
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
