//
//  ViewController.swift
//  MeasureIT
//
//  Created by Arkadiusz Stasczak on 02.04.2018.
//  Copyright © 2018 Arkadiusz Staśczak. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var distanceTextField: UITextView!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var measureSwitch: UISwitch!
    
    
    var box: BoxNode!
    var status: String! = "NIEGOTOWY"
    var startPosition: SCNVector3!
    var distance: Float!
    var trackingState: ARCamera.TrackingState!
    var distanceText:SCNText?
    var textNode:TextNode?
    

    var mode: Mode = .waitingForMeasuring {
        didSet {
            switch mode {
            case .waitingForMeasuring:
                break
            case .measuring:
                box.update(
                    minExtents: SCNVector3Zero, maxExtents: SCNVector3Zero)
                box.isHidden = false
                startPosition = nil
                distance = 0.0
                setText()
            }
        }
    }

    @IBAction func switchEnabled(_ sender: UISwitch) {
        if sender.isOn{
            mode = .measuring
        }
        else{
             mode = .waitingForMeasuring
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        let scene = SCNScene.init()
        sceneView.scene = scene
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.preferredFramesPerSecond = 60
        
        // Konfiguracja sceny
        

        box = BoxNode()
        box.isHidden = true;
        
        // Inicjalizacja dystansu
        distance = 0.0
        sceneView.scene.rootNode.addChildNode(box)
        
        // Inicjalizacja trybu
        mode = .waitingForMeasuring
        setText()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
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
    func setText(){
        var text = getTrackigDescription()
        text += "\nStatus: \(status!)"
        text += "\nOdległość \(String(format:"%.2f cm", distance! * 100.0))"
        
        self.distanceTextField.text = text
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.measure()
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        trackingState = camera.trackingState
    }
}

extension ViewController {
    
    // Tryb
    enum Mode {
        case waitingForMeasuring
        case measuring
    }
    
    // Stan Śledzenia
    func getTrackigDescription() -> String {
        var description = ""
        if let t = trackingState {
            switch(t) {
            case .notAvailable:
                description = "ŚLEDZENIE NIEMOŻLIWE"
            case .normal:
                description =  "ŚLEDZENIE W NORMIE"
            case .limited(let reason):
                switch reason {
                case .excessiveMotion:
                    description =
                    "ŚLEDZENIE OGRANICZONE - Zbyt dużo ruchów aparatem"
                case .insufficientFeatures:
                    description =
                    "ŚLEDZENIE OGRANICZONE - Nie wykryto odpowieniej ilości powierzchni"
                case .initializing:
                    description = "INICJALIZACJA"
                }
            }
        }
        return description
    }
    
    // Funkcja odpowiedzialna za pmiar
    func measure() {
        let screenCenter : CGPoint = CGPoint(
            x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        let planeTestResults = sceneView.hitTest(screenCenter, types: [.existingPlaneUsingExtent])
        
        // Po wykryciu pierwsze powierzchni przez ARKit
        if let result = planeTestResults.first {
            status = "GOTOWY"
            if mode == .measuring {
                status = "MIERZĘ"
                let worldPosition = SCNVector3Make(
                    result.worldTransform.columns.3.x,
                    result.worldTransform.columns.3.y,
                    result.worldTransform.columns.3.z
                )
                if startPosition == nil {
                    startPosition = worldPosition
                    box.position = worldPosition
                }
                box.resizeTo(extent: distance)
                let angleInRadians = calculateAngleInRadians( from: startPosition!, to: worldPosition)
                box.rotation = SCNVector4(x: 0, y: 1, z: 0,w: -(angleInRadians + Float.pi))
                distance = calculateDistance(from: startPosition!, to: worldPosition)
                setTextNode(begin: startPosition, end: worldPosition, angle: angleInRadians)
            }
        }
        setText()
    }
    
    // Ustaw wartość tekstową node'a odpowiedzialnego za wyświetlenie dystansu
    
    func setTextNode(begin: SCNVector3, end: SCNVector3, angle: Float){
        let xPos = (begin.x + end.x)/2.0
        let yPos = (begin.y + end.y)/2.0 + 0.04
        let zPos = (begin.z + end.z)/2.0
        if(self.textNode != nil){
            self.textNode?.removeFromParentNode()
        }
        let position = SCNVector3Make(xPos, yPos, zPos)
        self.textNode = TextNode(String(format:"%.2f cm", distance! * 100.0))
        self.textNode?.rotation = SCNVector4(0 , 1, 0, -(angle + Float.pi))
        self.textNode?.position = position
        self.textNode?.scale = SCNVector3Make(0.2, 0.2, 0.2)
        self.textNode?.font = UIFont(name: "AvenirNext-Bold", size: 0.01)
        self.textNode?.color = .white
        self.sceneView.scene.rootNode.addChildNode(self.textNode!)
    }
    
    
    // Mierzenie odleglosci pomiędzy poczatkiem a obecnym punktem
    func calculateDistance(from: SCNVector3, to: SCNVector3) -> Float {
        let x = from.x - to.x
        let y = from.y - to.y
        let z = from.z - to.z
        return sqrtf( (x * x) + (y * y) + (z * z))
    }
    
    // Mierzenie kąta nachylenia miary
    func calculateAngleInRadians(from: SCNVector3, to: SCNVector3) -> Float {
        let x = from.x - to.x
        let z = from.z - to.z
        return atan2(z, x)
    }
}

