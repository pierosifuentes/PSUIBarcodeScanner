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
                self.stopButton?.setTitle("Start", for: .normal)
                self.barcodeScannerView?.stopCapturing()
            } else {
                self.stopButton?.setTitle("Stop", for: .normal)
                self.barcodeScannerView?.restartCapturing()
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.barcodeScannerView?.onScanSuccess = { [weak self] (result) in
            if let strongSelf = self {
                strongSelf.codeLabel?.text = result.value
                strongSelf.typeLabel?.text = result.type.rawValue
                strongSelf.dateLabel?.text = UIViewController.formatter.string(from: result.date)
                strongSelf.scannerLogLabel?.text = "New Value"
                strongSelf.scannerLogLabel?.textColor = .green
            }
        }
        
        self.barcodeScannerView?.onScanFailure = { [weak self] (error) in
            if let strongSelf = self {
                strongSelf.scannerLogLabel?.text = error
                strongSelf.scannerLogLabel?.textColor = .red
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.clearInfoLabels()
    }

    @IBAction func toggleButtonTapped(_ sender: UIButton) {
        self.willStop.toggle()
    }
    
    @IBAction func clearScannedInfoTapped(_ sender: UIButton) {
        self.clearInfoLabels()
    }
    
    private func clearInfoLabels() {
        self.codeLabel?.text = ""
        self.typeLabel?.text = ""
        self.dateLabel?.text = ""
        self.scannerLogLabel?.text = ""
    }
}

extension UIViewController {
    
    static var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        return formatter
    }
}

