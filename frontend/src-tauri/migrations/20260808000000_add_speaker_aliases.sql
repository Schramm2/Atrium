CREATE TABLE IF NOT EXISTS speaker_aliases (
    meeting_id TEXT NOT NULL,
    original_speaker_label TEXT NOT NULL,
    alias TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (meeting_id, original_speaker_label),
    FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_speaker_aliases_meeting_alias_nocase
    ON speaker_aliases(meeting_id, alias COLLATE NOCASE);
