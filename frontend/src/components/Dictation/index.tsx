'use client';

import type { ReactNode } from 'react';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  AudioLines,
  Check,
  Clipboard,
  Command,
  Cpu,
  Keyboard,
  LockKeyhole,
  Mic,
  ShieldCheck,
  Square,
  X,
} from 'lucide-react';
import { dictationService } from '@/services/dictationService';
import {
  DEFAULT_DICTATION_STATUS,
  type DictationResult,
  type DictationState,
  type DictationStatus,
} from '@/types/dictation';
import { BrandWordmark } from '@/components/BrandIdentity';

interface DictationWorkspaceProps {
  renderHeader: (status: ReactNode) => ReactNode;
}

const STATE_LABELS: Record<DictationState, string> = {
  idle: 'Ready',
  starting: 'Starting',
  recording: 'Listening',
  transcribing: 'Writing',
  completed: 'Ready',
  cancelled: 'Cancelled',
  error: 'Needs attention',
};

export function DictationWorkspace({ renderHeader }: DictationWorkspaceProps) {
  const [status, setStatus] = useState<DictationStatus>(DEFAULT_DICTATION_STATUS);
  const [lastResult, setLastResult] = useState<DictationResult | null>(null);
  const [pendingAction, setPendingAction] = useState<'start' | 'stop' | 'cancel' | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    let disposed = false;
    const cleanups: Array<() => void> = [];

    Promise.all([
      dictationService.onStateChanged((nextStatus) => {
        if (!disposed) {
          setStatus(nextStatus);
          setNotice(nextStatus.error);
        }
      }),
      dictationService.onResult((result) => {
        if (!disposed) {
          setLastResult(result);
          setCopied(false);
          setNotice(null);
        }
      }),
    ])
      .then((unlisten) => cleanups.push(...unlisten))
      .catch((error) => {
        if (!disposed) setNotice(toMessage(error, 'Dictation events are unavailable.'));
      });

    dictationService
      .getStatus()
      .then((nextStatus) => {
        if (!disposed) setStatus(nextStatus);
      })
      .catch((error) => {
        if (!disposed) setNotice(toMessage(error, 'Dictation status is unavailable.'));
      });

    return () => {
      disposed = true;
      cleanups.forEach((cleanup) => cleanup());
    };
  }, []);

  const runAction = useCallback(async (action: 'start' | 'stop' | 'cancel') => {
    setPendingAction(action);
    setNotice(null);
    setCopied(false);

    if (action === 'start') {
      setStatus((current) => ({ ...current, state: 'starting', error: null }));
    }

    try {
      await dictationService[action]();
      setStatus(await dictationService.getStatus());
    } catch (error) {
      setNotice(toMessage(error, `Could not ${action} dictation.`));
      try {
        setStatus(await dictationService.getStatus());
      } catch {
        setStatus((current) => ({ ...current, state: 'error' }));
      }
    } finally {
      setPendingAction(null);
    }
  }, []);

  const copyResult = useCallback(async () => {
    if (!lastResult?.text) return;
    try {
      await navigator.clipboard.writeText(lastResult.text);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1800);
    } catch (error) {
      setNotice(toMessage(error, 'Could not copy the last result.'));
    }
  }, [lastResult]);

  const isRecording = status.state === 'recording';
  const isBusy = status.state === 'starting' || status.state === 'transcribing';
  const stateLabel = STATE_LABELS[status.state];

  const headerStatus = useMemo(
    () => (
      <span className={`ubundi-dictation-state ubundi-dictation-state-${status.state}`} role="status">
        <span aria-hidden="true" />
        {stateLabel}
      </span>
    ),
    [stateLabel, status.state],
  );

  return (
    <>
      {renderHeader(headerStatus)}
      <main className="ubundi-dictation-content">
        <section className={`ubundi-dictation-console ubundi-dictation-console-${status.state}`} aria-labelledby="dictation-workspace-title">
          <div className="ubundi-dictation-console-copy">
            <p className="ubundi-dictation-kicker">Current state</p>
            <h2 id="dictation-workspace-title">{isRecording ? 'Speak naturally.' : status.state === 'transcribing' ? 'Turning speech into text.' : 'Ready when you are.'}</h2>
            <p>
              {isRecording
                ? 'Release the shortcut or stop here when you finish. Ubundi Meet will insert the result in the active app.'
                : status.state === 'transcribing'
                  ? 'Your local model is processing the recording.'
                  : 'Hold the shortcut anywhere, or start here.'}
            </p>

            <div className="ubundi-dictation-actions">
              {isRecording ? (
                <button className="ubundi-dictation-primary" type="button" onClick={() => runAction('stop')} disabled={pendingAction !== null}>
                  <Square aria-hidden="true" />
                  {pendingAction === 'stop' ? 'Stopping…' : 'Stop and transcribe'}
                </button>
              ) : (
                <button className="ubundi-dictation-primary" type="button" onClick={() => runAction('start')} disabled={isBusy || pendingAction !== null}>
                  <Mic aria-hidden="true" />
                  {status.state === 'starting' ? 'Starting…' : status.state === 'transcribing' ? 'Transcribing…' : 'Start dictation'}
                </button>
              )}
              {(isRecording || isBusy) && (
                <button className="ubundi-dictation-secondary" type="button" onClick={() => runAction('cancel')} disabled={pendingAction !== null}>
                  <X aria-hidden="true" />
                  {pendingAction === 'cancel' ? 'Cancelling…' : 'Cancel'}
                </button>
              )}
            </div>
          </div>

          <div className="ubundi-dictation-visual" aria-hidden="true">
            <BrandWordmark priority />
            <div className="ubundi-dictation-wave">
              {[16, 34, 54, 76, 46, 66, 88, 58, 38, 70, 50, 26].map((height, index) => (
                <span key={index} style={{ height: `${height}%` }} />
              ))}
            </div>
          </div>
        </section>

        {notice && (
          <div className="ubundi-dictation-notice" role="alert">
            <span>{notice}</span>
            <button type="button" onClick={() => setNotice(null)} aria-label="Dismiss message"><X /></button>
          </div>
        )}

        <section className="ubundi-dictation-details" aria-label="Dictation setup">
          <InfoRow icon={<Keyboard />} label="Shortcut" value={status.shortcut || 'Not set'} aside={<kbd>{status.shortcut || 'Not set'}</kbd>} />
          <InfoRow icon={<Mic />} label="Microphone" value={status.microphone || 'System default'} />
          <InfoRow icon={<Cpu />} label="Model" value={status.model || 'Local speech model'} />
        </section>

        <section className="ubundi-dictation-result" aria-labelledby="last-result-title">
          <div className="ubundi-dictation-section-heading">
            <div>
              <p className="ubundi-dictation-kicker">Output</p>
              <h2 id="last-result-title">Last result</h2>
            </div>
            <button type="button" onClick={copyResult} disabled={!lastResult?.text} className="ubundi-dictation-copy">
              {copied ? <Check aria-hidden="true" /> : <Clipboard aria-hidden="true" />}
              {copied ? 'Copied' : 'Copy'}
            </button>
          </div>
          <div className={`ubundi-dictation-result-text ${lastResult?.text ? '' : 'is-empty'}`}>
            {lastResult?.text || 'Your latest dictation will appear here.'}
          </div>
        </section>

        <div className="ubundi-dictation-support-grid">
          <section className="ubundi-dictation-support" aria-labelledby="privacy-title">
            <div className="ubundi-dictation-support-icon"><ShieldCheck aria-hidden="true" /></div>
            <div>
              <h2 id="privacy-title">Private by default</h2>
              <p>Speech is processed on this device. {status.retains_audio ? 'Audio retention is on.' : 'Audio is not retained after transcription.'}</p>
              <span className="ubundi-dictation-detail"><LockKeyhole aria-hidden="true" />No cloud upload</span>
            </div>
          </section>

          <section className="ubundi-dictation-support" aria-labelledby="accessibility-title">
            <div className="ubundi-dictation-support-icon"><Command aria-hidden="true" /></div>
            <div>
              <h2 id="accessibility-title">Accessibility access</h2>
              <p>{status.accessibility_granted ? 'Access is ready. Ubundi Meet can insert text in the active app.' : 'Allow Ubundi Meet in System Settings → Privacy & Security → Accessibility, then restart Ubundi Meet.'}</p>
              <span className={`ubundi-dictation-detail ${status.accessibility_granted ? 'is-ready' : ''}`}>
                {status.accessibility_granted ? <Check aria-hidden="true" /> : <AudioLines aria-hidden="true" />}
                {status.accessibility_granted ? 'Access granted' : 'Access required for text insertion'}
              </span>
            </div>
          </section>
        </div>
      </main>
    </>
  );
}

function InfoRow({ icon, label, value, aside }: { icon: ReactNode; label: string; value: string; aside?: ReactNode }) {
  return (
    <div className="ubundi-dictation-info-row">
      <span className="ubundi-dictation-info-icon" aria-hidden="true">{icon}</span>
      <div>
        <span>{label}</span>
        <strong>{value}</strong>
      </div>
      {aside}
    </div>
  );
}

function toMessage(error: unknown, fallback: string): string {
  if (typeof error === 'string' && error.trim()) return error;
  if (error instanceof Error && error.message.trim()) return error.message;
  return fallback;
}
