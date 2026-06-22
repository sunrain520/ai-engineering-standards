import path from 'node:path';
import { fileURLToPath } from 'node:url';
import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import { readJson } from './fs-utils.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
export const contractsDir = path.resolve(here, '../../contracts');

export const contractFiles = [
  'project-input.v1.schema.json',
  'batch-plan.v1.schema.json',
  'repo-profile.v1.schema.json',
  'code-facts.v1.schema.json',
  'pattern-candidates.v1.schema.json',
  'standard-rule.v1.schema.json',
  'rule-decision.v1.schema.json',
  'lineage-ledger.v1.schema.json',
  'owner-decision-queue.v1.schema.json'
];

export async function loadSchemas() {
  const schemas = [];
  for (const file of contractFiles) {
    schemas.push(await readJson(path.join(contractsDir, file)));
  }
  return schemas;
}

export async function createAjv() {
  const ajv = new Ajv({ allErrors: true, strict: false });
  addFormats(ajv);
  for (const schema of await loadSchemas()) {
    ajv.addSchema(schema, schema.$id);
  }
  return ajv;
}

export async function validateArtifact(schemaId, artifact) {
  const ajv = await createAjv();
  const validate = ajv.getSchema(schemaId);
  if (!validate) {
    throw new Error(`Unknown schema: ${schemaId}`);
  }
  const valid = validate(artifact);
  return {
    valid,
    errors: valid ? [] : [...(validate.errors ?? [])]
  };
}

export async function assertValid(schemaId, artifact, label = schemaId) {
  const result = await validateArtifact(schemaId, artifact);
  if (!result.valid) {
    const errors = result.errors.map((error) => `${error.instancePath || '/'} ${error.message}`).join('; ');
    throw new Error(`${label} failed ${schemaId} validation: ${errors}`);
  }
  return artifact;
}

export async function validateSchemas() {
  const ajv = new Ajv({ allErrors: true, strict: false });
  addFormats(ajv);
  const results = [];
  for (const schema of await loadSchemas()) {
    const valid = ajv.validateSchema(schema);
    results.push({
      schema: schema.$id,
      valid,
      errors: valid ? [] : [...(ajv.errors ?? [])]
    });
    if (valid) {
      ajv.addSchema(schema, schema.$id);
    }
  }
  return results;
}
