import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

// Load environment variables from .env
dotenv.config({ path: path.join(__dirname, '../../.env') });

async function checkVapiCall() {
  const callId = '01a063ee-ed7a-7882-9f31-656bd964dfa2';
  const targetStructuredOutputId = 'dbd79a88-edd8-4da7-8fe0-f92ae5b637e0';
  const vapiApiKey = process.env.VAPI_PRIVATE_KEY;

  if (!vapiApiKey) {
    console.error('Error: VAPI_PRIVATE_KEY not found in environment');
    process.exit(1);
  }

  console.log(`[check-vapi-call] Fetching call details for: ${callId}...`);

  const response = await fetch(`https://api.vapi.ai/call/${callId}`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${vapiApiKey}`,
    },
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error(`Error: Failed to fetch call (${response.status}): ${errorText}`);
    process.exit(1);
  }

  const data = (await response.json()) as any;

  // Save to file
  const outputPath = path.join(__dirname, '../../vapi-call-details.json');
  fs.writeFileSync(outputPath, JSON.stringify(data, null, 2), 'utf8');
  console.log(`[check-vapi-call] Saved full response to: ${outputPath}`);

  console.log('\n=================== SEARCH RESULTS ===================');

  // 1. Check structuredOutputs / artifact.structuredOutputs
  console.log('\n--- 1. structuredOutputs / artifact.structuredOutputs ---');
  console.log('data.structuredOutputs:', JSON.stringify(data.structuredOutputs ?? null, null, 2));
  console.log('data.artifact?.structuredOutputs:', JSON.stringify(data.artifact?.structuredOutputs ?? null, null, 2));

  // Search entire JSON for targetStructuredOutputId
  const jsonString = JSON.stringify(data, null, 2);
  const foundId = jsonString.includes(targetStructuredOutputId);
  console.log(`\nDoes ID "${targetStructuredOutputId}" appear in the response?: ${foundId}`);

  if (foundId) {
    console.log(`\nOccurrences of "${targetStructuredOutputId}" in JSON:`);
    const lines = jsonString.split('\n');
    lines.forEach((line: string, idx: number) => {
      if (line.includes(targetStructuredOutputId)) {
        const start = Math.max(0, idx - 5);
        const end = Math.min(lines.length - 1, idx + 5);
        console.log(`--- Match near line ${idx + 1} ---`);
        console.log(lines.slice(start, end + 1).join('\n'));
      }
    });
  }

  // 2. Check analysis field
  console.log('\n--- 2. analysis field ---');
  console.log('data.analysis:', JSON.stringify(data.analysis ?? null, null, 2));
  console.log('data.artifact?.analysis:', JSON.stringify(data.artifact?.analysis ?? null, null, 2));

  // 3. Transcript
  console.log('\n--- 3. transcript ---');
  console.log('data.transcript:', data.transcript ?? data.artifact?.transcript ?? 'None');

  console.log('\n================ FULL RAW JSON RESPONSE ================\n');
  console.log(JSON.stringify(data, null, 2));
}

checkVapiCall().catch((err) => {
  console.error('Unhandled error:', err);
  process.exit(1);
});
