package tree_sitter_canapea_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_canapea "github.com/canapea/canapea/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_canapea.Language())
	if language == nil {
		t.Errorf("Error loading Canapea grammar")
	}
}
