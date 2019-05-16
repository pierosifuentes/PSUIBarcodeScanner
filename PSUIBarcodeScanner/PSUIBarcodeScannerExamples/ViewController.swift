//
//  ViewController.swift
//  PSUIBarcodeScannerExamples
//
//  Created by Piero Sifuentes on 15/3/19.
//  Copyright © 2019 PRSP. All rights reserved.
//

import UIKit
import PSUIBarcodeScanner

class ViewController: UIViewController {

    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var barcodeScannerView: PSUIBarcodeScannerView!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var scannerLogLabel: UILabel!
    
    var willStop: Bool = false {
        didSet {
            if willStop {
                stopButton?.setTitle("Start", for: .normal)
                barcodeScannerView?.stopCapturing()
            } else {
                stopButton?.setTitle("Stop", for: .normal)
                barcodeScannerView?.restartCapturing()
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        barcodeScannerView?.onScanSuccess = { [weak self] (result) in
            if let self = self {
                self.codeLabel?.text = result.value
                self.typeLabel?.text = result.type.rawValue
                self.dateLabel?.text = UIViewController.formatter.string(from: result.date)
                self.scannerLogLabel?.text = "New Value"
                self.scannerLogLabel?.textColor = .green
            }
        }
        
        barcodeScannerView?.onScanFailure = { [weak self] (error) in
            if let self = self {
                self.scannerLogLabel?.text = error.description
                self.scannerLogLabel?.textColor = .red
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearInfoLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        barcodeScannerView?.startCapturing()
    }

    @IBAction func toggleButtonTapped(_ sender: UIButton) {
        willStop.toggle()
    }
    
    @IBAction func clearScannedInfoTapped(_ sender: UIButton) {
        clearInfoLabels()
    }
    
    private func clearInfoLabels() {
        codeLabel?.text = ""
        typeLabel?.text = ""
        dateLabel?.text = ""
        scannerLogLabel?.text = ""
    }
}

extension UIViewController {
    
    static var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        return formatter
    }
}

