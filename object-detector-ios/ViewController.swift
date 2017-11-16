//
//  ViewController.swift
//  object-detector-ios
//
//  Created by Darius Vilcinskis on 14/11/2017.
//  Copyright © 2017 Darius Vilcinskis. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController {
    
    //MARK: outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var precisionLabel: UILabel!
    @IBOutlet weak var innerView: UIView!
    
    //MARK: private
    private var formerItem = ""
    
    var synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        innerView.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video"))
        captureSession.addOutput(dataOutput)
    }
}
    
extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        let request = VNCoreMLRequest(model: model) {
            (finished, err) in
            
            guard let results = finished.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }
            
            let identifierName = String(firstObservation.identifier.split(separator: ",").first!)

            print (identifierName)
            
            if firstObservation.confidence > 0.3 && self.formerItem != identifierName && !self.synth.isSpeaking{
                DispatchQueue.main.async(execute: {
                self.nameLabel.text = identifierName
                self.precisionLabel.text =
                    firstObservation.confidence.description
                })
                
                if firstObservation.confidence > 0.8 {
                    self.myUtterance = AVSpeechUtterance(string: "this is a fucking \(identifierName)")
                } else if (firstObservation.confidence > 0.5) {
                    self.myUtterance = AVSpeechUtterance(string: "this is probably a \(identifierName)")
                } else {
                    self.myUtterance = AVSpeechUtterance(string: "maybe this is a \(identifierName)")
                }
                self.synth.speak(self.myUtterance)
                
                self.formerItem = identifierName
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}

