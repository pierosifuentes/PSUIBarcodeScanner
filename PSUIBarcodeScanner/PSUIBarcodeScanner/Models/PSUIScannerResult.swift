//
//  ScannerResult.swift
//  PSUIBarcodeScanner
//
//  Created by Piero Sifuentes on 15/3/19.
//  Copyright © 2019 PRSP. All rights reserved.
//

public enum PSUIMetadataObjectType: String {
    case code39, code39Mod43, eAN13Code, eAN8Code, code93, code128, pdf417, qr, aztec, dataMatrix, uPCECode, unsupported
    public static var all: [PSUIMetadataObjectType] = [.code39, .code39Mod43, .eAN13Code, eAN8Code, .code93, .code128, .pdf417, .qr, aztec, dataMatrix, uPCECode]
}

public struct PSUIScannerResult {
    public let value: String, type: PSUIMetadataObjectType, date: Date
}


