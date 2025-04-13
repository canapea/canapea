import XCTest
import SwiftTreeSitter
import TreeSitterLang0

final class TreeSitterLang0Tests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_lang0())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading Lang0 grammar")
    }
}
