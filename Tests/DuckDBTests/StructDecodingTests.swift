//
//  CountrySerializationTests.swift
//  DuckDB
//
//  Created by Sten Soosaar on 11.09.2025.
//

import Foundation
import XCTest
import DuckDB

final class StructDecodingnTests: XCTestCase {
    
	struct Country: Decodable, Equatable {
			var fullName: String
			var isoCode: String
			var isActive: Bool
        
			init(_ fullName: String, iso2: String, isActive: Bool) {
					self.fullName = fullName
					self.isoCode = iso2
					self.isActive = isActive
			}
	}
    
	func testSerializeAndDeserializeCountries() throws {
		
		let countries: [Country] = [
			Country("United States", iso2: "US", isActive: true),
			Country("United Kingdom", iso2: "GB", isActive: true),
			Country("Netherlands", iso2: "NL", isActive: true),
			Country("Denmark", iso2: "DK", isActive: true)
		]
		
		let database = try Database(store: .inMemory)
		let connection = try database.connect()
		
		_ = try connection.execute("""
			CREATE TABLE country (
				full_name VARCHAR,
				iso_code CHAR(3),
				is_active BOOL
			);
			""")
		
		let appender = try Appender(connection: connection, table: "country")
		for country in countries {
			try appender.append(country.fullName)
			try appender.append(country.isoCode)
			try appender.append(country.isActive)
			try appender.endRow()
		}
		try appender.flush()
		
		let result = try connection.query("""
			SELECT	
				STRUCT_PACK(
					fullName := full_name,
					isoCode := iso_code,
					isActive := is_active
				) 
			FROM country;
		""")
		
		let dbCountries = result[0].cast(to: Country.self).compactMap { $0 }
		XCTAssertEqual(dbCountries, countries)
		
	}
	
}
