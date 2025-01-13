use chrono::{NaiveTime, Weekday};
use figment::providers::Toml;
use figment::{providers::Format, Error, Figment};
use serde::Deserialize;

#[derive(Deserialize)]
pub struct Configuration {
    pub booking_days: Vec<BookingDay>,
    pub credentials: Vec<UserCredentials>,
}

#[derive(Deserialize, Clone)]
pub struct BookingDay {
    pub week_day: Weekday,
    pub time: NaiveTime,
    pub booking_id: String,
}

#[derive(Deserialize, Clone)]
pub struct UserCredentials {
    pub username: String,
    pub password: String,
}

impl Configuration {
    pub fn parse() -> Result<Self, Error> {
        let config: Configuration = Figment::new().merge(Toml::file("config.toml")).extract()?;
        Ok(config)
    }
}
