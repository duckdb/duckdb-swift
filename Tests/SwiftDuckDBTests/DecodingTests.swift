//
//  DecodingTests.swift
//  DuckDB
//
//  Created by Jason Jobe on 4/24/25.
//


import Foundation
import StructuredQueries
import SwiftDuckDB
import Testing
import SnapshotTesting

struct DecodingTests {
    let db: Database
    let dbc: Connection

    init() throws {
        db = try Database(store: .inMemory)
        dbc = try db.connect()
    }
    
    @Test func basics() throws {
        try dbc.execute("""
        """)
    }
}
