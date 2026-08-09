'use client';

import { ExternalLink } from 'lucide-react';
import type { ClaimCitationData } from '@/lib/ask/logic';

export function CitationLink({ data, onNavigate }: { data: ClaimCitationData; onNavigate: (href: string) => void }) {
  return (
    <button
      type="button"
      onClick={() => onNavigate(data.href)}
      className="ask-citation inline-flex max-w-full items-center gap-1 rounded-full border px-2.5 py-1 text-xs font-medium transition-colors focus-visible:outline-none focus-visible:ring-2"
      title={data.citation.snippet}
    >
      <span className="truncate">{data.label}</span>
      <ExternalLink className="size-3 shrink-0" aria-hidden="true" />
    </button>
  );
}
