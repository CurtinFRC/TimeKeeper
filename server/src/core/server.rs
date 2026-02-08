use std::time::Duration;

use anyhow::Result;

use crate::{
  config::ServerConfig,
  core::{scheduler::SchedulerPool, shutdown::ShutdownNotifier, web::Web},
};

pub struct Server {
  config: ServerConfig,
  scheduler: SchedulerPool,
}

impl Server {
  pub fn new(config: Option<ServerConfig>) -> Self {
    let config = match config {
      Some(cfg) => cfg,
      None => ServerConfig::parse_from_cli(),
    };

    Self { config, scheduler: SchedulerPool::new() }
  }

  pub async fn run(mut self) -> Result<()> {
    log::info!("Running server with config: {:?}", self.config);

    let shutdown_notifier = ShutdownNotifier::get();

    // Start Web Server
    let web_socket_addr =
      format!("{}:{}", self.config.addr, self.config.web_port).parse().expect("Error parsing web address");
    let web_server = Web::new(web_socket_addr, "client/build/web".to_string());
    let mut web_handle = tokio::spawn(async move { web_server.serve().await });

    // TODO: Start API server
    // let mut api_handle = tokio::spawn(async move { ... });

    // Wait for ctrl-c
    tokio::signal::ctrl_c().await.expect("Failed to listen for ctrl-c");
    log::info!("Received ctrl-c, beginning graceful shutdown...");

    // Notify all services to begin graceful shutdown
    shutdown_notifier.notify();

    // Wait for services to shutdown gracefully with timeout
    let timeout_future = async {
      // Wait for web server
      if let Err(e) = (&mut web_handle).await {
        log::error!("Web server task panicked: {:?}", e);
      }

      // TODO: Wait for API server
      // if let Err(e) = (&mut api_handle).await {
      //   log::error!("API server task panicked: {:?}", e);
      // }

      // Wait for scheduled services
      if let Err(e) = self.scheduler.wait_all().await {
        log::error!("Scheduled services error: {:?}", e);
      }
    };

    match tokio::time::timeout(Duration::from_secs(5), timeout_future).await {
      Ok(()) => log::info!("All services shut down gracefully"),
      Err(_) => {
        log::warn!("Shutdown timeout - force aborting...");
        web_handle.abort();
        // api_handle.abort();
        self.scheduler.abort_all();
      }
    }

    Ok(())
  }
}
