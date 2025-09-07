//
//  DuckDB
//  https://github.com/duckdb/duckdb-swift
//
//  Copyright © 2018-2025 Stichting DuckDB Foundation
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

import Foundation
import XCTest
@testable import DuckDB

// MARK: - ResultSetRowIteratorTests

final class ResultSetRowIteratorTests: XCTestCase {
  func test_forEachRow_countsAllRows() throws {
    let db = try Database(store: .inMemory)
    let conn = try db.connect()
    // Insert 10 rows
    try conn.execute("CREATE TABLE t(a INTEGER);")
    for i in 0..<10 {
      try conn.execute("INSERT INTO t VALUES (\(i));")
    }
    let result = try conn.query("SELECT * FROM t;")
    var count = 0
    result.forEachRow { _ in
      count += 1
    }
    XCTAssertEqual(count, Int(result.rowCount))
  }
  
  func test_forEachRow_matchesElementAccess() throws {
    let db = try Database(store: .inMemory)
    let conn = try db.connect()
    // Insert 5 rows
    try conn.execute("CREATE TABLE t(a INTEGER, b VARCHAR);")
    let values: [(Int, String)] = [(1, "one"), (2, "two"), (3, "three"), (4, "four"), (5, "five")]
    for (a, b) in values {
      try conn.execute("INSERT INTO t VALUES (\(a), '\(b)');")
    }
    let result = try conn.query("SELECT * FROM t ORDER BY a;")
    let intCol = result[0].cast(to: Int32.self)
    let strCol = result[1].cast(to: String.self)
    var rowIndex = 0
    result.forEachRow { row in
      // Compare values via RowCursor and via element(forColumn:at:)
      let aVal = intCol[DBInt(row.rowInChunk)]
      let bVal = strCol[DBInt(row.rowInChunk)]
      let aEl = intCol[DBInt(rowIndex)]
      let bEl = strCol[DBInt(rowIndex)]
      XCTAssertEqual(aVal, aEl)
      XCTAssertEqual(bVal, bEl)
      rowIndex += 1
    }
    XCTAssertEqual(rowIndex, Int(result.rowCount))
  }
  
  func test_forEachRow_emptyResult() throws {
    let db = try Database(store: .inMemory)
    let conn = try db.connect()
    try conn.execute("CREATE TABLE t(a INTEGER);")
    let result = try conn.query("SELECT * FROM t WHERE 1=0;")
    var called = false
    result.forEachRow { _ in
      called = true
    }
    XCTAssertFalse(called)
    XCTAssertEqual(result.rowCount, 0)
  }
  
  func test_forEachRow_multipleColumns() throws {
    let db = try Database(store: .inMemory)
    let conn = try db.connect()
    try conn.execute("CREATE TABLE t(i INT, f DOUBLE, s VARCHAR);")
    try conn.execute("INSERT INTO t VALUES (1, 3.14, 'duck');")
    try conn.execute("INSERT INTO t VALUES (2, -2.71, NULL);")
    let result = try conn.query("SELECT * FROM t ORDER BY i;")
    let intCol = result[0].cast(to: Int32.self)
    let doubleCol = result[1].cast(to: Double.self)
    let strCol = result[2].cast(to: String.self)
    var rows: [[Any?]] = []
    result.forEachRow { row in
      let i = intCol[DBInt(row.rowInChunk)]
      let f = doubleCol[DBInt(row.rowInChunk)]
      let s = strCol[DBInt(row.rowInChunk)]
      rows.append([i, f, s])
    }
    XCTAssertEqual(rows.count, 2)
    // Compare with element(forColumn:at:)
    for idx in 0..<result.rowCount {
      let i = intCol[DBInt(idx)]
      let f = doubleCol[DBInt(idx)]
      let s = strCol[DBInt(idx)]
      XCTAssertEqual(rows[Int(idx)][0] as? Int32, i)
      XCTAssertEqual(rows[Int(idx)][1] as? Double, f)
      XCTAssertEqual(rows[Int(idx)][2] as? String, s)
    }
  }
}
