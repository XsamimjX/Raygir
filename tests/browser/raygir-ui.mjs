import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
/* global process */
import { chromium } from 'playwright';

const baseUrl = process.env.RAYGIR_TEST_URL ?? 'http://127.0.0.1:8010';
const candidates = [
    process.env.CHROME_PATH,
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
].filter(Boolean);
const executablePath = candidates.find((candidate) => existsSync(candidate));

assert.ok(executablePath, 'A local Chromium-compatible browser is required.');

const surfaces = [
    '',
    '/markets',
    '/civic',
    '/prediction',
    '/exchange',
    '/create',
    '/portfolio',
    '/reports',
    '/evidence',
    '/challenges',
    '/refunds',
];
const profiles = [
    { width: 375, height: 812, colorScheme: 'light' },
    { width: 768, height: 1024, colorScheme: 'dark' },
    { width: 1440, height: 900, colorScheme: 'light' },
];

const browser = await chromium.launch({ executablePath, headless: true });

try {
    for (const locale of ['fa', 'en']) {
        for (const profile of profiles) {
            const context = await browser.newContext({
                viewport: { width: profile.width, height: profile.height },
                colorScheme: profile.colorScheme,
                reducedMotion: 'reduce',
            });
            const page = await context.newPage();
            const errors = [];

            page.on('console', (message) => {
                if (message.type() === 'error') {
                    errors.push(message.text());
                }
            });
            page.on('pageerror', (error) => errors.push(error.message));

            for (const surface of surfaces) {
                const response = await page.goto(`${baseUrl}/${locale}${surface}`, {
                    waitUntil: 'networkidle',
                });

                assert.equal(response?.status(), 200, `${locale}${surface} did not return 200`);
                assert.equal(await page.locator('html').getAttribute('lang'), locale);
                assert.equal(await page.locator('html').getAttribute('dir'), locale === 'fa' ? 'rtl' : 'ltr');
                assert.equal(await page.locator('main').count(), 1, `${locale}${surface} needs one main landmark`);
                assert.equal(
                    await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth),
                    true,
                    `${locale}${surface} overflows at ${profile.width}px`,
                );

                await page.keyboard.press('Tab');
                assert.notEqual(
                    await page.evaluate(() => document.activeElement?.tagName),
                    'BODY',
                    `${locale}${surface} has no keyboard focus target`,
                );
            }

            assert.deepEqual(errors, [], `${locale} ${profile.width}px emitted browser errors`);
            await context.close();
        }
    }
} finally {
    await browser.close();
}

console.log(`Raygir browser matrix passed: ${2 * profiles.length * surfaces.length} page profiles.`);
