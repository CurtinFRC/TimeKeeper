use tonic::{Request, Response, Result, Status};

use crate::{
  auth::auth_helpers::require_permission,
  core::db::recreate_default_admin,
  generated::{
    api::{
      GetSettingsRequest, GetSettingsResponse, PurgeDatabaseRequest, PurgeDatabaseResponse, UpdateSettingsRequest,
      UpdateSettingsResponse, settings_service_server::SettingsService,
    },
    common::Role,
    db::{Location, Secret, Session, Settings, TeamMember, TeamMemberSession, User},
  },
  modules::{
    location::LocationRepository, secret::SecretRepository, session::SessionRepository, settings::SettingsRepository,
    team_member::TeamMemberRepository, team_member_session::TeamMemberSessionRepository, user::UserRepository,
  },
};

pub struct SettingsApi;

#[tonic::async_trait]
impl SettingsService for SettingsApi {
  async fn get_settings(&self, _request: Request<GetSettingsRequest>) -> Result<Response<GetSettingsResponse>, Status> {
    let settings = Settings::get().map_err(|e| Status::internal(format!("Failed to get settings: {}", e)))?;
    Ok(Response::new(GetSettingsResponse { settings: Some(settings) }))
  }

  async fn update_settings(
    &self,
    request: Request<UpdateSettingsRequest>,
  ) -> Result<Response<UpdateSettingsResponse>, Status> {
    require_permission(&request, Role::Admin)?;
    let req = request.into_inner();

    let settings = Settings { next_session_threshold_secs: req.next_session_threshold_secs };
    Settings::set(&settings).map_err(|e| Status::internal(format!("Failed to update settings: {}", e)))?;

    Ok(Response::new(UpdateSettingsResponse {}))
  }

  async fn purge_database(
    &self,
    request: Request<PurgeDatabaseRequest>,
  ) -> Result<Response<PurgeDatabaseResponse>, Status> {
    require_permission(&request, Role::Admin)?;

    // Clear all data using repository methods so the event bus notifies clients
    TeamMemberSession::clear()
      .map_err(|e| Status::internal(format!("Failed to clear team member session data: {}", e)))?;
    Session::clear().map_err(|e| Status::internal(format!("Failed to clear session data: {}", e)))?;
    TeamMember::clear().map_err(|e| Status::internal(format!("Failed to clear team member data: {}", e)))?;
    Location::clear().map_err(|e| Status::internal(format!("Failed to clear location data: {}", e)))?;
    User::clear().map_err(|e| Status::internal(format!("Failed to clear user data: {}", e)))?;
    Secret::clear().map_err(|e| Status::internal(format!("Failed to clear secret data: {}", e)))?;
    Settings::clear().map_err(|e| Status::internal(format!("Failed to clear settings data: {}", e)))?;

    log::warn!("Database purged by admin");

    // Recreate admin user with default password after clearing users
    recreate_default_admin().map_err(|e| Status::internal(format!("Failed to recreate admin user: {}", e)))?;

    Ok(Response::new(PurgeDatabaseResponse {}))
  }
}
