import {type Browser, type Page} from 'playwright';
import {sleep} from "./util.ts";

export const register = async (browser: Browser, kursId: number, email: string, password: string) => {

    let page = await browser.newPage();
    const courseElementSelector = `[name="BS_Kursid_${kursId}"]`;

    // open badminton offerings
    await page.goto('https://www.buchsys.de/eichstaett-ingolstadt/angebote/aktueller_zeitraum/_Badminton_ING.html');

    const locator = page.locator(courseElementSelector);
    while (await locator.count() === 0) {
        await sleep(10_000);
        await page.reload();
    }

    // Navigate to specific course
    await page.click(courseElementSelector);


    // Get all pages
    let pages: Page[] = [];
    while (pages.length <= 1) {
        pages = page.context().pages();
        await sleep(50);
    }

    // Bring latest page to the front
    await pages[1].bringToFront();


    const bookingPage = pages[1];

    // Select specific booking day
    await bookingPage.click('input[value="buchen"]');

    // Open password and email prompt
    await bookingPage.click('div.bs_arrow');

    // Enter credentials
    await bookingPage.fill('[name="pw_email"]', email);
    await bookingPage.fill('[type="password"]', password);

    // Submit credentials
    await bookingPage.click('input[type="submit"]');

    // Accept terms
    await bookingPage.click('input[type="checkbox"]');

    // Submit form with all user data filled in
    await bookingPage.click('input[type="submit"]');

    // Submit check again form
    await bookingPage.click('input[type="submit"]');

    // Close all browser windows
    for (const page of pages) {
        await page.close();
    }
}
