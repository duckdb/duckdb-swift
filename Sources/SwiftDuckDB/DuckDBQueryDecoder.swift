//
//  DuckDBQueryDecoder.swift
//  DuckDB
//
//  Created by Jason Jobe on 4/24/25.
//


import DuckDB
import StructuredQueries

@usableFromInline
struct DuckDBQueryDecoder: QueryDecoder {
    @usableFromInline
    let resultSet: ResultSet
    
    @usableFromInline
    var currentRow: DBInt = 0
    
    @usableFromInline
    var currentColumn: DBInt = 0

    @usableFromInline
    init(resultSet: ResultSet) {
        self.resultSet = resultSet
    }
    
    @inlinable
    mutating func next() {
        currentRow += 1
        currentColumn = 0
    }
    
    @inlinable
    @_disfavoredOverload
    func value<T: Decodable>(at ndx: DBInt) -> T? {
        let value = resultSet[currentColumn].cast(to: T.self)[currentRow]
        print(#function, T.self, resultSet[currentColumn].id, value as Any)
        return value
    }
    
    @inlinable
    func value<T: FixedWidthInteger>(at ndx: DBInt) -> T? {
        let value = resultSet[currentColumn].cast(to: Int.self)[currentRow]
        print(#function, T.self, resultSet[currentColumn].id, value as Any)
        return if let value { T(value) } else { nil }
    }

    @inlinable
    mutating func decode(_ columnType: [UInt8].Type) throws -> [UInt8]? {
        defer { currentColumn += 1 }
        return value(at: currentColumn)
    }
    
    @inlinable
    mutating func decode(_ columnType: Double.Type) throws -> Double? {
        defer { currentColumn += 1 }
        print(#function, columnType, resultSet[currentColumn].id)
        guard let f = resultSet[currentColumn].cast(to: Float.self)[currentRow]
        else { return nil }
        return Double(f)
//        return value(at: currentColumn)
    }
    
    @inlinable
    mutating func decode(_ columnType: Int64.Type) throws -> Int64? {
        defer { currentColumn += 1 }
        return value(at: currentColumn)
    }
    
    @inlinable
    mutating func decode(_ columnType: String.Type) throws -> String? {
        defer { currentColumn += 1 }
//        return resultSet[currentColumn].cast(to: String.self)[currentRow]
        return value(at: currentColumn)
    }
    
    @inlinable
    mutating func decode(_ columnType: Bool.Type) throws -> Bool? {
        resultSet[currentColumn].cast(to: columnType)[currentRow]
//        try decode(Int64.self).map { $0 != 0 }
    }
    
    @inlinable
    mutating func decode(_ columnType: Int.Type) throws -> Int? {
        try decode(Int64.self).map(Int.init)
    }
}

extension DatabaseType {
  
  public var description: String {
    switch self {
    case .boolean: return "\(Self.self).boolean"
    case .tinyint: return "\(Self.self).tinyint"
    case .smallint: return "\(Self.self).smallint"
    case .integer: return "\(Self.self).integer"
    case .bigint: return "\(Self.self).bigint"
    case .utinyint: return "\(Self.self).utinyint"
    case .usmallint: return "\(Self.self).usmallint"
    case .uinteger: return "\(Self.self).uinteger"
    case .ubigint: return "\(Self.self).ubigint"
    case .float: return "\(Self.self).float"
    case .double: return "\(Self.self).double"
    case .timestamp: return "\(Self.self).timestamp"
    case .timestampTz: return "\(Self.self).timestampTZ"
    case .date: return "\(Self.self).date"
    case .time: return "\(Self.self).time"
    case .timeTz: return "\(Self.self).timeTZ"
    case .interval: return "\(Self.self).interval"
    case .hugeint: return "\(Self.self).hugeint"
    case .uhugeint: return "\(Self.self).uhugeint"
    case .varchar: return "\(Self.self).varchar"
    case .blob: return "\(Self.self).blob"
    case .decimal: return "\(Self.self).decimal"
    case .timestampS: return "\(Self.self).timestampS"
    case .timestampMS: return "\(Self.self).timestampMS"
    case .timestampNS: return "\(Self.self).timestampNS"
    case .`enum`: return "\(Self.self).enum"
    case .list: return "\(Self.self).list"
    case .`struct`: return "\(Self.self).struct"
    case .map: return "\(Self.self).map"
    case .union: return "\(Self.self).union"
    case .uuid: return "\(Self.self).uuid"
//    case .invalid: return "\(Self.self).invalid"
    default: return "\(Self.self).unknown - id: (\(self.rawValue))"
    }
  }
}
