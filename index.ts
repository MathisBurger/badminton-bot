import * as fs from "node:fs";
import type {Config} from "./types";
import nodeCron from "node-cron";
import {register} from "./web.ts";
import {chromium} from "playwright";

console.log("Starting...");
const config: Config =  JSON.parse(fs.readFileSync("./config.json", "utf8"));
console.log("Accounts: " + config.accounts.length);
console.log("Courses: " + config.courses.length);

for (const course of config.courses) {

    nodeCron.schedule(course.cron, async () => {

        const browser = await chromium.launch({ headless: false });
        console.log(`Booking course with ID ${course.courseId}`);

        for (const account of config.accounts) {
            console.log("Booking course for user: " +  account.username);
            await register(browser, course.courseId, account.username, account.password);
        }

        await browser.close();
    });
}
