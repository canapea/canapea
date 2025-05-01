extern crate tree_sitter_canapea;

use std::path::PathBuf;

use tree_sitter::Parser;
use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;
use tower_lsp::{Client, LanguageServer, LspService, Server};

#[derive(Debug)]
struct Backend {
    client: Client,
}

#[tower_lsp::async_trait]
impl LanguageServer for Backend {
    async fn initialize(
        &self,
        _: InitializeParams,
    ) -> Result<InitializeResult> {
        let mut parser = Parser::new();
        parser
            .set_language(&tree_sitter_canapea::LANGUAGE.into())
            .expect("Error loading Canapea parser");
        Ok(InitializeResult::default())
    }

    async fn initialized(&self, _: InitializedParams) {
        self.client
            .log_message(MessageType::INFO, "server initizlized!")
            .await;
    }

    async fn shutdown(&self) -> Result<()> {
        Ok(())
    }
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub struct LanguageServerConfig {
    pub transport: TransportKind,
}

// See https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#implementationConsiderations
#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum TransportKind {
    Stdio,
    // Pipe,
    // Socket,
    // Nodeipc
}

#[tokio::main]
pub async fn start(config: LanguageServerConfig) {
    match config.transport {
        TransportKind::Stdio => {
            let stdin = tokio::io::stdin();
            let stdout = tokio::io::stdout();

            let (service, socket) =
                LspService::new(|client| Backend { client });
            Server::new(stdin, stdout, socket).serve(service).await;
        }
    }
}

pub fn format_files<T: IntoIterator<Item = PathBuf>>(paths: T) {
    for path in paths.into_iter() {
        println!("TODO: Format file {path:#?}");
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
