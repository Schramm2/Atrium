'use client';

import { CalendarDays, ChevronDown } from 'lucide-react';
import type { CurrentMeeting } from '@/components/Sidebar/SidebarProvider';

interface ScopeControlsProps {
  meetings: CurrentMeeting[];
  selectedMeetingIds: string[];
  dateFrom: string;
  dateTo: string;
  expanded: boolean;
  onExpandedChange: (expanded: boolean) => void;
  onSelectedMeetingIdsChange: (ids: string[]) => void;
  onDateFromChange: (value: string) => void;
  onDateToChange: (value: string) => void;
}
export function ScopeControls(props: ScopeControlsProps) {
  const scopeLabel = props.selectedMeetingIds.length === 0
    ? 'All meetings'
    : `${props.selectedMeetingIds.length} meeting${props.selectedMeetingIds.length === 1 ? '' : 's'}`;

  const toggleMeeting = (meetingId: string) => {
    props.onSelectedMeetingIdsChange(
      props.selectedMeetingIds.includes(meetingId)
        ? props.selectedMeetingIds.filter(id => id !== meetingId)
        : [...props.selectedMeetingIds, meetingId],
    );
  };

  return (
    <div className="ask-scope border-t pt-3">
      <button
        type="button"
        className="ask-scope-trigger flex w-full items-center justify-between rounded-md px-1 py-1.5 text-sm font-medium"
        onClick={() => props.onExpandedChange(!props.expanded)}
        aria-expanded={props.expanded}
      >
        <span className="flex items-center gap-2"><CalendarDays className="size-4" />Scope: {scopeLabel}</span>
        <ChevronDown className={`size-4 transition-transform ${props.expanded ? 'rotate-180' : ''}`} />
      </button>

      {props.expanded && (
        <div className="ask-scope-panel mt-3 grid gap-5 rounded-lg p-4 md:grid-cols-2">
          <fieldset>
            <legend className="ask-scope-legend mb-2 text-xs font-semibold uppercase tracking-wide">Meetings</legend>
            <label className="ask-scope-label mb-2 flex cursor-pointer items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={props.selectedMeetingIds.length === 0}
                onChange={() => props.onSelectedMeetingIdsChange([])}
                className="ask-checkbox"
              />
              All meetings
            </label>
            <div className="max-h-36 space-y-2 overflow-y-auto pr-2">
              {props.meetings.map(meeting => (
                <label key={meeting.id} className="ask-scope-label flex cursor-pointer items-start gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={props.selectedMeetingIds.includes(meeting.id)}
                    onChange={() => toggleMeeting(meeting.id)}
                    className="ask-checkbox mt-0.5"
                  />
                  <span>{meeting.title}</span>
                </label>
              ))}
            </div>
          </fieldset>

          <fieldset>
            <legend className="ask-scope-legend mb-2 text-xs font-semibold uppercase tracking-wide">Meeting date</legend>
            <div className="space-y-3">
              <label className="ask-scope-label block text-xs">
                From
                <input type="date" value={props.dateFrom} max={props.dateTo || undefined} onChange={event => props.onDateFromChange(event.target.value)} className="ask-date-input mt-1 block h-9 w-full rounded-md border px-3 text-sm" />
              </label>
              <label className="ask-scope-label block text-xs">
                To
                <input type="date" value={props.dateTo} min={props.dateFrom || undefined} onChange={event => props.onDateToChange(event.target.value)} className="ask-date-input mt-1 block h-9 w-full rounded-md border px-3 text-sm" />
              </label>
            </div>
          </fieldset>
        </div>
      )}
    </div>
  );
}
