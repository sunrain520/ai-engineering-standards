import test from 'node:test';
import assert from 'node:assert/strict';
import { validateArtifact, validateSchemas } from '../scripts/lib/contracts.mjs';

test('all contract schemas validate', async () => {
  const results = await validateSchemas();
  assert.equal(results.filter((result) => !result.valid).length, 0);
  assert.equal(results.length, 9);
});

test('non-git facts require snapshot anchors', async () => {
  const artifact = {
    schema: 'code-facts.v1',
    run_id: 'run-test',
    extraction_target: { domain: 'backend', sub_domain: 'java-spring' },
    source_projects: [],
    facts: [{
      fact_id: 'FACT-1',
      kind: 'layering',
      observation: 'x',
      source_anchor: {
        source_type: 'filesystem',
        path_hash: 'sha256:x',
        file: 'src/App.java',
        line_range: { start: 1, end: 1 },
        snippet_hash: 'sha256:y'
      },
      git: { available: false, commit: null },
      scope: 'main',
      deterministic_occurrence_count: 1,
      confidence: 'high'
    }]
  };
  const result = await validateArtifact('code-facts.v1', artifact);
  assert.equal(result.valid, false);
});
