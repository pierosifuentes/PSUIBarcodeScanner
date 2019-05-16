//
//  PSUIBarcodeScannerView.swift
//  PSUIBarcodeScanner
//
//  Created by Piero Sifuentes on 15/3/19.
//  Copyright © 2019 PRSP. All rights reserved.
//

import UIKit
import AVFoundation

public protocol PSUIBarcodeScannerViewDelegate: class {
    func barcodeScannerView(_ scanner: PSUIBarcodeScannerView, didScan barcode: PSUIScannerResponse)
    func barcodeScannerView(_ scanner: PSUIBarcodeScannerView, didFailBy error: PSUIScannerError)
}

open class PSUIBarcodeScannerView: UIView {
    
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastResult: PSUIScannerResponse?
    private var highlightView: UIView = UIView()
    private var currentCamera: PSUIScannerCamera?
    public var isOneTimeSearch: Bool = false
    public var canRescanSameBarcode: Bool = true
    public var shouldScanOnLaunch: Bool = true
    public var shouldIgnoreResults: Bool = false
    public var onScanSuccess: ((PSUIScannerResponse) -> Void)?
    public var onScanFailure: ((PSUIScannerError) -> Void)?
    public var allowedMetadata: [AVMetadataObject.ObjectType]?
    public var logger: PSUIScannerLogger = PSUIScannerLogger()
    public var barcodeLineDetectionColor: UIColor = UIColor.green
    public var barcodeErrorLineDetectionColor: UIColor = UIColor.red
    public var barcodeRepetedLineDetectionColor: UIColor = UIColor.yellow
    public weak var delegate: PSUIBarcodeScannerViewDelegate?
    
    // MARK: - IBOutlets
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        if shouldScanOnLaunch {
            startCapturing()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        if shouldScanOnLaunch {
            startCapturing()
        }

    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
        if shouldScanOnLaunch {
            startCapturing()
        }
    }
    
    private func setupUI() {
        isUserInteractionEnabled = false
        clipsToBounds = true
        backgroundColor = .black
        highlightView.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.flexibleTopMargin.rawValue | UIView.AutoresizingMask.flexibleBottomMargin.rawValue | UIView.AutoresizingMask.flexibleLeftMargin.rawValue | UIView.AutoresizingMask.flexibleRightMargin.rawValue)
        highlightView.layer.borderColor = barcodeLineDetectionColor.cgColor
        highlightView.layer.borderWidth = 3

    }
    
    public func startCapturing(inputCamera: PSUIScannerCamera = .rear) {
        #if !targetEnvironment(simulator)
        guard let _ = UIApplication.camaraUsage else {
            logger.e("Camara usage was not setup on plist")
            return
        }
        AVCaptureDevice.authorizeVideo { (authStatus) in
            switch authStatus {
            case .justAuthorized, .alreadyAuthorized: break // if it has grant access

            case .justDenied, .alreadyDenied, .restricted:
                if self.delegate != nil {
                    self.delegate?.barcodeScannerView(self, didFailBy: PSUIScannerError.cameraRestricted)
                } else {
                    self.onScanFailure?(PSUIScannerError.cameraRestricted)
                }
                self.logger.w(PSUIScannerError.cameraRestricted.description)
            }
        }
        let session = AVCaptureSession()
        guard let device = inputCamera.device else {
            logger.e("Failed to get the camera device")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = allowedMetadata ?? AVMetadataObject.ObjectType.defaultTypes
            
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewLayer?.contentsGravity = .resizeAspectFill
            previewLayer?.connection?.videoOrientation = .portrait
            previewLayer?.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            if let previewLayer = previewLayer {
                layer.insertSublayer(previewLayer, at: 0)
            }
            
            session.startRunning()
            self.session = session
            if !subviews.contains(highlightView) {
                addSubview(highlightView)
            }
        } catch {
            logger.e(error)
        }
        
        #endif
    }
    
    private func endCapturing() {
        #if !targetEnvironment(simulator)
        guard let session = session else {
            return
        }
        for input in session.inputs {
            session.removeInput(input)
        }
        for output in session.outputs {
            session.removeOutput(output)
        }
        session.stopRunning()
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        self.session = nil
        highlightView.removeFromSuperview()
        #endif
    }
    
    public func stopCapturing() {
        #if !targetEnvironment(simulator)
        if let session = session, session.isRunning {
            session.stopRunning()
        } else {
            logger.w("There's no active session to be stopped")
        }
        #endif
    }
    
    public func restartCapturing() {
        #if !targetEnvironment(simulator)
        if let session = session, !session.isRunning {
            session.startRunning()
        } else {
            logger.w("There's no active session, use startCapturing instead of restartCapturing")
        }
        #endif
    }
    
}

extension PSUIBarcodeScannerView: AVCaptureMetadataOutputObjectsDelegate {
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        var highlightViewRect = CGRect.zero
        guard !shouldIgnoreResults, let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let code = metadata.stringValue, let transformedResult = previewLayer?.transformedMetadataObject(for: metadata) else {
            highlightView.frame = highlightViewRect
            highlightView.layer.borderColor = barcodeErrorLineDetectionColor.cgColor
            bringSubviewToFront(highlightView)
            if delegate != nil {
                delegate?.barcodeScannerView(self, didFailBy: PSUIScannerError.invalidMetadata)
            } else {
                onScanFailure?(PSUIScannerError.invalidMetadata)
            }
            logger.i(PSUIScannerError.invalidMetadata)
            return
        }

        let newResult = PSUIScannerResponse(value: code, type: PSUIMetadataObjectType.from(objectType: metadata.type, code: code), date: Date())
        
        if !canRescanSameBarcode, let last = lastResult, last.value == code {
            highlightView.frame = highlightViewRect
            highlightView.layer.borderColor = barcodeRepetedLineDetectionColor.cgColor
            bringSubviewToFront(highlightView)
            if delegate != nil {
                delegate?.barcodeScannerView(self, didFailBy: PSUIScannerError.sameBarcode)
            } else {
                onScanFailure?(PSUIScannerError.sameBarcode)
            }
            logger.i(PSUIScannerError.sameBarcode.description + " " + last.value)
            return
        }
        guard !isOneTimeSearch, let _ = lastResult else {
            return
        }
        if let containsBarcode = previewLayer?.bounds.contains(transformedResult.bounds), containsBarcode {
            let rect = CGRect(x: transformedResult.bounds.origin.x, y: transformedResult.bounds.origin.y, width: transformedResult.bounds.size.width, height: transformedResult.bounds.size.height)
            highlightViewRect = rect
            highlightView.layer.borderColor = barcodeLineDetectionColor.cgColor
            lastResult = newResult
            if delegate != nil {
                delegate?.barcodeScannerView(self, didScan: newResult)
            } else {
                onScanSuccess?(newResult)
            }
            logger.d(newResult)
        } else {
            highlightViewRect = CGRect.zero
            if delegate != nil {
                delegate?.barcodeScannerView(self, didFailBy: PSUIScannerError.barcodeOutOfBounds)
            } else {
                onScanFailure?(PSUIScannerError.barcodeOutOfBounds)
            }
            logger.i(PSUIScannerError.barcodeOutOfBounds.description)
        }
        highlightView.frame = highlightViewRect
        bringSubviewToFront(highlightView)
    }
    
}

public extension PSUIScannerCamera {
    
    var device: AVCaptureDevice? {
        switch self {
        case .front:
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        case .rear:
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
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
        case .ean13, .upca:
            return AVMetadataObject.ObjectType.ean13
        case .ean8:
            return AVMetadataObject.ObjectType.ean8
        case .upce:
            return AVMetadataObject.ObjectType.upce
        case .face:
            return AVMetadataObject.ObjectType.face
        case .interleaved2of5:
            return AVMetadataObject.ObjectType.interleaved2of5
        case .itf14:
            return AVMetadataObject.ObjectType.itf14
        case .unsupported:
            return nil
        }
    }
    
    static func from(objectType: AVMetadataObject.ObjectType, code: String) -> PSUIMetadataObjectType {
        switch objectType {
        case .code39:
            return PSUIMetadataObjectType.code39
        case .code93:
            return PSUIMetadataObjectType.code93
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
        case .ean13:
            // UPC-A is an EAN-13 barcode with a zero prefix.
            // See: https://stackoverflow.com/questions/22767584/ios7-barcode-scanner-api-adds-a-zero-to-upca-barcode-format
            if code.hasPrefix("0") {
                return PSUIMetadataObjectType.upca
            } else {
                return PSUIMetadataObjectType.ean13
            }
        case .ean8:
            return PSUIMetadataObjectType.ean8
        case .upce:
            return PSUIMetadataObjectType.upce
        case .face:
            return PSUIMetadataObjectType.face
        case .interleaved2of5:
            return PSUIMetadataObjectType.interleaved2of5
        case .itf14:
            return PSUIMetadataObjectType.itf14
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

private extension PSUIScannerCamera {
    
    enum PSUIScannerCameraError: Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
}

public extension AVMetadataObject.ObjectType {
    
    public static var defaultTypes = [
        AVMetadataObject.ObjectType.aztec,
        AVMetadataObject.ObjectType.code128,
        AVMetadataObject.ObjectType.code39,
        AVMetadataObject.ObjectType.code39Mod43,
        AVMetadataObject.ObjectType.code93,
        AVMetadataObject.ObjectType.dataMatrix,
        AVMetadataObject.ObjectType.ean13,
        AVMetadataObject.ObjectType.ean8,
        AVMetadataObject.ObjectType.face,
        AVMetadataObject.ObjectType.interleaved2of5,
        AVMetadataObject.ObjectType.itf14,
        AVMetadataObject.ObjectType.pdf417,
        AVMetadataObject.ObjectType.qr,
        AVMetadataObject.ObjectType.upce
    ]
}
