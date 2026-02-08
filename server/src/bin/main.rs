use anyhow::Result;
use server::core::server::Server;

#[tokio::main]
async fn main() -> Result<()> {
  server::core::logging::init_logging()?;
  Server::new(None).run().await
}
