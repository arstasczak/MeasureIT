//
//  BoxNode.swift
//  MeasureIT
//
//  Created by Arkadiusz Stasczak on 02.04.2018.
//  Copyright © 2018 Arkadiusz Staśczak. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class BoxNode: SCNNode {
    lazy var box: SCNNode = makeBox()
    
    override init() {
        super.init()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // Stworz box
    func makeBox() -> SCNNode {
        let box = SCNBox(
            width: 0.01, height: 0.001, length: 0.01, chamferRadius: 0
        )
        return convertToNode(geometry: box)
    }
    // Konwersja na Node czytany przez ARKit
    func convertToNode(geometry: SCNGeometry) -> SCNNode {
        for material in geometry.materials {
            material.lightingModel = .constant
            material.diffuse.contents = UIImage(named: "ruler")
            material.diffuse.contentsTransform = SCNMatrix4MakeScale(640, 10, 0)
            material.diffuse.wrapT = .repeat
            material.diffuse.wrapS = .repeat
            material.isDoubleSided = false
        }
        let node = SCNNode(geometry: geometry)
        self.addChildNode(node)
        return node
    }
    
    func resizeTo(extent: Float) {
        var (min, max) = boundingBox
        max.x = extent
        update(minExtents: min, maxExtents: max)
    }
    
    func update(minExtents: SCNVector3, maxExtents: SCNVector3) {
        guard let scnBox = box.geometry as? SCNBox else {
            fatalError("Geometry is not SCNBox")
        }
        
        // Ustaw granice boxa
        let absMin = SCNVector3(
            x: min(minExtents.x, maxExtents.x),
            y: min(minExtents.y, maxExtents.y),
            z: min(minExtents.z, maxExtents.z)
        )
        let absMax = SCNVector3(
            x: max(minExtents.x, maxExtents.x),
            y: max(minExtents.y, maxExtents.y),
            z: max(minExtents.z, maxExtents.z)
        )
        
        // Ustaw wartosci
        boundingBox = (absMin, absMax)
        // Oblicz długość
        let size = absMax - absMin
        // Weź wartośc bezwzględną
        let absDistance = CGFloat(abs(size.x))
        // Dlugosc boxa to ta wartosc
        scnBox.width = absDistance
        let offset = size.x * 0.5
        let vector = SCNVector3(x: absMin.x, y: absMin.y, z: absMin.z)
        box.position = vector + SCNVector3(x: offset, y: 0, z: 0)
        let scaleX = (Float(scnBox.width)  / 0.30).rounded()
        scnBox.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(scaleX, 0, 0)

        
    }
}

// Przeciażenie operatorów + i - dla wektorów
func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(
        left.x + right.x, left.y + right.y, left.z + right.z
    )
}
func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(
        left.x - right.x, left.y - right.y, left.z - right.z
    )
}
