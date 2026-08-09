'use client';

import { FormEvent, useCallback, useReducer, useRef, useState } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { useRouter } from 'next/navigation';
import { ArrowUp, Loader2, RotateCcw, Sparkles, Square } from 'lucide-react';
import { useSidebar } from '@/components/Sidebar/SidebarProvider';
import { AnswerView } from '@/components/AskUbundiMeet/AnswerView';
import { ScopeControls } from '@/components/AskUbundiMeet/ScopeControls';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { initialAskState, needsExternalProviderConfirmation, reduceAskState } from '@/lib/ask/logic';
import type { AskAnswer, AskRequest, AskRetrievalResponse } from '@/types/ask';

const CONFIRMED_PROVIDERS_KEY = 'ask-confirmed-external-providers';

function readConfirmedProviders(): string[] {
  try {
    return JSON.parse(sessionStorage.getItem(CONFIRMED_PROVIDERS_KEY) || '[]');
  } catch {
    return [];
  }
}

export default function AskUbundiMeetPage() {
  const router = useRouter();
  const { meetings } = useSidebar();
  const [state, dispatch] = useReducer(reduceAskState, initialAskState);
  const [question, setQuestion] = useState('');
  const [selectedMeetingIds, setSelectedMeetingIds] = useState<string[]>([]);
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [scopeExpanded, setScopeExpanded] = useState(false);
  const activeOperation = useRef(0);
  const lastRequest = useRef<AskRequest | null>(null);

  const generateAnswer = useCallback(async (
    retrieval: Pick<AskRetrievalResponse, 'requestId' | 'provider' | 'isExternalProvider'> & { evidenceCount: number },
    request: AskRequest,
    operation: number,
  ) => {
    dispatch({ type: 'generate', requestId: retrieval.requestId, provider: retrieval.provider, evidenceCount: retrieval.evidenceCount });
    try {
      const answer = await invoke<AskAnswer>('api_generate_ask_answer', {
        request: {
          requestId: retrieval.requestId,
          provider: retrieval.provider,
          ...request,
          externalEvidenceConfirmed: retrieval.isExternalProvider,
        },
      });
      if (activeOperation.current === operation) dispatch({ type: 'resolve', answer });
    } catch (error) {
      if (activeOperation.current === operation) {
        dispatch({ type: 'fail', message: error instanceof Error ? error.message : String(error) });
      }
    }
  }, []);

  const runAsk = useCallback(async (request: AskRequest) => {
    const operation = ++activeOperation.current;
    lastRequest.current = request;
    dispatch({ type: 'retrieve' });
    try {
      const retrieval = await invoke<AskRetrievalResponse>('api_retrieve_ask_evidence', { request });
      if (activeOperation.current !== operation) return;
      if (retrieval.evidence.length === 0) {
        dispatch({ type: 'empty', requestId: retrieval.requestId || null, provider: retrieval.provider });
        return;
      }
      if (!retrieval.requestId) throw new Error('Ask retrieval did not return a request identifier.');

      if (needsExternalProviderConfirmation(retrieval.provider, retrieval.isExternalProvider, readConfirmedProviders())) {
        dispatch({ type: 'confirm', requestId: retrieval.requestId, provider: retrieval.provider, evidenceCount: retrieval.evidence.length });
        return;
      }
      await generateAnswer({ ...retrieval, evidenceCount: retrieval.evidence.length }, request, operation);
    } catch (error) {
      if (activeOperation.current === operation) {
        dispatch({ type: 'fail', message: error instanceof Error ? error.message : String(error) });
      }
    }
  }, [generateAnswer]);

  const submit = (event: FormEvent) => {
    event.preventDefault();
    const normalizedQuestion = question.trim();
    if (!normalizedQuestion) return;
    runAsk({
      question: normalizedQuestion,
      meetingIds: selectedMeetingIds,
      dateFrom: dateFrom || null,
      dateTo: dateTo || null,
    });
  };

  const confirmExternalProvider = async () => {
    if (!lastRequest.current || !state.requestId || !state.provider) return;
    const confirmed = Array.from(new Set([...readConfirmedProviders(), state.provider]));
    sessionStorage.setItem(CONFIRMED_PROVIDERS_KEY, JSON.stringify(confirmed));
    const operation = activeOperation.current;
    await generateAnswer({
      requestId: state.requestId,
      evidenceCount: state.evidenceCount,
      provider: state.provider,
      isExternalProvider: true,
    }, lastRequest.current, operation);
  };

  const cancel = async () => {
    const requestId = state.requestId;
    ++activeOperation.current;
    dispatch({ type: 'cancel' });
    if (requestId) {
      try { await invoke<boolean>('api_cancel_ask', { requestId }); } catch (error) { console.error('Failed to cancel Ask request:', error); }
    }
  };

  const isWorking = state.phase === 'retrieving' || state.phase === 'generating';

  return (
    <div className="ask-page min-h-screen px-5 py-10 md:px-10">
      <div className="mx-auto max-w-3xl">
        <div className="ask-heading mb-8 flex items-center gap-3">
          <span className="ask-heading-icon flex size-10 items-center justify-center rounded-xl"><Sparkles className="size-5" /></span>
          <h1 className="text-2xl font-semibold tracking-tight">Ask Ubundi Meet</h1>
        </div>

        <form onSubmit={submit} className="ask-composer rounded-2xl border p-4 md:p-5">
          <label htmlFor="ask-question" className="sr-only">Question</label>
          <textarea
            id="ask-question"
            value={question}
            onChange={event => setQuestion(event.target.value)}
            placeholder="What decisions did we make about the launch?"
            rows={4}
            disabled={isWorking}
            className="ask-question w-full resize-none bg-transparent text-lg leading-7 outline-none disabled:opacity-60"
            onKeyDown={event => {
              if (event.key === 'Enter' && !event.shiftKey) {
                event.preventDefault();
                event.currentTarget.form?.requestSubmit();
              }
            }}
          />
          <ScopeControls
            meetings={meetings}
            selectedMeetingIds={selectedMeetingIds}
            dateFrom={dateFrom}
            dateTo={dateTo}
            expanded={scopeExpanded}
            onExpandedChange={setScopeExpanded}
            onSelectedMeetingIdsChange={setSelectedMeetingIds}
            onDateFromChange={setDateFrom}
            onDateToChange={setDateTo}
          />
          <div className="mt-4 flex items-center justify-between gap-3">
            <span className="ask-support-copy text-xs">Answers use only cited meeting transcript evidence.</span>
            {isWorking ? (
              <Button type="button" variant="outline" onClick={cancel}><Square className="size-3 fill-current" />Cancel</Button>
            ) : (
              <Button type="submit" disabled={!question.trim()} className="ask-submit">
                Ask <ArrowUp className="size-4" />
              </Button>
            )}
          </div>
        </form>

        <div className="mt-8">
          {state.phase === 'retrieving' && <ProgressLine label="Finding relevant transcript evidence…" />}
          {state.phase === 'generating' && <ProgressLine label={`Writing an answer from ${state.evidenceCount} source${state.evidenceCount === 1 ? '' : 's'}…`} />}
          {state.phase === 'empty' && <ResultMessage text="No relevant transcript evidence was found in this scope." onRetry={() => lastRequest.current && runAsk(lastRequest.current)} />}
          {state.phase === 'insufficient' && state.answer && <AnswerView answer={state.answer} onNavigate={router.push} />}
          {state.phase === 'answered' && state.answer && <AnswerView answer={state.answer} onNavigate={router.push} />}
          {state.phase === 'error' && <ResultMessage text="Ubundi Meet could not complete this answer." detail={state.error || undefined} onRetry={() => lastRequest.current && runAsk(lastRequest.current)} />}
          {state.phase === 'cancelled' && <ResultMessage text="The request was cancelled." onRetry={() => lastRequest.current && runAsk(lastRequest.current)} />}
        </div>
      </div>

      <Dialog open={state.phase === 'confirming'} onOpenChange={open => { if (!open) cancel(); }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Send evidence to {state.provider}</DialogTitle>
            <DialogDescription>
              {state.provider} is an external AI provider. If you continue, the retrieved meeting evidence and your question will be sent to this provider. This confirmation applies for this app session.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={cancel}>Cancel</Button>
            <Button onClick={confirmExternalProvider} className="ask-submit">Continue</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function ProgressLine({ label }: { label: string }) {
  return <div className="ask-progress flex items-center gap-3 py-5 text-sm" role="status"><Loader2 className="ask-progress-icon size-5 animate-spin" />{label}</div>;
}

function ResultMessage({ text, detail, onRetry }: { text: string; detail?: string; onRetry: () => void }) {
  return (
    <div className="ask-result rounded-xl border p-5">
      <p className="ask-result-title font-medium">{text}</p>
      {detail && <p className="ask-result-detail mt-1 text-sm">{detail}</p>}
      <Button variant="outline" size="sm" className="mt-4" onClick={onRetry}><RotateCcw className="size-4" />Retry</Button>
    </div>
  );
}
