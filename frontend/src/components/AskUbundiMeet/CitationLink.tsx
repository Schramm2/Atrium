'use client';

import { ExternalLink } from 'lucide-react';
import type { ClaimCitationData } from '@/lib/ask/logic';

export function CitationLink({ data, onNavigate }: { data: ClaimCitationData; onNavigate: (href: string) => void }) {
  return (
    <button
      type="button"
      onClick={() => onNavigate(data.href)}
      className="inline-flex max-w-full items-center gap-1 rounded-full border border-[#C9D1F2] bg-[#F2F5FC] px-2.5 py-1 text-xs font-medium text-[#2F3498] transition-colors hover:bg-[#E6EBF8] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#2F3498]"
      title={data.citation.snippet}
    >
      <span className="truncate">{data.label}</span>
      <ExternalLink className="size-3 shrink-0" aria-hidden="true" />
    </button>
  );
}

