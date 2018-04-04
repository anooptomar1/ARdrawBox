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
//add words to it
//set bounding box instead of drawing a box
//remove focal node after 3 points are drawn


import UIKit
import SceneKit
import ARKit



class ViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - Interface Builder Connections

    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var searchingLabel: UILabel!
    
    @IBOutlet weak var heightSlider: UISlider!
    
    var panGesture: UIPanGestureRecognizer!
    var doubleTapGesture: UITapGestureRecognizer!
    var rotationGesture: UIRotationGestureRecognizer!


    // Spheres nodes
    var spheres: [SCNNode] = []
    // Measurement label
    var measurementLabel = UILabel()
    
    var focalNode: FocalNode?
    private var screenCenter: CGPoint!
    

    
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
    

    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
       initiatelabel()
        screenCenter = view.center

        
        heightSlider.isHidden=true
        
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        
        // Creates a tap handler and then sets it to a constant
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))

        // Sets the amount of taps needed to trigger the handler
//        tapRecognizer.numberOfTapsRequired = 1

        // Adds the handler to the scene view
        sceneView.addGestureRecognizer(tapRecognizer)
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
    

    func createBox(position : SCNVector3,width : CGFloat, length: CGFloat) {
        newBox = SCNBox(width: width, height: 0.005, length: length, chamferRadius: 0.001)
        newBoxNode = SCNNode(geometry: newBox)
        newBoxNode?.position = position
        
        self.sceneView.scene.rootNode.addChildNode(newBoxNode!)
        
    }
    
    // Called when tap is detected
    @objc func handleTap(sender: UITapGestureRecognizer) {
        // Make sure we've found the floor
        guard focalNode != nil else { return }
        
        // See if we tapped on a plane where a model can be placed
        let results = sceneView.hitTest(screenCenter, types: .existingPlane)
        guard let transform = results.last?.worldTransform else { return }
        
        // Find the position to place the model
        let position = float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        let vector = SCNVector3Make(transform.columns.3.x,
                                    transform.columns.3.y,
                                    transform.columns.3.z)
        

        
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
                
                measurementLabel.text = "width: "+formatter.string(from: sphere.distance(to: first) as NSNumber)!+"m"
            }
            if spheres.count == 3 {
                print(spheres[0])
                print(spheres[1])
                print(spheres[2])
                
                
                let boxlen=sphere.findheight(point1: first, point2: spheres[1]).length
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

                
            }
            
            
            // If more that three are present...
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
//        sceneView.debugOptions  = [SCNDebugOptions.showConstraints, SCNDebugOptions.showLightExtents, ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
        
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
//    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
//
//        let indices: [Int32] = [0, 1]
//
//        let source = SCNGeometrySource(vertices: [vector1, vector2])
//        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
//
//        return SCNGeometry(sources: [source], elements: [element])
//
//    }

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

            
        } else {
            // haven't encountered this scenario yet
            print("not plane anchor \(anchor)")
        }
        
        return node
    }
    
    // Called when a new node has been mapped to the given anchor
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // If we have already created the focal node we should not do it again
        guard focalNode == nil else { return }
        
        // Create a new focal node
        let node = FocalNode()
        
        // Add it to the root of our current scene
        sceneView.scene.rootNode.addChildNode(node)
        
        // Store the focal node
        self.focalNode = node
        
        // Hide the label (making sure we're on the main thread)
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.searchingLabel.alpha = 0.0
            }, completion: { _ in
                self.searchingLabel.isHidden = true
            })
        }

        
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
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // If we haven't established a focal node yet do not update
        guard let focalNode = focalNode else { return }
        
        // Determine if we hit a plane in the scene
        let hit = sceneView.hitTest(screenCenter, types: .existingPlane)
        
        // Find the position of the first plane we hit
        guard let positionColumn = hit.first?.worldTransform.columns.3 else { return }
        
        // Update the position of the node
        focalNode.position = SCNVector3(x: positionColumn.x, y: positionColumn.y, z: positionColumn.z)
    }

    
    
    
}



