//
//  Logger.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 01.05.22.
//

import Foundation

class Logger {
    static let sessionId = String(Date.now.timeIntervalSince1970)
    
    static func log(msg: String){
        logToFile(msg: msg)
        
        print(msg)
    }
    
    static func log(error: Error){
        logToFile(msg: error.localizedDescription)
        
        print(error.localizedDescription)
    }
    
    private static func logToFile(msg: String){
        let paths = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)
        let documentDirectoryPath = paths.first!
        let log = documentDirectoryPath.appendingPathComponent("log-" + sessionId + ".txt")
        
        do {
            let handle = try FileHandle(forWritingTo: log)
            handle.seekToEndOfFile()
            handle.write((msg + "\n").data(using: .utf8)!)
            handle.closeFile()
        }catch{
            print(error.localizedDescription)
            do {
                try msg.data(using: .utf8)?.write(to: log)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
