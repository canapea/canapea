import XCTest
import SwiftTreeSitter
import TreeSitterSol3

final class TreeSitterSol3Tests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_sol3())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading sol3 grammar")
    }
}
