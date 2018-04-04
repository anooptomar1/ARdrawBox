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
//    var doubleTapGesture: UITapGestureRecognizer!
//    var rotationGesture: UIRotationGestureRecognizer!


    // Spheres nodes
    var spheres: [SCNNode] = []
    // Measurement label
    var measurementLabel = UILabel()
    
    var focalNode: FocalNode?
    private var screenCenter: CGPoint!
    

    
    //height slider bar


    let planeIdentifiers = [UUID]()
    var anchors = [ARAnchor]()
    var nodes = [SCNNode]()
    
    // keep track of number of anchor nodes that are added into the scene
    var planeNodesCount = 0
    let planeHeight: CGFloat = 0.01
    // set isPlaneSelected to true when user taps on the anchor plane to select.
    var isPlaneSelected = false

    var center : SCNVector3?
    let formatter = NumberFormatter()

    
    
    @IBAction func heightchanged(_ sender: UISlider) {
        let heightd=sender.value
        box.move(side: .top, to: heightd)

    }
    



//
//
//    func createBox(position : SCNVector3,width : CGFloat, length: CGFloat) {
//        newBox = SCNBox(width: width, height: 0.005, length: length, chamferRadius: 0.001)
//        newBoxNode = SCNNode(geometry: newBox)
//        newBoxNode?.position = position
//
//        self.sceneView.scene.rootNode.addChildNode(newBoxNode!)
//
//    }
//




////    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
////
////        let indices: [Int32] = [0, 1]
////
////        let source = SCNGeometrySource(vertices: [vector1, vector2])
////        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
////
////        return SCNGeometry(sources: [source], elements: [element])
////
////    }
//







    
    var box: Box!
    var hitTestPlane: SCNNode!
    var floor: SCNNode!
    
    var currentAnchor: ARAnchor?
    
    struct RenderingCategory: OptionSet {
        let rawValue: Int
        static let reflected = RenderingCategory(rawValue: 1 << 1)//1 shift left by 1 place
        static let planes = RenderingCategory(rawValue: 1 << 2) //1 shift left by 2?
    }
    
    enum InteractionMode {
        case waitingForLocation
        case draggingInitialWidth, draggingInitialLength
        case waitingForFaceDrag, draggingFace(side: Box.Side, dragStart: SCNVector3)

    }
    
    var planesShown: Bool {
        
        get { return RenderingCategory(rawValue: sceneView.pointOfView!.camera!.categoryBitMask).contains(.planes) }
        set {
            var mask = RenderingCategory(rawValue: sceneView.pointOfView!.camera!.categoryBitMask)
            if newValue == true {
                mask.formUnion(.planes)
            } else {
                mask.subtract(.planes)
            }
            sceneView.pointOfView!.camera!.categoryBitMask = mask.rawValue
        }
    }
    
    var mode: InteractionMode = .waitingForLocation {
        didSet {
            switch mode {
            case .waitingForLocation:
//                rotationGesture.isEnabled = false
                
                box.isHidden = true
                box.clearHighlights()
                
                hitTestPlane.isHidden = true
                floor.isHidden = true
                
                planesShown = true
                
            case .draggingInitialWidth, .draggingInitialLength:
//                rotationGesture.isEnabled = true
                
                box.isHidden = false
                box.clearHighlights()
                
                floor.isHidden = false
                
                // Place the hit-test plane flat on the z-axis, aligned with the bottom of the box.
                hitTestPlane.isHidden = false
                hitTestPlane.position = .zero
                hitTestPlane.boundingBox.min = SCNVector3(x: -1000, y: 0, z: -1000)
                hitTestPlane.boundingBox.max = SCNVector3(x: 1000, y: 0, z: 1000)
                
                planesShown = false
                
            case .waitingForFaceDrag:
//                rotationGesture.isEnabled = true
                
                box.isHidden = false
                box.clearHighlights()
                
                floor.isHidden = false
                hitTestPlane.isHidden = true
                
                planesShown = false
            
                
                
            case .draggingFace(let side, let dragStart):
//                rotationGesture.isEnabled = true
                
                box.isHidden = false
                floor.isHidden = false
                
                hitTestPlane.isHidden = false
                hitTestPlane.position = dragStart
                
                planesShown = false
                
                box.highlight(side: side)
                
                // Place the hit-test plane straight through the dragged side, centered at the point on which the drag started.
                // This makes the drag operation act as though you're dragging that exact point on the side to a new location.
                // TODO: the plane should be constrained so that it always rotates to face the camera along the axis that goes through the dragged side.
                switch side.axis {
                case .x:
                    hitTestPlane.boundingBox.min = SCNVector3(x: -1000, y: -1000, z: 0)
                    hitTestPlane.boundingBox.max = SCNVector3(x: 1000, y: 1000, z: 0)
                case .y:
                    hitTestPlane.boundingBox.min = SCNVector3(x: -1000, y: -1000, z: 0)
                    hitTestPlane.boundingBox.max = SCNVector3(x: 1000, y: 1000, z: 0)
                case .z:
                    hitTestPlane.boundingBox.min = SCNVector3(x: 0, y: -1000, z: -1000)
                    hitTestPlane.boundingBox.max = SCNVector3(x: 0, y: 1000, z: 1000)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        screenCenter = view.center
        
        heightSlider.isHidden=true
        
        sceneView.antialiasingMode = .multisampling4X
        sceneView.autoenablesDefaultLighting = true
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        
                // Sets the amount of taps needed to trigger the handler
        tapGesture.numberOfTapsRequired = 1
        

        
//        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        
        sceneView.addGestureRecognizer(panGesture)
        sceneView.addGestureRecognizer(tapGesture)
//        sceneView.addGestureRecognizer(rotationGesture)
        
        box = Box()
        box.isHidden = true
        sceneView.scene.rootNode.addChildNode(box)
        
        // Create an invisible plane used for hit-testing during drag operations.
        // This is a child of the box, so it inherits the box's own transform.
        // It is resized and repositioned within the box depending on what part of the box is being dragged.
        hitTestPlane = SCNNode()
        hitTestPlane.isHidden = true
        box.addChildNode(hitTestPlane)
        
        let floorSurface = SCNFloor()
        floorSurface.reflectivity = 0.2
        floorSurface.reflectionFalloffEnd = 0.05
        floorSurface.reflectionCategoryBitMask = RenderingCategory.reflected.rawValue
        
        // Floor scene reflections are blended with the diffuse color's transparency mask, so if diffuse is transparent then no reflection will be shown.
        // To get around this, we make the floor black and use additive blending so that only the brighter reflection is shown.
        floorSurface.firstMaterial?.diffuse.contents = UIColor.black
        floorSurface.firstMaterial?.writesToDepthBuffer = false
        floorSurface.firstMaterial?.blendMode = .add
        
        floor = SCNNode(geometry: floorSurface)
        floor.isHidden = true
        
        box.addChildNode(floor)
        box.categoryBitMask |= RenderingCategory.reflected.rawValue
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        sceneView.session.run(configuration, options: [ARSession.RunOptions.removeExistingAnchors,
                                                                ARSession.RunOptions.resetTracking])
        ////        sceneView.debugOptions  = [SCNDebugOptions.showConstraints, SCNDebugOptions.showLightExtents, ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
        // Run the view's session
//        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func resetBox() {
        mode = .waitingForLocation
        box.resizeTo(min: .zero, max: .zero)
        currentAnchor = nil
    }
    
    // MARK: - Touch handling
    // Called when tap is detected
    @objc dynamic func handleTap(_ gestureRecognizer: UIPanGestureRecognizer) {
        // Make sure we've found the floor
        guard focalNode != nil else { return }
        switch mode {
        case .waitingForLocation:
            findStartingLocation()
        case .draggingInitialWidth:
            handleInitialWidthDrag()
        case .draggingInitialLength:
            handleInitialLengthDrag()
        case .waitingForFaceDrag:
            findFaceDragLocation(gestureRecognizer)
        default:
            break
            
        }
        
    }
    
    @objc dynamic func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch mode {
//        case .waitingForLocation:
//            findStartingLocation(gestureRecognizer)
//        case .draggingInitialWidth:
//            handleInitialWidthDrag(gestureRecognizer)
//        case .draggingInitialLength:
//            handleInitialLengthDrag(gestureRecognizer)
//        case .waitingForFaceDrag:
//            findFaceDragLocation(gestureRecognizer)
        case .draggingFace:
            handleFaceDrag(gestureRecognizer)
        default:
            break
        }
    }
    
//    @objc dynamic func handleDoubleTap(_ gestureRecognizer: UIPanGestureRecognizer) {
//        resetBox()
//    }
    
    // MARK: Twist-to-rotate gesture handling
    
//    fileprivate var lastRotation = CGFloat(0)
//    @objc dynamic func handleRotation(_ gestureRecognizer: UIRotationGestureRecognizer) {
//        let currentRotation = gestureRecognizer.rotation
//        switch gestureRecognizer.state {
//        case .began:
//            lastRotation = currentRotation
//        case .changed:
//            let rotationDelta = currentRotation - lastRotation
//            lastRotation = currentRotation
//
//            let rotation = SCNQuaternion(radians: -Float(rotationDelta), around: .axisY)
//            let rotationPivot = box.pointInBounds(at: SCNVector3(x: 0.5, y: 0, z: 0.5))
//            let pivotInWorld = box.convertPosition(rotationPivot, to: nil)
//            box.rotate(by: rotation, aroundTarget: pivotInWorld)
//        default:
//            break
//        }
//    }
    
    // MARK: Drag Gesture handling
    func findStartingLocation() {

        // Use real-world ARKit coordinates to determine where to start drawing
        
        
        let hit = realWorldHit(at: screenCenter)
        if let startPos = hit.position, let plane = hit.planeAnchor {
            // Once the user hits a usable real-world plane, switch into line-dragging mode
            box.position = startPos
            currentAnchor = plane
            mode = .draggingInitialWidth
   
        }
        
    }
    func handleInitialWidthDrag() {
        if abs(box.boundingBox.max.x - box.boundingBox.min.x) >= box.minLabelDistanceThreshold {
            // If the box ended up with a usable width, switch to length-dragging mode.
            mode = .draggingInitialLength
        } else {
            // Otherwise, give up on this drag and start again.
            resetBox()
        }

        
        
        
    }
    func handleInitialLengthDrag() {
        
        // Once the box has a usable width and depth, switch to face-dragging mode.
        // Otherwise, stay in length-dragging mode.
        if (box.boundingBox.max.z - box.boundingBox.min.z) >= box.minLabelDistanceThreshold {
            mode = .waitingForFaceDrag
            focalNode?.isHidden=true
            heightSlider.isHidden=false
        }
        
    }
    
//    func findStartingLocation(_ gestureRecognizer: UIPanGestureRecognizer) {
//        switch gestureRecognizer.state {
//        case .began, .changed:
//            // Use real-world ARKit coordinates to determine where to start drawing
//            let touchPos = gestureRecognizer.location(in: sceneView)
//
//            let hit = realWorldHit(at: touchPos)
//            if let startPos = hit.position, let plane = hit.planeAnchor {
//                // Once the user hits a usable real-world plane, switch into line-dragging mode
//                box.position = startPos
//                currentAnchor = plane
//                mode = .draggingInitialWidth
//            }
//        default:
//            break
//        }
//    }
    
//
//
//    func handleInitialWidthDrag(_ gestureRecognizer: UIPanGestureRecognizer) {
//        switch gestureRecognizer.state {
//        case .changed:
//            let touchPos = gestureRecognizer.location(in: sceneView)
//            if let locationInWorld = scenekitHit(at: touchPos, within: hitTestPlane) {
//                // This drags a line out that determines the box's width and its orientation:
//                // The box's front will face 90 degrees clockwise out from the line being dragged.
//                let delta = box.position - locationInWorld
//                let distance = delta.length
//
//                let angleInRadians = atan2(delta.z, delta.x)
//
//                box.move(side: .right, to: distance)
//                box.rotation = SCNVector4(x: 0, y: 1, z: 0, w: -(angleInRadians + Float.pi))
//            }
//        case .ended, .cancelled:
//            if abs(box.boundingBox.max.x - box.boundingBox.min.x) >= box.minLabelDistanceThreshold {
//                // If the box ended up with a usable width, switch to length-dragging mode.
//                mode = .draggingInitialLength
//            } else {
//                // Otherwise, give up on this drag and start again.
//                resetBox()
//            }
//        default:
//            break
//        }
//    }
    
//
//
//
//
//    func handleInitialLengthDrag(_ gestureRecognizer: UIPanGestureRecognizer) {
//        switch gestureRecognizer.state {
//        case .changed:
//            let touchPos = gestureRecognizer.location(in: sceneView)
//            if let locationInWorld = scenekitHit(at: touchPos, within: hitTestPlane) {
//                // Check where the hit vector landed within the box's own coordinate system, which may be rotated.
//                let locationInBox = box.convertPosition(locationInWorld, from: nil)
//
//                // Front side faces toward +z, back side toward -z
//                if locationInBox.z < 0 {
//                    box.move(side: .front, to: 0)
//                    box.move(side: .back, to: locationInBox.z)
//                } else {
//                    box.move(side: .front, to: locationInBox.z)
//                    box.move(side: .back, to: 0)
//                }
//            }
//        case .ended, .cancelled:
//            // Once the box has a usable width and depth, switch to face-dragging mode.
//            // Otherwise, stay in length-dragging mode.
//            if (box.boundingBox.max.z - box.boundingBox.min.z) >= box.minLabelDistanceThreshold {
//                mode = .waitingForFaceDrag
//            }
//        default:
//            break
//        }
//    }
    

    
    
    
//    func findFaceDragLocation(_ gestureRecognizer: UIPanGestureRecognizer) {
//        switch gestureRecognizer.state {
//        case .began, .changed:
//            let touchPos = gestureRecognizer.location(in: sceneView)
//
//            // Test if the user managed to hit a face of the box: if so, transition into dragging that face
//            for (side, node) in box.faces {
//                let hitResults = sceneView.hitTest(touchPos, options: [
//                    .rootNode: node,
//                    .firstFoundOnly: true,
//                    ])
//
//                if let result = hitResults.first {
//                    let coordinatesInBox = box.convertPosition(result.localCoordinates, from: result.node)
//                    box.highlight(side: side)
//                    mode = .draggingFace(side: side, dragStart: coordinatesInBox)
//                    return
//                }
//            }
//        default:
//            break
//        }
//    }
    func findFaceDragLocation(_ gestureRecognizer: UIPanGestureRecognizer) {

        let touchPos = gestureRecognizer.location(in: sceneView)

        // Test if the user managed to hit a face of the box: if so, transition into dragging that face
        for (side, node) in box.faces {
            let hitResults = sceneView.hitTest(touchPos, options: [
                .rootNode: node,
                .firstFoundOnly: true,
                ])
            
            
            if let result = hitResults.first {
                let coordinatesInBox = box.convertPosition(result.localCoordinates, from: result.node)
                box.highlight(side: side)
                mode = .draggingFace(side: side, dragStart: coordinatesInBox)
                return
            }
        }

    }
    
    func handleFaceDrag(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard case let .draggingFace(side, _) = mode else {
            return
        }
        
        switch gestureRecognizer.state {
        case .changed:
            let touchPos = gestureRecognizer.location(in: sceneView)
            if let locationInWorld = scenekitHit(at: touchPos, within: hitTestPlane) {
                // Check where the hit vector landed within the box's own coordinate system, which may be rotated.
                let locationInBox = box.convertPosition(locationInWorld, from: nil)
                
                var distanceForAxis = locationInBox.value(for: side.axis)
                
                // Don't allow the box to be dragged inside-out: stop dragging the side at the point at which it meets its opposite side.
                switch side.edge {
                case .min:
                    distanceForAxis = min(distanceForAxis, box.boundingBox.max.value(for: side.axis))
                case .max:
                    distanceForAxis = max(distanceForAxis, box.boundingBox.min.value(for: side.axis))
                }
                
                box.move(side: side, to: distanceForAxis)
            }
        case .ended, .cancelled:
            mode = .waitingForFaceDrag
        default:
            break
        }
    }
    
    // MARK: - Hit-testing
    
    func scenekitHit(at screenPos: CGPoint, within rootNode: SCNNode) -> SCNVector3? {
        let hits = sceneView.hitTest(screenPos, options: [
            .boundingBoxOnly: true,
            .firstFoundOnly: true,
            .rootNode: rootNode,
            .ignoreChildNodes: true
            ])
        
        return hits.first?.worldCoordinates
    }
    
    func realWorldHit(at screenPos: CGPoint) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView.hitTest(screenPos, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(screenPos, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(screenPos)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
    
    
    // MARK: - ARSCNViewDelegate
    
    
    
    
    // Highlight detected planes in the view with a surface so we can see what the hell we're doing
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // add the anchor node only if the plane is not already selected.
        guard !isPlaneSelected else {
            // we don't session to track the anchor for which we don't want to map node.
            sceneView.session.remove(anchor: anchor)
            return nil
        }
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return nil
        }
        
        let plane = SCNBox(width: CGFloat(planeAnchor.extent.x),
                           height: 0.0001,
                           length: CGFloat(planeAnchor.extent.z), chamferRadius: 0)
        
        if let material = plane.firstMaterial {
            material.lightingModel = .constant
            material.diffuse.contents = UIColor.yellow
            material.transparency = 0.1
            material.writesToDepthBuffer = false
        }
        
        let node = SCNNode(geometry: plane)
        node.categoryBitMask = RenderingCategory.planes.rawValue
        anchors.append(planeAnchor)
        isPlaneSelected=true
        print(isPlaneSelected)
        
//        var node:  SCNNode?
//        if let planeAnchor = anchor as? ARPlaneAnchor {
//            node = SCNNode()
//            //            let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
//            let planeGeometry = SCNBox(width: CGFloat(planeAnchor.extent.x), height: planeHeight, length: CGFloat(planeAnchor.extent.z), chamferRadius: 0.0)
//            planeGeometry.firstMaterial?.diffuse.contents = UIImage(named: "./art.scnassets/floor.png")
//            planeGeometry.firstMaterial?.diffuse.wrapS = SCNWrapMode.repeat
//            planeGeometry.firstMaterial?.diffuse.wrapT = SCNWrapMode.repeat
//            let planeNode = SCNNode(geometry: planeGeometry)
//            planeNode.position = SCNVector3Make(planeAnchor.center.x, Float(planeHeight / 2), planeAnchor.center.z)
//
        return node
    }
        // Called when a node has been updated with data from the given anchor
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, let plane = node.geometry as? SCNBox else {
            return
        }
        // update the anchor node size only if the plane is not already selected.
        guard !isPlaneSelected else {
            return
        }
        
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.length = CGFloat(planeAnchor.extent.z)
        
        // If this anchor is the one the box is positioned relative to, then update the box to match any corrections to the plane's observed position.
        if plane == currentAnchor {
            let oldPos = node.position
            let newPos = SCNVector3.positionFromTransform(planeAnchor.transform)
            let delta = newPos - oldPos
            box.position += delta
        }
        
        node.transform = SCNMatrix4(planeAnchor.transform)
        node.pivot = SCNMatrix4(translationByX: -planeAnchor.center.x, y: -planeAnchor.center.y, z: -planeAnchor.center.z)
//        if let planeAnchor = anchor as? ARPlaneAnchor {
//            if anchors.contains(planeAnchor) {
//                if node.childNodes.count > 0 {
//                    let planeNode = node.childNodes.first!
//                    planeNode.position = SCNVector3Make(planeAnchor.center.x, Float(planeHeight / 2), planeAnchor.center.z)
//                    if let plane = planeNode.geometry as? SCNBox {
//                        plane.width = CGFloat(planeAnchor.extent.x)
//                        plane.length = CGFloat(planeAnchor.extent.z)
//                        plane.height = planeHeight
//                    }
//                }
//            }
//        }
        
        
        
        
        
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
            
            guard let box=box else{return }
            switch(mode){
            case .draggingInitialWidth:

                    if let locationInWorld = scenekitHit(at: screenCenter, within: hitTestPlane) {
                    // This drags a line out that determines the box's width and its orientation:
                    // The box's front will face 90 degrees clockwise out from the line being dragged.
                    let delta = box.position - locationInWorld
                    let distance = delta.length

                    
                    let angleInRadians = atan2(delta.z, delta.x)
                    
                    box.move(side: .right, to: distance)
                    box.rotation = SCNVector4(x: 0, y: 1, z: 0, w: -(angleInRadians + Float.pi))
                                    }
//                    let delta = box.position - focalNode.position
//                    let distance = delta.length
//
//                    let angleInRadians = atan2(delta.z, delta.x)
//
//                    box.move(side: .right, to: distance)
//                    box.rotation = SCNVector4(x: 0, y: 1, z: 0, w: -(angleInRadians + Float.pi))

            case .draggingInitialLength:
                if let locationInWorld = scenekitHit(at: screenCenter, within: hitTestPlane) {
                    // Check where the hit vector landed within the box's own coordinate system, which may be rotated.
                    let locationInBox = box.convertPosition(locationInWorld, from: nil)
                    
                    // Front side faces toward +z, back side toward -z
                    if locationInBox.z < 0 {
                        box.move(side: .front, to: 0)
                        box.move(side: .back, to: locationInBox.z)
                    } else {
                        box.move(side: .front, to: locationInBox.z)
                        box.move(side: .back, to: 0)
                    }
                }

            default: break
            }


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
    
    
    
    

    
    
    
}



