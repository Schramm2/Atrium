import { beforeEach, describe, expect, mock, test } from "bun:test";

const invokeMock = mock(async () => null);

mock.module("@tauri-apps/api/core", () => ({
  invoke: invokeMock,
}));

describe("speaker alias service", () => {
  beforeEach(() => {
    invokeMock.mockReset();
  });

  test("saves an edited alias with a typed request", async () => {
    const service = await import("../../src/services/speakerAliasService");
    const saved = {
      meeting_id: "meeting-1",
      original_speaker_label: "Speaker 1",
      alias: "Alicia",
      created_at: "2026-08-08T00:00:00Z",
      updated_at: "2026-08-08T00:01:00Z",
    };
    invokeMock.mockResolvedValueOnce(saved);

    await expect(service.saveSpeakerAlias({
      meeting_id: "meeting-1",
      original_speaker_label: "Speaker 1",
      alias: "Alicia",
    })).resolves.toEqual(saved);
    expect(invokeMock).toHaveBeenCalledWith("api_save_speaker_alias", {
      request: {
        meeting_id: "meeting-1",
        original_speaker_label: "Speaker 1",
        alias: "Alicia",
      },
    });
  });

  test("clears an alias without changing transcript data", async () => {
    const service = await import("../../src/services/speakerAliasService");
    invokeMock.mockResolvedValueOnce({ cleared: true });

    await expect(service.clearSpeakerAlias({
      meeting_id: "meeting-1",
      original_speaker_label: "Speaker 1",
    })).resolves.toBe(true);
    expect(invokeMock).toHaveBeenCalledWith("api_clear_speaker_alias", {
      request: {
        meeting_id: "meeting-1",
        original_speaker_label: "Speaker 1",
      },
    });
  });
});
