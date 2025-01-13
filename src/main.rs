use chrono::{Datelike, Duration, NaiveDateTime, NaiveTime, Utc, Weekday};
use chrono_tz::Europe::Berlin;
use config::{BookingDay, Configuration};
use log::info;
use std::{thread, time::Duration as StdDuration};
use tokio;

mod automation;
mod config;

#[tokio::main]
async fn main() {
    let config = Configuration::parse().expect("Cannot load config");
    let log_level = std::env::var("RUST_LOG").unwrap_or_else(|_e| "info".to_string());

    std::env::set_var("RUST_LOG", log_level);
    pretty_env_logger::init();
    let credentials = config.credentials.clone();
    loop {
        let (ttw, booking_day) = get_next(&config);
        let msg: String = format!(
            "Next booking is scheduled in {} secs for {} users. ({}) ",
            ttw,
            credentials.len(),
            booking_day.week_day
        );
        info!(target: "scheduler", "{}", msg);
        thread::sleep(StdDuration::from_secs(ttw));
        for creds in credentials.clone() {
            info!(target: "booking", "Booking {} for user {}", booking_day.booking_id, creds.username);
            automation::perform_booking(
                booking_day.booking_id.as_str(),
                creds.username.as_str(),
                creds.password.as_str(),
            )
            .await
            .expect("Cannot create booking for user");
        }
    }
}

fn get_next(config: &Configuration) -> (u64, BookingDay) {
    let mut sorted = config.booking_days.clone();
    sorted.sort_by(|a, b| conv_wd_to_u8(a.week_day).cmp(&conv_wd_to_u8(b.week_day)));
    let current_date = Utc::now();
    let berlin_date = current_date.with_timezone(&Berlin);
    let next_booking_day = get_next_weekday(berlin_date.weekday(), berlin_date.time(), &sorted);
    let next_date = get_next_date(&next_booking_day);
    (
        next_date
            .signed_duration_since(berlin_date.naive_utc())
            .num_seconds() as u64,
        next_booking_day,
    )
}

fn conv_wd_to_u8(weekday: Weekday) -> u8 {
    match weekday {
        Weekday::Mon => 0,
        Weekday::Tue => 1,
        Weekday::Wed => 2,
        Weekday::Thu => 3,
        Weekday::Fri => 4,
        Weekday::Sat => 5,
        Weekday::Sun => 6,
    }
}

fn get_next_weekday(
    current: Weekday,
    current_time: NaiveTime,
    sorted: &Vec<BookingDay>,
) -> BookingDay {
    for element in sorted {
        if conv_wd_to_u8(current) <= conv_wd_to_u8(element.week_day) && current_time < element.time
        {
            return element.clone();
        }
    }
    sorted.first().unwrap().clone()
}

fn get_next_date(day: &BookingDay) -> NaiveDateTime {
    let mut now = Utc::now().date_naive();
    while now.weekday() != day.week_day {
        now = now + Duration::days(1);
    }
    now.and_time(day.time)
}
