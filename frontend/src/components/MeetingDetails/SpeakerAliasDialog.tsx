"use client";

import { FormEvent, useEffect, useState } from 'react';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { clearSpeakerAlias, saveSpeakerAlias } from '@/services/speakerAliasService';
import { validateSpeakerAlias } from '@/lib/speaker-aliases';

interface SpeakerAliasDialogProps {
  meetingId: string;
  originalSpeakerLabel: string | null;
  displaySpeakerName: string | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onChanged: () => Promise<void> | void;
}

export function SpeakerAliasDialog({
  meetingId,
  originalSpeakerLabel,
  displaySpeakerName,
  open,
  onOpenChange,
  onChanged,
}: SpeakerAliasDialogProps) {
  const hasAlias = Boolean(
    originalSpeakerLabel
    && displaySpeakerName
    && originalSpeakerLabel !== displaySpeakerName,
  );
  const [alias, setAlias] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (open) {
      setAlias(hasAlias ? displaySpeakerName ?? '' : '');
      setError(null);
    }
  }, [open, hasAlias, displaySpeakerName, originalSpeakerLabel]);

  const handleSave = async (event: FormEvent) => {
    event.preventDefault();
    if (!originalSpeakerLabel) return;

    const validation = validateSpeakerAlias(alias);
    if (!validation.valid) {
      setError(validation.message);
      return;
    }

    setIsSaving(true);
    setError(null);
    try {
      await saveSpeakerAlias({
        meeting_id: meetingId,
        original_speaker_label: originalSpeakerLabel,
        alias: validation.alias,
      });
      await onChanged();
      toast.success('Speaker name saved');
      onOpenChange(false);
    } catch (saveError) {
      setError(String(saveError));
    } finally {
      setIsSaving(false);
    }
  };

  const handleClear = async () => {
    if (!originalSpeakerLabel) return;
    setIsSaving(true);
    setError(null);
    try {
      await clearSpeakerAlias({
        meeting_id: meetingId,
        original_speaker_label: originalSpeakerLabel,
      });
      await onChanged();
      toast.success('Speaker name cleared');
      onOpenChange(false);
    } catch (clearError) {
      setError(String(clearError));
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-sm">
        <form onSubmit={handleSave}>
          <DialogHeader>
            <DialogTitle>Rename speaker</DialogTitle>
          </DialogHeader>
          <div className="space-y-3 py-4">
            <div className="space-y-1.5">
              <Label htmlFor="speaker-alias">{originalSpeakerLabel}</Label>
              <Input
                id="speaker-alias"
                autoFocus
                value={alias}
                maxLength={80}
                onChange={(event) => {
                  setAlias(event.target.value);
                  setError(null);
                }}
                aria-invalid={Boolean(error)}
                aria-describedby={error ? 'speaker-alias-error' : undefined}
              />
            </div>
            <p className="text-xs text-muted-foreground" role="status">
              This name is used in this meeting and in the next generated summary.
            </p>
            {error && (
              <p id="speaker-alias-error" className="text-sm text-red-600" role="alert">
                {error}
              </p>
            )}
          </div>
          <DialogFooter>
            {hasAlias && (
              <Button type="button" variant="outline" onClick={handleClear} disabled={isSaving}>
                Clear
              </Button>
            )}
            <Button type="button" variant="ghost" onClick={() => onOpenChange(false)} disabled={isSaving}>
              Cancel
            </Button>
            <Button type="submit" disabled={isSaving}>
              {isSaving ? 'Saving…' : 'Save'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
