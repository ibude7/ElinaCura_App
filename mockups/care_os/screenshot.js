const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const url = 'file:///Users/ibude/ElinaCura_App/mockups/care_os/index.html';

  // 1440px
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto(url);
  await page.waitForTimeout(1000); // wait for fonts/icons
  await page.screenshot({ path: 'screenshot_1440.png', fullPage: true });

  // 768px
  await page.setViewportSize({ width: 768, height: 1024 });
  await page.goto(url);
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'screenshot_768.png', fullPage: true });

  // 375px
  await page.setViewportSize({ width: 375, height: 812 });
  await page.goto(url);
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'screenshot_375.png', fullPage: true });

  await browser.close();
})();
