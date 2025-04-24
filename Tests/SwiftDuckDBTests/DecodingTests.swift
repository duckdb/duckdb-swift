//
//  DecodingTests.swift
//  DuckDB
//
//  Created by Jason Jobe on 4/24/25.
//


import Foundation
import StructuredQueries
@testable import SwiftDuckDB
import Testing
@preconcurrency import TabularData

//import SnapshotTesting

struct DecodingTests {
    let db: Database
    let dbc: Connection

    init() throws {
        db = try Database(store: .inMemory)
        dbc = try db.connect()
    }
    
    @Test func basics() throws {
        try dbc.execute("""
        CREATE TABLE testtables(
            id INTEGER PRIMARY KEY,
            name VARCHAR,
            age FLOAT
        )
        """)
        
        try dbc.execute("""
            INSERT INTO testtables (id, name, age)
            VALUES
                (1, 'Bob', 20.0),
                (2, 'Alice', 20.0);
        """)

//        let insert = TestTable.insert {
//            ($0.id, $0.name, $0.age)
//        }
//        values: {
//            (1, "Bob", 20.0)
//            (2, "Alice", 20.0)
//        }
//        try dbc.execute(insert)
        
        let sql = TestTable.all

        let results = try dbc.query(sql)
        var decoder = DuckDBQueryDecoder(resultSet: results)
        
        do {
            for ndx in 0..<results.rowCount {
                let row = try TestTable(decoder: &decoder)
                print(ndx, row)
                decoder.next()
            }
        } catch {
            print(error)
        }
        #expect(true)
    }
}

@Table private struct TestTable {
  var id: Int
  var name: String
  var age: Double
}
