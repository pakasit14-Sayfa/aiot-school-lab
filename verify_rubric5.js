const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1400, height: 900 } });
  await page.goto('http://127.0.0.1:8765/', { waitUntil: 'networkidle' });
  await page.waitForTimeout(7000);
  await page.mouse.click(700, 404);
  await page.keyboard.type('teacher@aiot-school-lab.local', { delay: 20 });
  await page.mouse.click(700, 468);
  await page.keyboard.type('Test1234!', { delay: 20 });
  await page.mouse.click(700, 562);
  await page.waitForTimeout(5000);
  await page.mouse.click(842, 414);
  await page.waitForTimeout(2500);
  await page.mouse.click(700, 612);
  await page.waitForTimeout(4000);
  await page.mouse.click(700, 612);
  await page.waitForTimeout(4000);

  await page.mouse.move(62, 500);
  await page.mouse.wheel(0, 500);
  await page.waitForTimeout(1000);
  await page.mouse.click(62, 533);
  await page.waitForTimeout(2000);
  await page.screenshot({ path: 'shot_rub_page2.png' });

  await browser.close();
})().catch((e) => { console.error('SCRIPT_ERROR', e); process.exit(1); });
