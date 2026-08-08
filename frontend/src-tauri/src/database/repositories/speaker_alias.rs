use crate::database::models::SpeakerAlias;
use sqlx::{SqlitePool, Transaction};
use std::collections::HashMap;
use thiserror::Error;

pub const MAX_SPEAKER_ALIAS_LENGTH: usize = 80;
pub const UNIDENTIFIED_SPEAKER_LABEL: &str = "Unidentified speaker";

#[derive(Debug, Error)]
pub enum SpeakerAliasError {
    #[error("meeting_id cannot be empty")]
    EmptyMeetingId,
    #[error("speaker label cannot be empty")]
    EmptySpeakerLabel,
    #[error("Unidentified speaker cannot be renamed")]
    UnidentifiedSpeaker,
    #[error("only anonymous Speaker N labels can be renamed")]
    InvalidSpeakerLabel,
    #[error("alias cannot be empty")]
    EmptyAlias,
    #[error("alias must be {MAX_SPEAKER_ALIAS_LENGTH} characters or fewer")]
    AliasTooLong,
    #[error("alias cannot contain control characters")]
    ControlCharacter,
    #[error("speaker label does not exist in this meeting")]
    SpeakerNotFound,
    #[error("this alias is already used by another speaker in this meeting")]
    DuplicateAlias,
    #[error("meeting not found")]
    MeetingNotFound,
    #[error(transparent)]
    Database(#[from] sqlx::Error),
}

pub struct SpeakerAliasesRepository;

impl SpeakerAliasesRepository {
    pub async fn list(
        pool: &SqlitePool,
        meeting_id: &str,
    ) -> Result<Vec<SpeakerAlias>, SpeakerAliasError> {
        validate_meeting_id(meeting_id)?;
        Ok(sqlx::query_as::<_, SpeakerAlias>(
            "SELECT meeting_id, original_speaker_label, alias, created_at, updated_at
             FROM speaker_aliases WHERE meeting_id = ? ORDER BY original_speaker_label",
        )
        .bind(meeting_id)
        .fetch_all(pool)
        .await?)
    }

    pub async fn get(
        pool: &SqlitePool,
        meeting_id: &str,
        original_speaker_label: &str,
    ) -> Result<Option<SpeakerAlias>, SpeakerAliasError> {
        validate_meeting_id(meeting_id)?;
        validate_speaker_label(original_speaker_label)?;
        Ok(sqlx::query_as::<_, SpeakerAlias>(
            "SELECT meeting_id, original_speaker_label, alias, created_at, updated_at
             FROM speaker_aliases WHERE meeting_id = ? AND original_speaker_label = ?",
        )
        .bind(meeting_id)
        .bind(original_speaker_label)
        .fetch_optional(pool)
        .await?)
    }

    pub async fn upsert(
        pool: &SqlitePool,
        meeting_id: &str,
        original_speaker_label: &str,
        alias: &str,
    ) -> Result<SpeakerAlias, SpeakerAliasError> {
        validate_meeting_id(meeting_id)?;
        validate_speaker_label(original_speaker_label)?;
        let alias = validate_alias(alias)?;

        let mut transaction = pool.begin().await?;
        ensure_meeting_exists(&mut transaction, meeting_id).await?;
        ensure_speaker_exists(&mut transaction, meeting_id, original_speaker_label).await?;

        let duplicate: Option<(String,)> = sqlx::query_as(
            "SELECT original_speaker_label FROM speaker_aliases
             WHERE meeting_id = ? AND alias = ? COLLATE NOCASE
               AND original_speaker_label <> ?",
        )
        .bind(meeting_id)
        .bind(alias)
        .bind(original_speaker_label)
        .fetch_optional(&mut *transaction)
        .await?;
        if duplicate.is_some() {
            return Err(SpeakerAliasError::DuplicateAlias);
        }

        sqlx::query(
            "INSERT INTO speaker_aliases
                (meeting_id, original_speaker_label, alias, created_at, updated_at)
             VALUES (?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
             ON CONFLICT(meeting_id, original_speaker_label) DO UPDATE SET
                alias = excluded.alias,
                updated_at = CURRENT_TIMESTAMP",
        )
        .bind(meeting_id)
        .bind(original_speaker_label)
        .bind(alias)
        .execute(&mut *transaction)
        .await?;

        let saved = sqlx::query_as::<_, SpeakerAlias>(
            "SELECT meeting_id, original_speaker_label, alias, created_at, updated_at
             FROM speaker_aliases WHERE meeting_id = ? AND original_speaker_label = ?",
        )
        .bind(meeting_id)
        .bind(original_speaker_label)
        .fetch_one(&mut *transaction)
        .await?;
        transaction.commit().await?;
        Ok(saved)
    }

    pub async fn clear(
        pool: &SqlitePool,
        meeting_id: &str,
        original_speaker_label: &str,
    ) -> Result<bool, SpeakerAliasError> {
        validate_meeting_id(meeting_id)?;
        validate_speaker_label(original_speaker_label)?;
        let result = sqlx::query(
            "DELETE FROM speaker_aliases WHERE meeting_id = ? AND original_speaker_label = ?",
        )
        .bind(meeting_id)
        .bind(original_speaker_label)
        .execute(pool)
        .await?;
        Ok(result.rows_affected() > 0)
    }

    pub async fn alias_map(
        pool: &SqlitePool,
        meeting_id: &str,
    ) -> Result<HashMap<String, String>, SpeakerAliasError> {
        Ok(Self::list(pool, meeting_id)
            .await?
            .into_iter()
            .map(|item| (item.original_speaker_label, item.alias))
            .collect())
    }
}

pub fn resolve_speaker_display_name(
    original_speaker_label: Option<&str>,
    aliases: &HashMap<String, String>,
) -> Option<String> {
    original_speaker_label.map(|label| {
        aliases
            .get(label)
            .cloned()
            .unwrap_or_else(|| label.to_string())
    })
}

fn validate_meeting_id(meeting_id: &str) -> Result<(), SpeakerAliasError> {
    if meeting_id.trim().is_empty() {
        Err(SpeakerAliasError::EmptyMeetingId)
    } else {
        Ok(())
    }
}

fn validate_speaker_label(label: &str) -> Result<(), SpeakerAliasError> {
    let label = label.trim();
    if label.is_empty() {
        return Err(SpeakerAliasError::EmptySpeakerLabel);
    }
    if label.eq_ignore_ascii_case(UNIDENTIFIED_SPEAKER_LABEL) {
        return Err(SpeakerAliasError::UnidentifiedSpeaker);
    }
    let number = label
        .strip_prefix("Speaker ")
        .and_then(|value| value.parse::<u32>().ok());
    if number.is_some_and(|value| value > 0) {
        Ok(())
    } else {
        Err(SpeakerAliasError::InvalidSpeakerLabel)
    }
}

fn validate_alias(alias: &str) -> Result<&str, SpeakerAliasError> {
    let alias = alias.trim();
    if alias.is_empty() {
        return Err(SpeakerAliasError::EmptyAlias);
    }
    if alias.chars().count() > MAX_SPEAKER_ALIAS_LENGTH {
        return Err(SpeakerAliasError::AliasTooLong);
    }
    if alias.chars().any(char::is_control) {
        return Err(SpeakerAliasError::ControlCharacter);
    }
    Ok(alias)
}

async fn ensure_meeting_exists(
    transaction: &mut Transaction<'_, sqlx::Sqlite>,
    meeting_id: &str,
) -> Result<(), SpeakerAliasError> {
    let exists: Option<(i64,)> = sqlx::query_as("SELECT 1 FROM meetings WHERE id = ?")
        .bind(meeting_id)
        .fetch_optional(&mut **transaction)
        .await?;
    if exists.is_none() {
        Err(SpeakerAliasError::MeetingNotFound)
    } else {
        Ok(())
    }
}

async fn ensure_speaker_exists(
    transaction: &mut Transaction<'_, sqlx::Sqlite>,
    meeting_id: &str,
    original_speaker_label: &str,
) -> Result<(), SpeakerAliasError> {
    let exists: Option<(i64,)> =
        sqlx::query_as("SELECT 1 FROM transcripts WHERE meeting_id = ? AND speaker = ? LIMIT 1")
            .bind(meeting_id)
            .bind(original_speaker_label)
            .fetch_optional(&mut **transaction)
            .await?;
    if exists.is_none() {
        Err(SpeakerAliasError::SpeakerNotFound)
    } else {
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::database::repositories::meeting::MeetingsRepository;
    use sqlx::sqlite::SqlitePoolOptions;

    async fn test_pool() -> SqlitePool {
        let pool = SqlitePoolOptions::new()
            .max_connections(1)
            .connect("sqlite::memory:")
            .await
            .unwrap();
        sqlx::raw_sql(
            "CREATE TABLE meetings (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                folder_path TEXT
             );
             CREATE TABLE transcripts (
                id TEXT PRIMARY KEY,
                meeting_id TEXT NOT NULL,
                transcript TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                summary TEXT,
                action_items TEXT,
                key_points TEXT,
                audio_start_time REAL,
                audio_end_time REAL,
                duration REAL,
                speaker TEXT
             );
             CREATE TABLE transcript_chunks (
                meeting_id TEXT PRIMARY KEY,
                meeting_name TEXT,
                transcript_text TEXT NOT NULL,
                model TEXT NOT NULL,
                model_name TEXT NOT NULL,
                chunk_size INTEGER,
                overlap INTEGER,
                created_at TEXT NOT NULL
             );
             CREATE TABLE summary_processes (
                meeting_id TEXT PRIMARY KEY,
                status TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                error TEXT,
                result TEXT,
                start_time TEXT,
                end_time TEXT,
                chunk_count INTEGER DEFAULT 0,
                processing_time REAL DEFAULT 0.0,
                metadata TEXT,
                result_backup TEXT,
                result_backup_timestamp TEXT
             );",
        )
        .execute(&pool)
        .await
        .unwrap();
        sqlx::raw_sql(include_str!(
            "../../../migrations/20260808000000_add_speaker_aliases.sql"
        ))
        .execute(&pool)
        .await
        .unwrap();
        pool
    }

    async fn insert_meeting(pool: &SqlitePool, meeting_id: &str, speakers: &[&str]) {
        sqlx::query(
            "INSERT INTO meetings (id, title, created_at, updated_at)
             VALUES (?, 'Test meeting', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        )
        .bind(meeting_id)
        .execute(pool)
        .await
        .unwrap();
        for (index, speaker) in speakers.iter().enumerate() {
            sqlx::query(
                "INSERT INTO transcripts
                    (id, meeting_id, transcript, timestamp, speaker)
                 VALUES (?, ?, 'Hello', '00:00', ?)",
            )
            .bind(format!("{meeting_id}-transcript-{index}"))
            .bind(meeting_id)
            .bind(speaker)
            .execute(pool)
            .await
            .unwrap();
        }
    }

    #[tokio::test]
    async fn creates_updates_gets_lists_and_clears_aliases() {
        let pool = test_pool().await;
        insert_meeting(&pool, "meeting-1", &["Speaker 1", "Speaker 2"]).await;

        let created =
            SpeakerAliasesRepository::upsert(&pool, "meeting-1", "Speaker 1", "  Alice  ")
                .await
                .unwrap();
        assert_eq!(created.alias, "Alice");
        assert_eq!(
            SpeakerAliasesRepository::get(&pool, "meeting-1", "Speaker 1")
                .await
                .unwrap()
                .unwrap()
                .alias,
            "Alice"
        );

        let updated = SpeakerAliasesRepository::upsert(&pool, "meeting-1", "Speaker 1", "Alicia")
            .await
            .unwrap();
        assert_eq!(updated.alias, "Alicia");
        assert_eq!(
            SpeakerAliasesRepository::list(&pool, "meeting-1")
                .await
                .unwrap()
                .len(),
            1
        );
        assert!(
            SpeakerAliasesRepository::clear(&pool, "meeting-1", "Speaker 1")
                .await
                .unwrap()
        );
        assert!(
            SpeakerAliasesRepository::get(&pool, "meeting-1", "Speaker 1")
                .await
                .unwrap()
                .is_none()
        );
    }

    #[tokio::test]
    async fn isolates_meetings_and_preserves_original_transcript_labels() {
        let pool = test_pool().await;
        insert_meeting(&pool, "meeting-1", &["Speaker 1"]).await;
        insert_meeting(&pool, "meeting-2", &["Speaker 1"]).await;

        SpeakerAliasesRepository::upsert(&pool, "meeting-1", "Speaker 1", "Alice")
            .await
            .unwrap();
        assert!(SpeakerAliasesRepository::list(&pool, "meeting-2")
            .await
            .unwrap()
            .is_empty());

        let raw_speaker: (String,) =
            sqlx::query_as("SELECT speaker FROM transcripts WHERE meeting_id = 'meeting-1'")
                .fetch_one(&pool)
                .await
                .unwrap();
        assert_eq!(raw_speaker.0, "Speaker 1");
    }

    #[tokio::test]
    async fn rejects_invalid_and_duplicate_aliases() {
        let pool = test_pool().await;
        insert_meeting(
            &pool,
            "meeting-1",
            &["Speaker 1", "Speaker 2", UNIDENTIFIED_SPEAKER_LABEL],
        )
        .await;

        for alias in ["", "   ", "Alice\nSmith"] {
            assert!(
                SpeakerAliasesRepository::upsert(&pool, "meeting-1", "Speaker 1", alias,)
                    .await
                    .is_err()
            );
        }
        let too_long = "a".repeat(MAX_SPEAKER_ALIAS_LENGTH + 1);
        assert!(
            SpeakerAliasesRepository::upsert(&pool, "meeting-1", "Speaker 1", &too_long,)
                .await
                .is_err()
        );
        assert!(SpeakerAliasesRepository::upsert(
            &pool,
            "meeting-1",
            UNIDENTIFIED_SPEAKER_LABEL,
            "Unknown",
        )
        .await
        .is_err());
        assert!(
            SpeakerAliasesRepository::upsert(&pool, "meeting-1", "mic", "Matthew",)
                .await
                .is_err()
        );

        SpeakerAliasesRepository::upsert(&pool, "meeting-1", "Speaker 1", "Alice")
            .await
            .unwrap();
        assert!(matches!(
            SpeakerAliasesRepository::upsert(&pool, "meeting-1", "Speaker 2", "alice").await,
            Err(SpeakerAliasError::DuplicateAlias)
        ));
    }

    #[tokio::test]
    async fn meeting_deletion_removes_aliases() {
        let pool = test_pool().await;
        insert_meeting(&pool, "meeting-1", &["Speaker 1"]).await;
        SpeakerAliasesRepository::upsert(&pool, "meeting-1", "Speaker 1", "Alice")
            .await
            .unwrap();

        assert!(MeetingsRepository::delete_meeting(&pool, "meeting-1")
            .await
            .unwrap());
        let count: (i64,) =
            sqlx::query_as("SELECT COUNT(*) FROM speaker_aliases WHERE meeting_id = 'meeting-1'")
                .fetch_one(&pool)
                .await
                .unwrap();
        assert_eq!(count.0, 0);
    }

    #[tokio::test]
    async fn alias_migration_keeps_existing_meeting_and_transcript_data() {
        let pool = SqlitePoolOptions::new()
            .max_connections(1)
            .connect("sqlite::memory:")
            .await
            .unwrap();
        sqlx::raw_sql(
            "CREATE TABLE meetings (
                id TEXT PRIMARY KEY, title TEXT NOT NULL,
                created_at TEXT NOT NULL, updated_at TEXT NOT NULL
             );
             CREATE TABLE transcripts (
                id TEXT PRIMARY KEY, meeting_id TEXT NOT NULL,
                transcript TEXT NOT NULL, timestamp TEXT NOT NULL, speaker TEXT
             );
             INSERT INTO meetings VALUES
                ('legacy-meeting', 'Legacy', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
             INSERT INTO transcripts VALUES
                ('legacy-transcript', 'legacy-meeting', 'Hello', '00:00', 'Speaker 1');",
        )
        .execute(&pool)
        .await
        .unwrap();

        sqlx::raw_sql(include_str!(
            "../../../migrations/20260808000000_add_speaker_aliases.sql"
        ))
        .execute(&pool)
        .await
        .unwrap();
        let legacy: (String, String) = sqlx::query_as(
            "SELECT transcript, speaker FROM transcripts WHERE id = 'legacy-transcript'",
        )
        .fetch_one(&pool)
        .await
        .unwrap();
        assert_eq!(legacy, ("Hello".to_string(), "Speaker 1".to_string()));
        SpeakerAliasesRepository::upsert(&pool, "legacy-meeting", "Speaker 1", "Alice")
            .await
            .unwrap();
    }
}
