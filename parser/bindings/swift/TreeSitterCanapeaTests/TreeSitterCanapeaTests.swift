import XCTest
import SwiftTreeSitter
import TreeSitterCanapea

final class TreeSitterCanapeaTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_canapea())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading Canapea grammar")
    }
}
