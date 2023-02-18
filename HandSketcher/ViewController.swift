//
//  ViewController.swift
//  HandSketcher
//
//  Created by Prasanna adithan on 19/01/23.
//

import Cocoa
import Vision
import AVFoundation

class ViewController: NSViewController{
    // STores the detected fingertip points
    var fingerTips : [CGPoint] = []
    private var session : AVCaptureSession!
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedOutput" , qos: .userInteractive)
    private var device : AVCaptureDevice!
    private let request = VNDetectHumanHandPoseRequest()
    private var previewLayer : AVCaptureVideoPreviewLayer!
    private var pointsPath = NSBezierPath()
    private var overlayLayer = CAShapeLayer()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //1)session
        session = AVCaptureSession()
        //2) Identifying the device
        device = AVCaptureDevice.default(for: .video)
        print("Device found:",device!)
        
        //3) Setting up the capture device input
        let device_input = try! AVCaptureDeviceInput(device: device)
        print("huhu",device_input)
        
        request.maximumHandCount = 1
        
        // 4) Adding the device_input to the session
        if session.canAddInput(device_input){
            session.addInput(device_input)
        }
        
        // 5) Setting up the output for the session
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        // 6) Adding the output to the session
        
        if session.canAddOutput(videoOutput){
            session.addOutput(videoOutput)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            print("Added")
        }
        
        
        //7) Setting up the previewLayer for viewing the camera feed
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = view.bounds
        overlayLayer.fillColor = #colorLiteral(red: 0.9999018312, green: 1, blue: 0.9998798966, alpha: 0).cgColor
        view.layer = previewLayer
        view.wantsLayer = true
        view.layer?.addSublayer(overlayLayer)
        
        
        session.startRunning()
        
        
        // Do any additional setup after loading the view.
    }
    
    func process_points (points: [CGPoint],color: NSColor){
        for point in points{
            pointsPath.move(to: point)
            pointsPath.appendArc(withCenter: NSPointFromCGPoint(point), radius: 5, startAngle: 0, endAngle: 2 * .pi,clockwise: true)
            
        }
        overlayLayer.fillColor = color.cgColor
        overlayLayer.path = pointsPath.cgPath
                    
        
    }
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
extension NSBezierPath {
    
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo: path.move(to: points[0])
            case .lineTo: path.addLine(to: points[0])
            case .curveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath: path.closeSubpath()
       
            @unknown default:
                fatalError("Unknown!")
            }
        }
        return path
    }
    
}
extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate{
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer,options: [:])
        
        do {
            // 2
            try handler.perform([request])
            
            // 3
            guard
                let results = request.results,
                !results.isEmpty
            else {
                return
            }
            
            var recognizedPoints : [VNRecognizedPoint] = []
            try results.forEach { observation in
                let fingers = try observation.recognizedPoints(.all)
                if let thumbTipPoint = fingers[.thumbTip]{
                    recognizedPoints.append(thumbTipPoint)
                }
                if let indexTipPoint = fingers[.indexTip] {
                    recognizedPoints.append(indexTipPoint)
                }
                if let middleTipPoint = fingers[.middleTip] {
                    recognizedPoints.append(middleTipPoint)
                }
                if let ringTipPoint = fingers[.ringTip] {
                    recognizedPoints.append(ringTipPoint)
                }
                if let littleTipPoint = fingers[.littleTip] {
                    recognizedPoints.append(littleTipPoint)
                }
            }
            fingerTips = recognizedPoints.filter({
                $0.confidence > 0.9
            })
            .map({CGPoint(x: $0.location.x, y: 1-$0.location.y)})
            print(fingerTips)
            //Vision coordinates to AV Foundation co ordinates conversion
        }
        catch {
            // 4
            session?.stopRunning()
          }

    }
}



