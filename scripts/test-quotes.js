#!/usr/bin/env node

/**
 * Test suite for Ticking Plasmoid Quote Engine.
 * Tests offline curated library, response parsing, and live OpenCode Zen API integration.
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// Load QuoteClient and QuoteLibrary
const rootDir = path.resolve(__dirname, '..');
const quoteClientCode = fs.readFileSync(path.join(rootDir, 'contents/ui/components/QuoteClient.js'), 'utf8')
    .replace('.pragma library', '');
const quoteLibCode = fs.readFileSync(path.join(rootDir, 'contents/ui/components/QuoteLibrary.js'), 'utf8')
    .replace('.pragma library', '');

const QC = {};
eval(quoteClientCode + '; QC.cleanQuoteText = cleanQuoteText; QC.cleanQuoteAuthor = cleanQuoteAuthor; QC.parseModelContent = parseModelContent; QC.resolveTopic = resolveTopic; QC.DEFAULT_QUOTE_TEXT = DEFAULT_QUOTE_TEXT; QC.REMOTE_MODELS = REMOTE_MODELS;');

const QL = {};
eval(quoteLibCode + '; QL.quotes = quotes; QL.getCuratedQuote = getCuratedQuote;');

let passed = 0;
let failed = 0;

function assert(condition, message) {
    if (condition) {
        console.log(`  ✓ ${message}`);
        passed++;
    } else {
        console.error(`  ✗ FAIL: ${message}`);
        failed++;
    }
}

function requestZen(key, includeSessionId, model) {
    return new Promise((resolve) => {
        const payload = JSON.stringify({
            model: model,
            messages: [{ role: 'user', content: 'Famous quote about focus. 1 line only: "Quote" - Author' }],
            max_tokens: 800,
            temperature: 0.7
        });

        const headers = {
            'Authorization': `Bearer ${key}`,
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(payload)
        };

        if (includeSessionId) {
            headers['x-session-id'] = 'ticking-test-' + Date.now();
        }

        const req = https.request('https://opencode.ai/zen/v1/chat/completions', {
            method: 'POST',
            headers: headers,
            timeout: 25000
        }, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => resolve({ statusCode: res.statusCode, body }));
        });

        req.on('error', (err) => resolve({ error: err }));
        req.on('timeout', () => {
            req.destroy();
            resolve({ error: new Error('Request timed out (25s)') });
        });

        req.write(payload);
        req.end();
    });
}

async function runAll() {
    console.log('====================================================');
    console.log('  TICKING QUOTE ENGINE TEST SUITE');
    console.log('====================================================\n');

    // 1. Text Sanitization Tests
    console.log('[1/4] Testing Quote Text Sanitization');
    assert(QC.cleanQuoteText('"Life is what happens."') === 'Life is what happens.', 'Strips straight double quotes');
    assert(QC.cleanQuoteText('“Simplicity is key.”') === 'Simplicity is key.', 'Strips curly quotes');
    assert(QC.cleanQuoteText('Here is a quote: "Focus."') === 'Focus.', 'Strips "Here is a quote:" preamble');
    assert(QC.cleanQuoteText('thinking process: let me see...') === '', 'Rejects thinking process contamination');
    assert(QC.cleanQuoteAuthor(' - Albert Einstein ') === '- Albert Einstein', 'Strips trailing spaces from author');
    assert(QC.cleanQuoteAuthor('"Marcus Aurelius"') === 'Marcus Aurelius', 'Strips surrounding quotes from author');

    // 2. Parser Tests
    console.log('\n[2/4] Testing Model Content Parser');
    const sample1 = '"The only reason for time is so that everything does not happen at once." - Albert Einstein';
    const parsed1 = QC.parseModelContent(sample1);
    assert(parsed1 && parsed1.text === 'The only reason for time is so that everything does not happen at once.', 'Parses standard quoted string');
    assert(parsed1 && parsed1.author === 'Albert Einstein', 'Extracts author correctly');

    const sampleWithThinking = `<think>
I need to generate a quote on focus.
Let's select Bruce Lee.
</think>
"The successful warrior is the average man, with laser-like focus." - Bruce Lee`;
    const parsed2 = QC.parseModelContent(sampleWithThinking);
    assert(parsed2 && parsed2.text === 'The successful warrior is the average man, with laser-like focus.', 'Strips <think> tags completely');
    assert(parsed2 && parsed2.author === 'Bruce Lee', 'Extracts author from post-think output');

    const sampleBy = 'Quality is not an act, it is a habit by Aristotle';
    const parsed3 = QC.parseModelContent(sampleBy);
    assert(parsed3 && parsed3.text === 'Quality is not an act, it is a habit', 'Parses "by Author" format');
    assert(parsed3 && parsed3.author === 'Aristotle', 'Extracts author from "by Author"');

    // 3. Curated Offline Library Tests
    console.log('\n[3/4] Testing Curated Offline Library');
    assert(QL.quotes.stoic.length >= 10, 'Stoic quote pool has >= 10 quotes');
    assert(QL.quotes.builder.length >= 10, 'Builder quote pool has >= 10 quotes');
    assert(QL.quotes.cosmic.length >= 10, 'Cosmic quote pool has >= 10 quotes');
    assert(QL.quotes.intensity.length >= 10, 'Intensity quote pool has >= 10 quotes');

    const adaptive0 = QL.getCuratedQuote('adaptive', 0.1);
    assert(adaptive0 && adaptive0.text.length > 0, 'Adaptive tier 0 (<25%) returns valid quote');
    const adaptive50 = QL.getCuratedQuote('adaptive', 0.5);
    assert(adaptive50 && adaptive50.text.length > 0, 'Adaptive tier 50 (25-75%) returns valid quote');
    const adaptive80 = QL.getCuratedQuote('adaptive', 0.8);
    assert(adaptive80 && adaptive80.text.length > 0, 'Adaptive tier 80 (75-100%) returns valid quote');
    const adaptive100 = QL.getCuratedQuote('adaptive', 1.0);
    assert(adaptive100 && adaptive100.text.length > 0, 'Adaptive tier 100 (reached) returns valid quote');

    // 4. Live OpenCode Zen Integration Tests
    console.log('\n[4/4] Testing Live OpenCode Zen API Integration');
    const apiKey = process.env.OPENCODE_ZEN_API_KEY || process.env.OPENCODE_API_KEY || '';

    if (!apiKey) {
        console.log('  ⚠ Skipping live network test: OPENCODE_ZEN_API_KEY not set.');
    } else {
        console.log(`  Using API Key: ${apiKey.slice(0, 10)}...${apiKey.slice(-6)}`);

        // Live Test A: Request WITHOUT x-session-id (reproduces the original failure)
        console.log('  -> Executing Test A: Request without x-session-id (expected HTTP 400)...');
        const resA = await requestZen(apiKey, false, 'nemotron-3-ultra-free');
        if (resA.statusCode === 400 && resA.body && resA.body.includes('MissingSessionID')) {
            assert(true, 'Reproduced root-cause bug without x-session-id: Server rejected with HTTP 400 MissingSessionID');
        } else {
            console.log(`  (Note: server returned status ${resA.statusCode || resA.error})`);
        }

        // Live Test B: Request WITH x-session-id using model cascade
        console.log('  -> Executing Test B: Remote model cascade with x-session-id...');
        let generatedQuote = null;
        for (const model of QC.REMOTE_MODELS) {
            console.log(`     Testing model candidate: ${model}...`);
            const res = await requestZen(apiKey, true, model);
            if (res.statusCode === 200 && res.body) {
                try {
                    const data = JSON.parse(res.body);
                    if (!data.error && data.choices && data.choices[0] && data.choices[0].message) {
                        const content = data.choices[0].message.content || '';
                        const parsed = QC.parseModelContent(content);
                        if (parsed && parsed.text.length > 0 && parsed.author.length > 0) {
                            generatedQuote = parsed;
                            assert(true, `Live AI Quote generated by ${model}: "${parsed.text}" - ${parsed.author}`);
                            break;
                        }
                    } else if (data.error) {
                        console.log(`     (${model} returned upstream error: ${data.error.message})`);
                    }
                } catch (e) {
                    console.log(`     (${model} parse exception: ${e.message})`);
                }
            } else {
                console.log(`     (${model} failed with status ${res.statusCode || res.error})`);
            }
        }
        if (!generatedQuote) {
            assert(false, 'Remote models failed to generate valid quote');
        }
    }

    console.log('\n====================================================');
    console.log(`  TEST RESULTS: ${passed} Passed, ${failed} Failed`);
    console.log('====================================================');
    if (failed > 0) {
        process.exit(1);
    }
}

runAll().catch(e => {
    console.error('Test runner error:', e);
    process.exit(1);
});
