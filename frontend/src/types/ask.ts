export type AskPhase =
  | 'idle'
  | 'retrieving'
  | 'confirming'
  | 'generating'
  | 'answered'
  | 'insufficient'
  | 'empty'
  | 'error'
  | 'cancelled';

export interface AskRequest {
  question: string;
  meetingIds: string[];
  dateFrom: string | null;
  dateTo: string | null;
  maxResults?: number;
}

export interface AskEvidence {
  sourceId: string;
  meetingId: string;
  meetingTitle: string;
  transcriptId: string;
  snippet: string;
  context: string;
  speaker?: string;
  timestamp: string;
  audioStartTime?: number;
  audioEndTime?: number;
  meetingCreatedAt: string;
  score: number;
}

export interface AskRetrievalResponse {
  /** Retrieval identifier used by answer generation and cancellation. */
  requestId: string;
  evidence: AskEvidence[];
  provider: string;
  isExternalProvider: boolean;
}

export interface AskCitation {
  sourceId: string;
  meetingId: string;
  meetingTitle: string;
  transcriptId: string;
  snippet: string;
  speaker?: string;
  timestamp: string;
  audioStartTime?: number;
  audioEndTime?: number;
}

export interface AskClaim {
  text: string;
  citationIds: string[];
}

export interface AskAnswer {
  status: 'answered' | 'insufficient';
  answer: string;
  claims: AskClaim[];
  citations: AskCitation[];
  provider: string;
  model: string;
}

export interface AskViewState {
  phase: AskPhase;
  requestId: string | null;
  provider: string | null;
  evidenceCount: number;
  answer: AskAnswer | null;
  error: string | null;
}
