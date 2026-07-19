import io.github.treesitter.jtreesitter.Language;
import io.github.treesitter.jtreesitter.sol3.TreeSitterSol3;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

public class TreeSitterSol3Test {
    @Test
    public void testCanLoadLanguage() {
        assertDoesNotThrow(() -> new Language(TreeSitterSol3.language()));
    }
}
