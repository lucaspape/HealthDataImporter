//
//  Logger.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 01.05.22.
//

import Foundation

class Logger {
    private static let sessionId = String(Date.now.timeIntervalSince1970)
    private static var inputPipe: Pipe!
    private static var outputPipe: Pipe!
    
    private static func logToFile(msg: String){
        let paths = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)
        let documentDirectoryPath = paths.first!
        let logDir = documentDirectoryPath.appendingPathComponent("logs/")
        let log = documentDirectoryPath.appendingPathComponent("logs/log-" + sessionId + ".txt")
        
        do {
            try FileManager.default.createDirectory(atPath: logDir.path, withIntermediateDirectories: true, attributes: nil)
        }catch{
        }
        
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
    
    static func openConsolePipe() {
        setvbuf(stdout, nil, _IONBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)

        // open a pipe to consume data sent into STDOUT and STDERR
        inputPipe = Pipe()

        // open a pipe to output data back to STDOUT
        outputPipe = Pipe()

        guard let inputPipe = inputPipe, let outputPipe = outputPipe else {
            return
        }

        let inputPipeReadHandle = inputPipe.fileHandleForReading

        // Redirect data sent into the output pipe into STDOUT, too.
        dup2(STDOUT_FILENO, outputPipe.fileHandleForWriting.fileDescriptor)

        // Redirect data sent into STDOUT and STDERR into the input pipe, too.
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        // listen for the readCompletionNotification.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveReadCompletionNotification),
                                               name: FileHandle.readCompletionNotification,
                                               object: inputPipeReadHandle)

        // We want to be notified of any data coming into our input pipe.
        inputPipeReadHandle.readInBackgroundAndNotify()
    }

    @objc private static func didReceiveReadCompletionNotification(notification: Notification) {
        // Need to call this to keep getting notified.
        inputPipe?.fileHandleForReading.readInBackgroundAndNotify()

        if let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data,
           let str = String(data: data, encoding: .utf8) {

            // Write the data back into the output pipe.
            // The output pipe's write file descriptor points to STDOUT,
            // which makes the logs show up in the Xcode console.
            outputPipe?.fileHandleForWriting.write(data)
            
            logToFile(msg: str.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
