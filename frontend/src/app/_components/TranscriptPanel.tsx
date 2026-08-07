import { VirtualizedTranscriptView } from '@/components/VirtualizedTranscriptView';
import { PermissionWarning } from '@/components/PermissionWarning';
import { Button } from '@/components/ui/button';
import { ButtonGroup } from '@/components/ui/button-group';
import { Copy, GlobeIcon } from 'lucide-react';
import { useTranscripts } from '@/contexts/TranscriptContext';
import { useConfig } from '@/contexts/ConfigContext';
import { useRecordingState } from '@/contexts/RecordingStateContext';
import { usePermissionCheck } from '@/hooks/usePermissionCheck';
import { ModalType } from '@/hooks/useModalState';
import { useIsLinux } from '@/hooks/usePlatform';
import { useMemo } from 'react';

/**
 * TranscriptPanel Component
 *
 * Displays transcript content with controls for copying and language settings.
 * Uses TranscriptContext, ConfigContext, and RecordingStateContext internally.
 */

interface TranscriptPanelProps {
  // indicates stop-processing state for transcripts; derived from backend statuses.
  isProcessingStop: boolean;
  isStopping: boolean;
  showModal: (name: ModalType, message?: string) => void;
  onStartRecording?: () => void;
}

export function TranscriptPanel({
  isProcessingStop,
  isStopping,
  showModal,
  onStartRecording,
}: TranscriptPanelProps) {
  // Contexts
  const { transcripts, transcriptContainerRef, copyTranscript } = useTranscripts();
  const { transcriptModelConfig } = useConfig();
  const { isRecording, isPaused } = useRecordingState();
  const { checkPermissions, isChecking, hasSystemAudio, hasMicrophone } = usePermissionCheck();
  const isLinux = useIsLinux();

  // Convert transcripts to segments for virtualized view
  const segments = useMemo(() =>
    transcripts.map(t => ({
      id: t.id,
      timestamp: t.audio_start_time ?? 0,
      endTime: t.audio_end_time,
      text: t.text,
      confidence: t.confidence,
    })),
    [transcripts]
  );

  return (
    <div ref={transcriptContainerRef} className="ubundi-transcript-surface overflow-hidden">
      <header className="ubundi-transcript-header">
        <div>
          <p className="ubundi-eyebrow">Ubundi Meet · Private workspace</p>
          <h1 className="ubundi-transcript-title">Conversation capture</h1>
          <p className="ubundi-transcript-subtitle">
            Record, transcribe, and keep the context of important conversations close to the work.
          </p>
        </div>
        <div className="flex flex-col items-end gap-3">
          <span className="ubundi-status-pill">On-device by default</span>
          <ButtonGroup>
            {transcripts?.length > 0 && (
              <Button
                variant="outline"
                size="sm"
                onClick={copyTranscript}
                title="Copy Transcript"
              >
                <Copy />
                <span className='hidden md:inline'>Copy</span>
              </Button>
            )}
            {transcriptModelConfig.provider === "localWhisper" &&
              <Button
                variant="outline"
                size="sm"
                onClick={() => showModal('languageSettings')}
                title="Language"
              >
                <GlobeIcon />
                <span className='hidden md:inline'>Language</span>
              </Button>
            }
          </ButtonGroup>
        </div>
      </header>

      <div className="ubundi-transcript-body">

      {/* Permission Warning - Not needed on Linux */}
      {!isRecording && !isChecking && !isLinux && (
        <div className="flex justify-center px-4 pt-4">
          <PermissionWarning
            hasMicrophone={hasMicrophone}
            hasSystemAudio={hasSystemAudio}
            onRecheck={checkPermissions}
            isRechecking={isChecking}
          />
        </div>
      )}

      {/* Transcript content */}
      <div className="pb-20">
        <div className="flex w-full justify-center">
          <div className="w-full max-w-[960px]">
            <VirtualizedTranscriptView
              segments={segments}
              isRecording={isRecording}
              isPaused={isPaused}
              isProcessing={isProcessingStop}
              isStopping={isStopping}
              enableStreaming={isRecording}
              showConfidence={true}
              onStartRecording={onStartRecording}
            />
          </div>
        </div>
      </div>
      </div>
    </div>
  );
}
