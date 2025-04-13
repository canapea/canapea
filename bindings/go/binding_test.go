package tree_sitter_lang0_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_lang0 "github.com/mfeineis/tree-sitter-lang0/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_lang0.Language())
	if language == nil {
		t.Errorf("Error loading Lang0 grammar")
	}
}
