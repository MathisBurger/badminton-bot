use fantoccini::{Client, Locator};
use tokio;

#[tokio::main]
async fn main() -> Result<(), fantoccini::error::CmdError> {
    let booking_id = "K040-3";

    // Verbindet sich mit einem laufenden WebDriver (z. B. geckodriver für Firefox)
    let mut client = Client::new("http://localhost:4444").await.unwrap();

    // Gehe zu einer Website
    client
        .goto("https://www.buchsys.de/eichstaett-ingolstadt/angebote/aktueller_zeitraum/_Badminton_ING.html")
        .await.expect("Cannot open website");

    client
        .find(Locator::XPath(
            format!("//*[@id='{}']", booking_id).as_str(),
        ))
        .await?
        .click()
        .await?;

    // Warte einige Sekunden, damit die Ergebnisse geladen werden
    tokio::time::sleep(tokio::time::Duration::from_secs(30)).await;

    // Schließe den Browser
    client.close().await?;
    Ok(())
}
