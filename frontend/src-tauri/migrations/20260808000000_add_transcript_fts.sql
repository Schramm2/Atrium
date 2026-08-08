-- Local full-text search for evidence-backed questions.
-- The external-content table keeps transcript text in one place. Triggers keep
-- the index current for recording, import, retranscription, and deletion flows.
CREATE VIRTUAL TABLE IF NOT EXISTS transcripts_fts USING fts5(
    transcript,
    content='transcripts',
    content_rowid='rowid',
    tokenize='unicode61 remove_diacritics 2'
);

CREATE TRIGGER IF NOT EXISTS transcripts_fts_insert AFTER INSERT ON transcripts BEGIN
    INSERT INTO transcripts_fts(rowid, transcript) VALUES (new.rowid, new.transcript);
END;

CREATE TRIGGER IF NOT EXISTS transcripts_fts_delete AFTER DELETE ON transcripts BEGIN
    INSERT INTO transcripts_fts(transcripts_fts, rowid, transcript)
    VALUES ('delete', old.rowid, old.transcript);
END;

CREATE TRIGGER IF NOT EXISTS transcripts_fts_update AFTER UPDATE OF transcript ON transcripts BEGIN
    INSERT INTO transcripts_fts(transcripts_fts, rowid, transcript)
    VALUES ('delete', old.rowid, old.transcript);
    INSERT INTO transcripts_fts(rowid, transcript) VALUES (new.rowid, new.transcript);
END;

INSERT INTO transcripts_fts(transcripts_fts) VALUES ('rebuild');

CREATE INDEX IF NOT EXISTS idx_transcripts_meeting_audio
    ON transcripts(meeting_id, audio_start_time);
