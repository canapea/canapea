package tree_sitter_sol3_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_sol3 "github.com/tree-sitter/tree-sitter-sol3/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_sol3.Language())
	if language == nil {
		t.Errorf("Error loading sol3 grammar")
	}
}
