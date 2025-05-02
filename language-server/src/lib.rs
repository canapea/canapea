pub mod docs;
pub mod format;

mod parsing;

use std::net::SocketAddr as TcpSocketAddr;

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
        let _parser = parsing::create_parser();
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

#[derive(Debug)]
pub struct LanguageServerConfig {
    pub transport: TransportKind,
}

// See https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#implementationConsiderations
#[derive(Debug)]
pub enum TransportKind {
    Stdio,
    UnixSocket {
        // std::os::unix::SocketAddr
        path: String,
    },
    TcpSocket(TcpSocketAddr),
    // Nodeipc,
}

#[tokio::main]
pub async fn start(config: LanguageServerConfig) {
    let LanguageServerConfig { transport } = config;

    let (service, client_socket) = LspService::new(|client| Backend { client });

    // TODO: Recoverable error handling
    match transport {
        TransportKind::Stdio => {
            let stdin = tokio::io::stdin();
            let stdout = tokio::io::stdout();
            Server::new(stdin, stdout, client_socket)
                .serve(service)
                .await
        }
        TransportKind::TcpSocket(socket_addr) => {
            match tokio::net::TcpStream::connect(socket_addr).await {
                Ok(tcp_stream) => {
                    let (read_from, write_to) = tokio::io::split(tcp_stream);
                    Server::new(read_from, write_to, client_socket)
                        .serve(service)
                        .await
                }
                Err(err) => {
                    println!("{err:#?}");
                    return;
                }
            }
        }
        TransportKind::UnixSocket { path } => {
            // FIXME: What do we do when UNIX socket is already in use?
            match tokio::net::UnixListener::bind(path) {
                Ok(listener) => match listener.accept().await {
                    Ok((unix_stream, _socket_addr)) => {
                        let (read_from, write_to) =
                            tokio::io::split(unix_stream);
                        Server::new(read_from, write_to, client_socket)
                            .serve(service)
                            .await
                    }
                    Err(err) => {
                        println!("{err:#?}");
                        return;
                    }
                },
                Err(err) => {
                    println!("{err:#?}");
                    return;
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
