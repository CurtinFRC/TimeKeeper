use std::pin::Pin;

use chrono::Utc;
use tokio_stream::{
  Stream, StreamExt,
  wrappers::{BroadcastStream, errors::BroadcastStreamRecvError},
};
use tonic::{Request, Response, Result, Status};

use crate::{
  auth::auth_helpers::require_permission,
  core::{
    events::{ChangeEvent, EVENT_BUS},
    shutdown::with_shutdown,
  },
  generated::{
    api::{
      CheckInOutRequest, CheckInOutResponse, GetSessionsRequest, GetSessionsResponse, SessionResponse,
      StreamSessionsRequest, StreamSessionsResponse, session_service_server::SessionService,
    },
    common::{Role, Timestamp},
    db::{Session, TeamMemberSession},
  },
  modules::session::SessionRepository,
};

pub struct SessionApi;

fn get_all_sessions() -> std::result::Result<Vec<SessionResponse>, Status> {
  Session::get_all()
    .map_err(|e| Status::internal(format!("Failed to get sessions: {}", e)))?
    .into_iter()
    .map(|(id, session)| Ok(SessionResponse { id, session: Some(session) }))
    .collect()
}

fn now_timestamp() -> Timestamp {
  let now = Utc::now();
  Timestamp { seconds: now.timestamp(), nanos: 0 }
}

const FOUR_HOURS_SECS: i64 = 4 * 60 * 60;

#[tonic::async_trait]
impl SessionService for SessionApi {
  // Getter

  async fn get_sessions(&self, _request: Request<GetSessionsRequest>) -> Result<Response<GetSessionsResponse>, Status> {
    let sessions = get_all_sessions()?;
    Ok(Response::new(GetSessionsResponse { sessions }))
  }

  // Stream

  type StreamSessionsStream = Pin<Box<dyn Stream<Item = Result<StreamSessionsResponse, Status>> + Send>>;

  async fn stream_sessions(
    &self,
    _request: Request<StreamSessionsRequest>,
  ) -> Result<Response<Self::StreamSessionsStream>, Status> {
    let initial = get_all_sessions()?;

    let Some(event_bus) = EVENT_BUS.get() else {
      return Err(Status::internal("Event bus not initialized"));
    };

    let rx = event_bus
      .subscribe::<Session>()
      .map_err(|e| Status::internal(format!("Failed to subscribe to session events: {}", e)))?;

    let stream = BroadcastStream::new(rx).filter_map(|result| match result {
      Ok(event) => match event {
        ChangeEvent::Record { id, data, .. } => data
          .map(|session| Ok(StreamSessionsResponse { sessions: vec![SessionResponse { id, session: Some(session) }] })),
        ChangeEvent::Table => match get_all_sessions() {
          Ok(sessions) => Some(Ok(StreamSessionsResponse { sessions })),
          Err(e) => {
            log::error!("Failed to get all sessions after table change: {}", e);
            None
          }
        },
        _ => None,
      },
      Err(BroadcastStreamRecvError::Lagged(n)) => {
        log::warn!("Client lagged by {} messages", n);
        None
      }
    });

    let full_stream = tokio_stream::once(Ok(StreamSessionsResponse { sessions: initial })).chain(stream);
    let full_stream = with_shutdown(full_stream);

    Ok(Response::new(Box::pin(full_stream)))
  }

  // Check In / Out

  async fn check_in_out(&self, request: Request<CheckInOutRequest>) -> Result<Response<CheckInOutResponse>, Status> {
    require_permission(&request, Role::Kiosk)?;
    let team_member_id = request.into_inner().team_member_id;
    let now = now_timestamp();

    // Get all sessions and find unfinished ones sorted by start time
    let all_sessions = Session::get_all().map_err(|e| Status::internal(format!("Failed to get sessions: {}", e)))?;

    let mut unfinished: Vec<(String, Session)> =
      all_sessions.into_iter().filter(|(_, s)| !s.finished && s.start_time.is_some()).collect();

    unfinished.sort_by_key(|(_, s)| s.start_time.as_ref().map(|t| t.seconds).unwrap_or(0));

    // Check if the member is already checked in to any session — if so, check them out
    for (id, session) in &mut unfinished {
      for ms in &mut session.member_sessions {
        if ms.team_member_id == team_member_id && ms.check_in_time.is_some() && ms.check_out_time.is_none() {
          ms.check_out_time = Some(now);
          Session::update(id, session).map_err(|e| Status::internal(format!("Failed to update session: {}", e)))?;
          return Ok(Response::new(CheckInOutResponse { checked_in: false }));
        }
      }
    }

    // Not checked in — find the right session to check into
    if unfinished.is_empty() {
      return Err(Status::not_found("No active sessions available"));
    }

    // Decide which session to check into
    // If there's a next session and we're within 4 hours of its start, use that instead
    let target_index = match unfinished.get(1) {
      Some((_, next_session)) => match &next_session.start_time {
        Some(next_start) => {
          let time_until_next = next_start.seconds - now.seconds;
          if time_until_next > 0 && time_until_next <= FOUR_HOURS_SECS { 1 } else { 0 }
        }
        None => 0,
      },
      None => 0,
    };

    let (id, session) =
      unfinished.get_mut(target_index).ok_or_else(|| Status::internal("Failed to resolve target session"))?;

    session.member_sessions.push(TeamMemberSession { team_member_id, check_in_time: Some(now), check_out_time: None });

    Session::update(id, session).map_err(|e| Status::internal(format!("Failed to update session: {}", e)))?;

    Ok(Response::new(CheckInOutResponse { checked_in: true }))
  }
}
