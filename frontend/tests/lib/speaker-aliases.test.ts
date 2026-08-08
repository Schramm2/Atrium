import { describe, expect, test } from "bun:test";
import type { Transcript } from "../../src/types";
import {
  applySpeakerAliases,
  buildSummaryTranscriptPayload,
  convertTranscriptsToSegments,
  formatCopiedTranscriptBody,
  getRenameSpeakerAccessibleLabel,
  isAliasableSpeakerLabel,
  resolveSpeakerDisplayName,
  validateSpeakerAlias,
} from "../../src/lib/speaker-aliases";

function transcript(
  id: string,
  speaker: string | undefined,
  text: string,
  audioStartTime: number,
): Transcript {
  return {
    id,
    speaker,
    text,
    timestamp: "14:30:05",
    audio_start_time: audioStartTime,
  };
}

describe("speaker alias validation", () => {
  test("trims a valid alias", () => {
    expect(validateSpeakerAlias("  Alice  ")).toEqual({
      valid: true,
      alias: "Alice",
    });
  });

  test("rejects empty, long, and control-character aliases", () => {
    expect(validateSpeakerAlias(" \t ")).toMatchObject({ valid: false, error: "empty" });
    expect(validateSpeakerAlias("😀".repeat(81))).toMatchObject({
      valid: false,
      error: "too_long",
    });
    expect(validateSpeakerAlias("Alice\u0007")).toMatchObject({
      valid: false,
      error: "control_character",
    });
    expect(validateSpeakerAlias("Alice\n")).toMatchObject({
      valid: false,
      error: "control_character",
    });
  });

  test("rejects duplicate aliases without blocking the speaker being edited", () => {
    const existingAliases = {
      "Speaker 1": "Alice",
      "Speaker 2": "Bob",
    };

    expect(validateSpeakerAlias(" alice ", { existingAliases })).toMatchObject({
      valid: false,
      error: "duplicate",
    });
    expect(
      validateSpeakerAlias(" Alice ", {
        existingAliases,
        originalSpeakerLabel: "Speaker 1",
      }),
    ).toEqual({ valid: true, alias: "Alice" });
  });

  test("only accepts exact positive-integer Speaker labels for aliasing", () => {
    expect(isAliasableSpeakerLabel("Speaker 1")).toBe(true);
    expect(isAliasableSpeakerLabel("Speaker 42")).toBe(true);
    expect(isAliasableSpeakerLabel("Speaker 0")).toBe(false);
    expect(isAliasableSpeakerLabel("Speaker 01")).toBe(false);
    expect(isAliasableSpeakerLabel(" Speaker 1")).toBe(false);
    expect(isAliasableSpeakerLabel("Unidentified speaker")).toBe(false);
  });
});

describe("speaker alias resolution", () => {
  const rawTranscripts = [
    transcript("1", "Speaker 1", "First point", 1),
    transcript("2", "Speaker 2", "Reply", 65),
    transcript("3", "Speaker 1", "Second point", 125),
    transcript("4", "Unidentified speaker", "Background speech", 126),
  ];

  test("renders one alias across repeated segments and preserves raw labels", () => {
    const resolved = applySpeakerAliases(rawTranscripts, {
      "Speaker 1": "Alice",
      "Unidentified speaker": "Unsafe alias",
    });

    expect(resolved.map(resolveSpeakerDisplayName)).toEqual([
      "Alice",
      "Speaker 2",
      "Alice",
      "Unidentified speaker",
    ]);
    expect(resolved.map((row) => row.speaker)).toEqual(
      rawTranscripts.map((row) => row.speaker),
    );
  });

  test("uses the same display values for separate paginated batches", () => {
    const aliases = { "Speaker 1": "Alice" };
    const firstPage = convertTranscriptsToSegments(
      applySpeakerAliases(rawTranscripts.slice(0, 2), aliases),
    );
    const secondPage = convertTranscriptsToSegments(
      applySpeakerAliases(rawTranscripts.slice(2), aliases),
    );

    expect(firstPage[0]).toMatchObject({
      speaker: "Speaker 1",
      speakerDisplayName: "Alice",
    });
    expect(secondPage[0]).toMatchObject({
      speaker: "Speaker 1",
      speakerDisplayName: "Alice",
    });
    expect(firstPage[1]).toMatchObject({
      speaker: "Speaker 2",
      speakerDisplayName: "Speaker 2",
    });
  });

  test("formats copied transcript text with resolved names", () => {
    const resolved = applySpeakerAliases(rawTranscripts.slice(0, 3), {
      "Speaker 1": "Alice",
    });

    expect(formatCopiedTranscriptBody(resolved)).toBe(
      "[00:01] Alice: First point  \n" +
        "[01:05] Speaker 2: Reply  \n" +
        "[02:05] Alice: Second point  ",
    );
  });

  test("builds generation input with aliases in both transcript forms", () => {
    const resolved = applySpeakerAliases(rawTranscripts.slice(0, 3), {
      "Speaker 1": "Alice",
    });

    expect(buildSummaryTranscriptPayload(resolved)).toEqual({
      transcriptText:
        "[00:01] Alice: First point\n" +
        "[01:05] Speaker 2: Reply\n" +
        "[02:05] Alice: Second point",
      transcriptTexts: [
        "Alice: First point",
        "Speaker 2: Reply",
        "Alice: Second point",
      ],
    });
  });

  test("provides an accessible rename label with original-label context", () => {
    expect(getRenameSpeakerAccessibleLabel("Speaker 1", "Alice")).toBe(
      "Rename Alice, original label Speaker 1",
    );
    expect(getRenameSpeakerAccessibleLabel("Speaker 2", "Speaker 2")).toBe(
      "Rename Speaker 2",
    );
  });
});
