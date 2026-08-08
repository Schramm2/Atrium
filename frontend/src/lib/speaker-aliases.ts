import type { Transcript, TranscriptSegmentData } from "@/types";

export const MAX_SPEAKER_ALIAS_LENGTH = 80;
export const UNIDENTIFIED_SPEAKER_LABEL = "Unidentified speaker";

export type TranscriptWithSpeakerDisplayName = Transcript & {
  speaker_display_name?: string;
};

export type ResolvedTranscriptSegmentData = TranscriptSegmentData & {
  /** The immutable diarization label stored with the transcript. */
  speaker?: string;
  /** The alias shown to the user, or the raw label when no alias exists. */
  speakerDisplayName?: string;
};

export type SpeakerAliasMap = Readonly<Record<string, string>>;

export type SpeakerAliasValidationError =
  | "empty"
  | "too_long"
  | "control_character"
  | "duplicate";

export type SpeakerAliasValidationResult =
  | { valid: true; alias: string }
  | { valid: false; error: SpeakerAliasValidationError; message: string };

export interface ValidateSpeakerAliasOptions {
  existingAliases?: SpeakerAliasMap;
  /** Excludes the current speaker when an existing alias is edited. */
  originalSpeakerLabel?: string;
}

export interface SummaryTranscriptPayload {
  transcriptText: string;
  transcriptTexts: string[];
}

/** Only numbered anonymous diarization labels can receive an alias. */
export function isAliasableSpeakerLabel(label: string | null | undefined): boolean {
  return typeof label === "string" && /^Speaker [1-9]\d*$/.test(label);
}

export function validateSpeakerAlias(
  value: string,
  options: ValidateSpeakerAliasOptions = {},
): SpeakerAliasValidationResult {
  const alias = value.trim();

  if (alias.length === 0) {
    return {
      valid: false,
      error: "empty",
      message: "Enter a speaker name.",
    };
  }

  if (Array.from(alias).length > MAX_SPEAKER_ALIAS_LENGTH) {
    return {
      valid: false,
      error: "too_long",
      message: `Speaker names must be ${MAX_SPEAKER_ALIAS_LENGTH} characters or fewer.`,
    };
  }

  if (/\p{Cc}/u.test(value)) {
    return {
      valid: false,
      error: "control_character",
      message: "Speaker names cannot contain control characters.",
    };
  }

  const duplicate = Object.entries(options.existingAliases ?? {}).some(
    ([speakerLabel, existingAlias]) =>
      speakerLabel !== options.originalSpeakerLabel &&
      existingAlias.trim().toLowerCase() === alias.toLowerCase(),
  );

  if (duplicate) {
    return {
      valid: false,
      error: "duplicate",
      message: "This speaker name is already used in this meeting.",
    };
  }

  return { valid: true, alias };
}

/** Resolves a display name without changing the stored diarization label. */
export function resolveSpeakerDisplayName(
  transcript: TranscriptWithSpeakerDisplayName,
): string | undefined {
  const displayName = transcript.speaker_display_name?.trim();
  return displayName || transcript.speaker;
}

/** Adds resolved display names while preserving every raw `speaker` value. */
export function applySpeakerAliases(
  transcripts: readonly Transcript[],
  aliases: SpeakerAliasMap,
): TranscriptWithSpeakerDisplayName[] {
  return transcripts.map((transcript) => {
    const alias = transcript.speaker && isAliasableSpeakerLabel(transcript.speaker)
      ? aliases[transcript.speaker]?.trim()
      : undefined;

    return alias
      ? { ...transcript, speaker_display_name: alias }
      : { ...transcript };
  });
}

/** Converts transcript rows for both simple and virtualized transcript views. */
export function convertTranscriptsToSegments(
  transcripts: readonly TranscriptWithSpeakerDisplayName[],
): ResolvedTranscriptSegmentData[] {
  return transcripts.map((transcript) => ({
    id: transcript.id,
    timestamp: transcript.audio_start_time ?? 0,
    endTime: transcript.audio_end_time,
    text: transcript.text,
    confidence: transcript.confidence,
    speaker: transcript.speaker,
    speakerDisplayName: resolveSpeakerDisplayName(transcript),
  }));
}

export function formatTranscriptTime(
  seconds: number | undefined,
  fallbackTimestamp: string,
): string {
  if (seconds === undefined) return fallbackTimestamp;

  const totalSeconds = Math.floor(seconds);
  const minutes = Math.floor(totalSeconds / 60);
  const remainingSeconds = totalSeconds % 60;
  return `[${minutes.toString().padStart(2, "0")}:${remainingSeconds
    .toString()
    .padStart(2, "0")}]`;
}

/** Formats the transcript rows used in saved-meeting clipboard output. */
export function formatCopiedTranscriptBody(
  transcripts: readonly TranscriptWithSpeakerDisplayName[],
): string {
  return transcripts
    .map((transcript) => {
      const speaker = resolveSpeakerDisplayName(transcript);
      const prefix = speaker ? `${speaker}: ` : "";
      return `${formatTranscriptTime(
        transcript.audio_start_time,
        transcript.timestamp,
      )} ${prefix}${transcript.text}  `;
    })
    .join("\n");
}

/** Builds the complete saved transcript input used for generation and regeneration. */
export function buildSummaryTranscriptPayload(
  transcripts: readonly TranscriptWithSpeakerDisplayName[],
): SummaryTranscriptPayload {
  return {
    transcriptText: transcripts
      .map((transcript) => {
        const speaker = resolveSpeakerDisplayName(transcript);
        const prefix = speaker ? `${speaker}: ` : "";
        return `${formatTranscriptTime(
          transcript.audio_start_time,
          transcript.timestamp,
        )} ${prefix}${transcript.text}`;
      })
      .join("\n"),
    transcriptTexts: transcripts.map((transcript) => {
      const speaker = resolveSpeakerDisplayName(transcript);
      return `${speaker ? `${speaker}: ` : ""}${transcript.text}`;
    }),
  };
}

export function getRenameSpeakerAccessibleLabel(
  originalSpeakerLabel: string,
  displayName?: string,
): string {
  const resolvedDisplayName = displayName?.trim();
  if (resolvedDisplayName && resolvedDisplayName !== originalSpeakerLabel) {
    return `Rename ${resolvedDisplayName}, original label ${originalSpeakerLabel}`;
  }
  return `Rename ${originalSpeakerLabel}`;
}
