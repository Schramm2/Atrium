import assert from 'node:assert/strict';
import test from 'node:test';
import {
  buildCitationHref,
  citationDataForClaim,
  initialAskState,
  needsExternalProviderConfirmation,
  readCitationTarget,
  reduceAskState,
} from '../../src/lib/ask/logic.ts';

const citation = {
  sourceId: 'source-1',
  meetingId: 'meeting / one',
  meetingTitle: 'Launch review',
  transcriptId: 'segment&42',
  snippet: 'We will launch Tuesday.',
  timestamp: '2026-08-08T09:00:00Z',
  audioStartTime: 125.5,
  meetingCreatedAt: '2026-08-08T08:00:00Z',
};

test('ask state covers retrieval, confirmation, generation, answer, and failures', () => {
  const retrieving = reduceAskState(initialAskState, { type: 'retrieve' });
  assert.equal(retrieving.phase, 'retrieving');
  const confirming = reduceAskState(retrieving, { type: 'confirm', requestId: 'r1', provider: 'OpenAI', evidenceCount: 2 });
  assert.deepEqual([confirming.phase, confirming.requestId, confirming.evidenceCount], ['confirming', 'r1', 2]);
  const generating = reduceAskState(confirming, { type: 'generate', requestId: 'r1', provider: 'OpenAI', evidenceCount: 2 });
  assert.equal(generating.phase, 'generating');
  const answered = reduceAskState(generating, { type: 'resolve', answer: { status: 'answered', answer: 'Tuesday.', claims: [], citations: [], provider: 'OpenAI', model: 'test' } });
  assert.equal(answered.phase, 'answered');
  const insufficient = reduceAskState(generating, { type: 'resolve', answer: { status: 'insufficient', answer: 'Not enough evidence.', claims: [], citations: [], provider: 'OpenAI', model: 'test' } });
  assert.equal(insufficient.phase, 'insufficient');
  assert.equal(reduceAskState(generating, { type: 'fail', message: 'bad output' }).phase, 'error');
  assert.equal(reduceAskState(generating, { type: 'cancel' }).phase, 'cancelled');
  assert.equal(reduceAskState(generating, { type: 'empty', requestId: 'r1', provider: 'Ollama' }).phase, 'empty');
  assert.equal(reduceAskState(generating, { type: 'reset' }).phase, 'idle');
});

test('external confirmation is required once per provider and never for local providers', () => {
  assert.equal(needsExternalProviderConfirmation('OpenAI', true, []), true);
  assert.equal(needsExternalProviderConfirmation('OpenAI', true, [' openai ']), false);
  assert.equal(needsExternalProviderConfirmation('Ollama', false, []), false);
});

test('citation data stays beside its claim and omits unknown source ids', () => {
  const rendered = citationDataForClaim(['missing', 'source-1'], [citation]);
  assert.equal(rendered.length, 1);
  assert.equal(rendered[0].citation.sourceId, 'source-1');
  assert.equal(rendered[0].label, 'Launch review · 2:05');
});

test('citation navigation encodes meeting, segment, and audio time', () => {
  const href = buildCitationHref(citation);
  assert.equal(
    href,
    '/meeting-details?id=meeting+%2F+one&segment=segment%2642&t=125.5',
  );
  const target = readCitationTarget(new URL(href, 'https://ubundi.local').searchParams);
  assert.deepEqual(target, {
    meetingId: 'meeting / one',
    segmentId: 'segment&42',
    timestamp: 125.5,
  });
});
