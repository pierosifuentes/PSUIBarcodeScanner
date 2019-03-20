//
//  PSUIBarcodeScannerView.swift
//  PSUIBarcodeScanner
//
//  Created by Piero Sifuentes on 15/3/19.
//  Copyright © 2019 PRSP. All rights reserved.
//

import UIKit
import AVFoundation

open class PSUIBarcodeScannerView: UIView {
    
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastResult: PSUIScannerResult?
    private var highlightView: UIView = UIView()
    public var isOneTimeSearch: Bool = true
    public var canRescanSameBarcode: Bool = true
    public var scanOnLaunch: Bool = true
    public var shouldIgnoreResults: Bool = false
    public var scanningTimeInterval: TimeInterval = 5
    public var onScanSuccess: ((PSUIScannerResult) -> Void)?
    public var onScanFailure: ((String) -> Void)?
    
    // MARK: - IBOutlets
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        if self.scanOnLaunch {
            self.startCapturing(on: self)
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupUI()
    }
    
    private func setupUI() {
        self.isUserInteractionEnabled = false
        self.backgroundColor = .black
        self.highlightView.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.flexibleTopMargin.rawValue | UIView.AutoresizingMask.flexibleBottomMargin.rawValue | UIView.AutoresizingMask.flexibleLeftMargin.rawValue | UIView.AutoresizingMask.flexibleRightMargin.rawValue)
        self.highlightView.layer.borderColor = UIColor.green.cgColor
        self.highlightView.layer.borderWidth = 3
        self.addSubview(self.highlightView)

    }
    
    private func startCapturing(on view: UIView?, inputCamera: PSUIScannerCamera = .rear) {
        #if !targetEnvironment(simulator)
        guard let _ = UIApplication.camaraUsage else {
            //TODO: LOG MANAGER
            print("\nCamara usage was not setup on plist")
            return
        }
        AVCaptureDevice.authorizeVideo { (authStatus) in
            switch authStatus {
            case .justAuthorized, .alreadyAuthorized:
                let session = AVCaptureSession()
                guard let device = inputCamera.device else {
                    //TODO: LOG MANAGER
                    print("\nFailed to get the camera device")
                    return
                }
                do {
                    try! device.lockForConfiguration()
                    device.focusMode = .continuousAutoFocus
                    device.autoFocusRangeRestriction = .far
                    device.unlockForConfiguration()
                    let input = try AVCaptureDeviceInput(device: device)
                    let output = AVCaptureMetadataOutput()
                    if session.canSetSessionPreset(AVCaptureSession.Preset.high) {
                        session.sessionPreset = AVCaptureSession.Preset.high //TODO
                    }
                    if session.canAddInput(input) {
                        session.addInput(input)
                    }
                    if session.canAddOutput(output) {
                        session.addOutput(output)
                    }
                    output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                    output.metadataObjectTypes = self.defaultMetadata //TODO
                    
                    self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
                    self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    self.previewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait //TODO
                    DispatchQueue.main.async {
                        self.previewLayer?.frame = view?.frame ?? self.frame
                        if let previewLayer = self.previewLayer {
                            self.layer.addSublayer(previewLayer)
                        }
                    }
                    session.startRunning()
                    self.session = session
                } catch {
                    //TODO: LOG MANAGER
                    print("\nFailed to capture barcode: \(error)")
                }
            case .justDenied, .alreadyDenied, .restricted:
                //TODO: LOG MANAGER
                print("\nNOT AUTHORIZED TO USE CAMERA")
            }
        }
        
        #endif
    }
    
    private func endCapturing() {
        #if !targetEnvironment(simulator)
        guard let session = self.session else {
            return
        }
        for input in session.inputs {
            session.removeInput(input)
        }
        for output in session.outputs {
            session.removeOutput(output)
        }
        self.session?.stopRunning()
        self.previewLayer?.removeFromSuperlayer()
        self.previewLayer = nil
        self.session = nil
        #endif
    }
    
    public func stopCapturing() {
        #if !targetEnvironment(simulator)
        if let session = self.session, session.isRunning {
            session.stopRunning()
        } else {
            //TODO: LOG MANAGER
            print("\nThere's no active session to be stopped")
        }
        #endif
    }
    
    public func restartCapturing() {
        #if !targetEnvironment(simulator)
        if let session = self.session, session.isInterrupted {
            session.startRunning()
        } else {
            //TODO: LOG MANAGER
            print("\nThere's no active session, use startCapturing instead of restartCapturing")
        }
        #endif
    }
    
}

extension PSUIBarcodeScannerView: AVCaptureMetadataOutputObjectsDelegate {
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        var highlightViewRect = CGRect.zero
        guard let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let code = metadata.stringValue, let transformedResult = self.previewLayer?.transformedMetadataObject(for: metadata) else {
            //TODO: LOG MANAGER
            print("\nNo barcode was detected")
            self.highlightView.frame = highlightViewRect
            self.bringSubviewToFront(self.highlightView)
            self.onScanFailure?("No barcode was detected")
            return
        }
        print("\nMedia time")
        print(metadata.time)
       
        
        let newResult = PSUIScannerResult(value: code, type: PSUIMetadataObjectType.from(objectType: metadata.type), date: Date())
        
        if !self.canRescanSameBarcode, let last = self.lastResult, last.value == code {
            print("\nReading the same barcode again")
            self.highlightView.frame = highlightViewRect
            self.bringSubviewToFront(self.highlightView)
            self.onScanFailure?("Reading the same barcode again")
            return
        }
        
        if self.defaultMetadata.contains(metadata.type), let containsBarcode = self.previewLayer?.bounds.contains(transformedResult.bounds), containsBarcode {
            let rect = CGRect(x: transformedResult.bounds.origin.x, y: transformedResult.bounds.origin.y - 50, width: transformedResult.bounds.size.width, height: transformedResult.bounds.size.height + 50)
            highlightViewRect = rect
            self.lastResult = newResult
            self.onScanSuccess?(newResult)
            //TODO: LOG MANAGER
            print("\n")
            print(newResult)
            
        } else {
            highlightViewRect = CGRect.zero
            //TODO: LOG MANAGER
            self.onScanFailure?("Got unsupported barcode or it's not within the preview bounds")
            print("\nGot unsupported barcode or it's not within the preview bounds")
        }
        self.highlightView.frame = highlightViewRect
        self.bringSubviewToFront(self.highlightView)
    }
    
}

public extension PSUIBarcodeScannerView {
    
    var defaultMetadata: [AVMetadataObject.ObjectType] {
        return [AVMetadataObject.ObjectType.code39, AVMetadataObject.ObjectType.code93, AVMetadataObject.ObjectType.code128, AVMetadataObject.ObjectType.pdf417, AVMetadataObject.ObjectType.qr]
    }
    
}

public extension PSUIScannerCamera {
    
    var device: AVCaptureDevice? {
        switch self {
        case .front:
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        case .rear:
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
        }
    }
}

public extension PSUIMetadataObjectType {
    
    var avObjectType: AVMetadataObject.ObjectType? {
        switch self {
        case .code39:
            return AVMetadataObject.ObjectType.code39
        case .code93:
            return AVMetadataObject.ObjectType.code93
        case .code128:
            return AVMetadataObject.ObjectType.code128
        case .pdf417:
            return AVMetadataObject.ObjectType.pdf417
        case .qr:
            return AVMetadataObject.ObjectType.qr
        case .aztec:
            return AVMetadataObject.ObjectType.aztec
        case .code39Mod43:
            return AVMetadataObject.ObjectType.code39Mod43
        case .dataMatrix:
            return AVMetadataObject.ObjectType.dataMatrix
        case .unsupported:
            return nil
        case .eAN13Code:
            return AVMetadataObject.ObjectType.ean13
        case .eAN8Code:
            return AVMetadataObject.ObjectType.ean8
        case .uPCECode:
            return AVMetadataObject.ObjectType.upce
        }
    }
    
    static func from(objectType: AVMetadataObject.ObjectType) -> PSUIMetadataObjectType {
        switch objectType {
        case .code39:
            return PSUIMetadataObjectType.code39
        case .code128:
            return PSUIMetadataObjectType.code128
        case .pdf417:
            return PSUIMetadataObjectType.pdf417
        case .qr:
            return PSUIMetadataObjectType.qr
        case .aztec:
            return PSUIMetadataObjectType.aztec
        case .code39Mod43:
            return PSUIMetadataObjectType.code39Mod43
        case .dataMatrix:
            return PSUIMetadataObjectType.dataMatrix
        default:
            return PSUIMetadataObjectType.unsupported
        }
    }
}

private extension AVCaptureDevice {
    
    enum AuthorizationStatus {
        case justDenied, alreadyDenied, restricted, justAuthorized, alreadyAuthorized
    }
    
    class func authorizeVideo(completion: ((AuthorizationStatus) -> Void)?) {
        AVCaptureDevice.authorize(mediaType: AVMediaType.video, completion: completion)
    }
    
    private class func authorize(mediaType: AVMediaType, completion: ((AuthorizationStatus) -> Void)?) {
        let status = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch status {
        case .authorized:
            completion?(.alreadyAuthorized)
        case .denied:
            completion?(.alreadyDenied)
        case .restricted:
            completion?(.restricted)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: mediaType, completionHandler: { (granted) in
                DispatchQueue.main.async {
                    if(granted) {
                        completion?(.justAuthorized)
                    }
                    else {
                        completion?(.justDenied)
                    }
                }
            })
        }
    }
}

private extension UIApplication {
    static var camaraUsage: String? {
        return Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String
    }
}
