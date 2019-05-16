//
//  ScannerResult.swift
//  PSUIBarcodeScanner
//
//  Created by Piero Sifuentes on 15/3/19.
//  Copyright © 2019 PRSP. All rights reserved.
//

public enum PSUIMetadataObjectType: String {
    case code39, code39Mod43, ean8, ean13, code93, code128, pdf417, qr, aztec, dataMatrix, upce, face, interleaved2of5, itf14, upca, unsupported
    public static var all: [PSUIMetadataObjectType] = [.code39, .code39Mod43, .ean8, .ean13, .code93, .code128, .pdf417, .qr, .aztec, .dataMatrix, .upce, .face, .interleaved2of5, .itf14, .upca]
}

public struct PSUIScannerResponse {
    public let value: String, type: PSUIMetadataObjectType, date: Date
    
    public init(value: String, type: PSUIMetadataObjectType, date: Date) {
        self.type = type
        self.date = date
        if type == .upca {
            self.value = String(value.dropFirst())
        } else {
            self.value = value
        }
    }
}
