//
//  SyncDatabase.swift
//  Health Data Importer
//
//  Created by Lucas Pape on 30.04.22.
//

import FileProvider
import SQLite3

class SyncDatabase {
    private var db: OpaquePointer?
    private let path: String = "sync_database.sqlite"
    private let tableName: String = "syncs"
    
    static var onChange = {
        
    }
    
    init(){
        self.db = createDB()
        self.createTable()
    }
    
    private func createDB() -> OpaquePointer? {
        let filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(path)
        
        var db: OpaquePointer?
        
        if sqlite3_open(filePath.path, &db) != SQLITE_OK {
            Logger.log(msg: "Error creating database")
            return nil
        } else {
            Logger.log(msg: "Opened/Created DB")
            return db
        }
    }
    
    private func createTable(){
        let query = "CREATE TABLE IF NOT EXISTS " + tableName + " (id TEXT PRIMARY KEY, type TEXT, data TEXT);"
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                Logger.log(msg: "Created Table")
            }else{
                Logger.log(msg: "Failed to create table")
            }
        }else{
            Logger.log(msg: "Database preparation failed")
        }
    }
    
    func insert(sync: Sync) -> Bool {
        let query = "INSERT INTO " + tableName + " (id, type, data) VALUES (?,?,?);"
        
        let id = UUID().uuidString
        var type = ""
        var data = ""
        
        let encoder = JSONEncoder()
        
        var statement : OpaquePointer?
        
        do {
            if(sync is HeartRateSync) {
                let sync = sync as! HeartRateSync
                type = "heartrate"
                
                data = String(decoding: try encoder.encode(sync), as: UTF8.self)
            }
            
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (type as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (data as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    return true
                }else{
                    Logger.log(msg: "Could not insert data into table")
                }
            }else{
                Logger.log(msg: "Could not prepare database")
            }
        }catch{
            Logger.log(msg: "JSON encode error")
        }
        
        SyncDatabase.onChange()
        
        return false
    }
    
    func get() -> [SyncWithId] {
        var list: [SyncWithId] = []
        
        let query = "SELECT * FROM " + tableName + ";"
        
        var statement : OpaquePointer? = nil
        
        let decoder = JSONDecoder()
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(describing: String(cString: sqlite3_column_text(statement, 0)))
                let type = String(describing: String(cString: sqlite3_column_text(statement, 1)))
                let data = String(describing: String(cString: sqlite3_column_text(statement, 2)))
                
                do {
                    if(type == "heartrate"){
                        let heartRateSync = try decoder.decode(HeartRateSync.self, from: data.data(using: .utf8)!)
                        list.append(SyncWithId(sync: heartRateSync, id: id))
                    }
                }catch{
                    Logger.log(msg: "JSON decode error")
                }
            }
        }
        
        return list
    }
    
    func delete(id: String) -> Bool {
        let query = "DELETE FROM " + tableName + " where id = ?"
        
        var statement : OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                return true
            }else{
                Logger.log(msg: "Failed to delete")
            }
        }
        
        SyncDatabase.onChange()
        
        return false
    }
}
