//
//  SyncLogDatabase.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 30.04.22.
//

import FileProvider
import SQLite3

class SyncLogDatabase {
    private var db: OpaquePointer?
    private let path: String = "sync_log_database.sqlite"
    private let tableName: String = "logs"
    
    init(){
        self.db = createDB()
        self.createTable()
    }
    
    private func createDB() -> OpaquePointer? {
        let filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(path)
        
        var db: OpaquePointer?
        
        if sqlite3_open(filePath.path, &db) != SQLITE_OK {
            print("Error creating database")
            return nil
        } else {
            print("Loaded/created DB")
            return db
        }
    }
    
    private func createTable(){
        let query = "CREATE TABLE IF NOT EXISTS " + tableName + " (id TEXT PRIMARY KEY, date INT, successCount INT, errorCount INT, type TEXT, filename TEXT);"
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Created table")
            }else{
                print("Failed to create table")
            }
        }else{
            print("Preparation failed")
        }
    }
    
    func insert(log: Log) -> Bool {
        let query = "INSERT INTO " + tableName + " (id, date, successCount, errorCount, type, filename) VALUES (?,?,?,?,?,?);"
        
        var statement : OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (log.id as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(statement, 2, Int64(log.date.timeIntervalSince1970))
            sqlite3_bind_int64(statement, 3, Int64(log.successCount))
            sqlite3_bind_int64(statement, 4, Int64(log.errorCount))
            sqlite3_bind_text(statement, 5, (log.type as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (log.fileName as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Inserted")
                return true
            }else{
                print("Could not insert data")
            }
        }else{
            print("Could not prepare db")
        }
        
        return false
    }
    
    func get() -> [Log] {
        var list: [Log] = []
        
        let query = "SELECT * FROM " + tableName + " ORDER BY date DESC;"
        
        var statement : OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(describing: String(cString: sqlite3_column_text(statement, 0)))
                let date = Int(sqlite3_column_int64(statement, 1))
                let successCount = Int(sqlite3_column_int64(statement, 2))
                let errorCount = Int(sqlite3_column_int64(statement, 3))
                let type = String(describing: String(cString: sqlite3_column_text(statement, 4)))
                let fileName = String(describing: String(cString: sqlite3_column_text(statement, 5)))
                
                list.append(Log(id: id, date: Date(timeIntervalSince1970: Double(date)), successCount: successCount, errorCount: errorCount, type: type, fileName: fileName))
            }
        }
        
        return list
    }
}
