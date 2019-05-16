//
//  PSUIScannerLogger.swift
//  PSUIBarcodeScanner
//
//  Created by Piero Sifuentes on 14/5/19.
//  Copyright © 2019 PRSP. All rights reserved.
//

import Foundation

public enum PSUILogEvent: String {
    case e = "[‼️]" // error
    case i = "[ℹ️]" // info
    case d = "[💬]" // debug
    case v = "[🔬]" // verbose
    case w = "[⚠️]" // warning
    case s = "[🔥]" // severe
}

public struct PSUIScannerLogger {
    
    var isLoggingEnabled: Bool
    
    init(isLoggingEnabled: Bool = true) {
        self.isLoggingEnabled = isLoggingEnabled
    }
    
    static var dateFormat = "yyyy-MM-dd hh:mm:ss"
    
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    private func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
    
    // Only allowing in DEBUG mode
    private func print(_ object: Any) {
        #if DEBUG
        Swift.print(object)
        #endif
    }
    
    private func print(_ object: Any,
        event: PSUILogEvent = .e,
        filename: String = #file,
        line: Int = #line,
        column: Int = #column,
        funcName: String = #function) {
        if isLoggingEnabled {
            print("\(Date().toString()) \(event.rawValue)[\(sourceFileName(filePath: filename))] line:\(line) column:\(column) [\(funcName)] -> \(object)")
        }
    }

    func e(_ object: Any,
        filename: String = #file,
        line: Int = #line,
        column: Int = #column,
        funcName: String = #function) {
        print(object, event: .e, filename: filename, line: line, column: column, funcName: funcName)
    }
    
    func i(_ object: Any,
           filename: String = #file,
           line: Int = #line,
           column: Int = #column,
           funcName: String = #function) {
        print(object, event: .i, filename: filename, line: line, column: column, funcName: funcName)
    }
    
    func d(_ object: Any,
           filename: String = #file,
           line: Int = #line,
           column: Int = #column,
           funcName: String = #function) {
        print(object, event: .d, filename: filename, line: line, column: column, funcName: funcName)
    }
    
    func v(_ object: Any,
           filename: String = #file,
           line: Int = #line,
           column: Int = #column,
           funcName: String = #function) {
        print(object, event: .v, filename: filename, line: line, column: column, funcName: funcName)
    }
    
    func w(_ object: Any,
           filename: String = #file,
           line: Int = #line,
           column: Int = #column,
           funcName: String = #function) {
        print(object, event: .w, filename: filename, line: line, column: column, funcName: funcName)
    }
    
    func s(_ object: Any,
           filename: String = #file,
           line: Int = #line,
           column: Int = #column,
           funcName: String = #function) {
        print(object, event: .s, filename: filename, line: line, column: column, funcName: funcName)
    }
}

fileprivate extension Date {
    func toString() -> String {
        return PSUIScannerLogger.dateFormatter.string(from: self as Date)
    }
}
