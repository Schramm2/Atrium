import type { AskAnswer, AskCitation, AskViewState } from '../../types/ask';

export type AskAction =
  | { type: 'retrieve' }
  | { type: 'confirm'; requestId: string; provider: string; evidenceCount: number }
  | { type: 'generate'; requestId: string; provider: string; evidenceCount: number }
  | { type: 'empty'; requestId: string | null; provider: string }
  | { type: 'resolve'; answer: AskAnswer }
  | { type: 'fail'; message: string }
  | { type: 'cancel' }
  | { type: 'reset' };

export const initialAskState: AskViewState = {
  phase: 'idle',
  requestId: null,
  provider: null,
  evidenceCount: 0,
  answer: null,
  error: null,
};

export function reduceAskState(state: AskViewState, action: AskAction): AskViewState {
  switch (action.type) {
    case 'retrieve':
      return { ...initialAskState, phase: 'retrieving' };
    case 'confirm':
      return {
        ...initialAskState,
        phase: 'confirming',
        requestId: action.requestId,
        provider: action.provider,
        evidenceCount: action.evidenceCount,
      };
    case 'generate':
      return {
        ...initialAskState,
        phase: 'generating',
        requestId: action.requestId,
        provider: action.provider,
        evidenceCount: action.evidenceCount,
      };
    case 'empty':
      return {
        ...initialAskState,
        phase: 'empty',
        requestId: action.requestId,
        provider: action.provider,
      };
    case 'resolve':
      return {
        ...state,
        phase: action.answer.status,
        answer: action.answer,
        provider: action.answer.provider,
        error: null,
      };
    case 'fail':
      return { ...state, phase: 'error', error: action.message, answer: null };
    case 'cancel':
      return { ...state, phase: 'cancelled', error: null };
    case 'reset':
      return initialAskState;
  }
}

export function needsExternalProviderConfirmation(
  provider: string,
  isExternalProvider: boolean,
  confirmedProviders: Iterable<string>,
): boolean {
  if (!isExternalProvider) return false;
  const normalizedProvider = provider.trim().toLocaleLowerCase();
  return !Array.from(confirmedProviders, value => value.trim().toLocaleLowerCase())
    .includes(normalizedProvider);
}

export interface ClaimCitationData {
  citation: AskCitation;
  label: string;
  href: string;
}

export function buildCitationHref(citation: AskCitation): string {
  const params = new URLSearchParams({
    id: citation.meetingId,
    segment: citation.transcriptId,
  });
  if (citation.audioStartTime !== undefined) {
    params.set('t', String(citation.audioStartTime));
  }
  return `/meeting-details?${params.toString()}`;
}

export function readCitationTarget(searchParams: Pick<URLSearchParams, 'get'>): {
  meetingId: string | null;
  segmentId: string | undefined;
  timestamp: number | undefined;
} {
  const timestampValue = searchParams.get('t');
  const parsedTimestamp = timestampValue === null ? undefined : Number(timestampValue);
  return {
    meetingId: searchParams.get('id'),
    segmentId: searchParams.get('segment') || undefined,
    timestamp: parsedTimestamp !== undefined && Number.isFinite(parsedTimestamp) ? parsedTimestamp : undefined,
  };
}

export function citationDataForClaim(
  citationIds: string[],
  citations: AskCitation[],
): ClaimCitationData[] {
  const citationsById = new Map(citations.map(citation => [citation.sourceId, citation]));
  return citationIds.flatMap(citationId => {
    const citation = citationsById.get(citationId);
    return citation
      ? [{ citation, label: `${citation.meetingTitle} · ${formatCitationTime(citation.audioStartTime, citation.timestamp)}`, href: buildCitationHref(citation) }]
      : [];
  });
}

export function formatCitationTime(audioStartTime: number | undefined, timestamp: string): string {
  if (audioStartTime === undefined) return timestamp;
  const seconds = Math.max(0, Math.floor(audioStartTime));
  const minutes = Math.floor(seconds / 60);
  return `${minutes}:${String(seconds % 60).padStart(2, '0')}`;
}
