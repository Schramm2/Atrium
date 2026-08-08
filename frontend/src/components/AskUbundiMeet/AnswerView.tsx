'use client';

import type { AskAnswer } from '@/types/ask';
import { citationDataForClaim } from '@/lib/ask/logic';
import { CitationLink } from './CitationLink';

export function AnswerView({ answer, onNavigate }: { answer: AskAnswer; onNavigate: (href: string) => void }) {
  const hasClaims = answer.claims.length > 0;

  return (
    <div className="space-y-5" aria-live="polite">
      {answer.status === 'insufficient' && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
          The selected meetings do not contain enough evidence for a complete answer.
        </div>
      )}

      {hasClaims ? (
        <div className="space-y-4">
          {answer.claims.map((claim, index) => {
            const citationData = citationDataForClaim(claim.citationIds, answer.citations);
            return (
              <div key={`${index}-${claim.text.slice(0, 24)}`} className="space-y-2">
                <p className="text-[15px] leading-7 text-slate-800">{claim.text}</p>
                {citationData.length > 0 && (
                  <div className="flex flex-wrap gap-2" aria-label={`Sources for claim ${index + 1}`}>
                    {citationData.map(data => (
                      <CitationLink key={data.citation.sourceId} data={data} onNavigate={onNavigate} />
                    ))}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      ) : (
        <p className="whitespace-pre-wrap text-[15px] leading-7 text-slate-800">{answer.answer}</p>
      )}

      <p className="text-xs text-slate-500">Answered by {answer.provider} · {answer.model}</p>
    </div>
  );
}

