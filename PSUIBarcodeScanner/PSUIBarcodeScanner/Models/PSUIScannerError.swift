//
//  PSUIScannerError.swift
//  PSUIBarcodeScanner
//
//  Created by Piero Sifuentes on 15/5/19.
//  Copyright © 2019 PRSP. All rights reserved.
//

import Foundation

public enum PSUIScannerError {
    case cameraRestricted
    case invalidMetadata
    case sameBarcode
    case unsupportedBarcode
    case barcodeOutOfBounds
    
    public var description: String {
        switch self {
        case .cameraRestricted:
            return "There's no access to the camera"
        case .invalidMetadata:
            return "Got invalid metadata scanning a barcode"
        case .sameBarcode:
            return "Reading the same barcode again"
        case .unsupportedBarcode:
            return "Got unsupported barcode"
        case .barcodeOutOfBounds:
            return "Barcode is outside of scanning bounds"
        }
    }
}
