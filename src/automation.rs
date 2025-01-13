use fantoccini::error::CmdError;
use fantoccini::{Client, Locator};

pub async fn perform_booking(
    booking_id: &str,
    username: &str,
    password: &str,
) -> Result<(), CmdError> {
    let mut client = Client::new("http://localhost:4444").await.unwrap();
    open_booking_page(&mut client, booking_id).await?;
    select_date_and_open_credentials_field(&mut client).await?;
    enter_credentials(&mut client, username, password).await?;
    //submit_login(&mut client).await?;
    client.close().await?;

    Ok(())
}

async fn open_booking_page(
    client: &mut Client,
    booking_id: &str,
) -> Result<(), fantoccini::error::CmdError> {
    client
        .goto("https://www.buchsys.de/eichstaett-ingolstadt/angebote/aktueller_zeitraum/_Badminton_ING.html")
        .await.expect("Cannot open website");

    let mut anchor = client
        .find(Locator::XPath(
            format!("//*[@id='{}']", booking_id).as_str(),
        ))
        .await?;
    let mut parent = anchor.find(Locator::XPath("..")).await?;
    let input = parent.find(Locator::Css("input")).await?;
    input.click().await?;

    let initial_window_handle = client.window().await?;

    tokio::time::sleep(std::time::Duration::from_secs(2)).await;

    let window_handles = client.windows().await?;

    let new_window_handle = window_handles
        .into_iter()
        .find(|handle| *handle != initial_window_handle)
        .expect("No new window opened");
    client.switch_to_window(new_window_handle).await?;
    Ok(())
}

async fn select_date_and_open_credentials_field(
    client: &mut Client,
) -> Result<(), fantoccini::error::CmdError> {
    let next_locator = Locator::Css("html body form div#bs_form_content div#bs_form_main div.bs_form_row div.bs_etvg div.bs_form_row.bs_rowstripe0 label div.bs_form_uni.bs_right.padding0 input.inlbutton.buchen");

    client.wait().for_element(next_locator).await?;

    let booking_button = client.find(next_locator).await?;
    booking_button.click().await?;

    let usr_pw_open_label = client
        .find(Locator::XPath("//*[@id='bs_pw_anmlink']"))
        .await?;

    usr_pw_open_label.click().await?;
    Ok(())
}

async fn enter_credentials(
    client: &mut Client,
    email: &str,
    password: &str,
) -> Result<(), fantoccini::error::CmdError> {
    let mut email_input = client
        .find(Locator::XPath(
            "/html/body/form/div/div[2]/div[1]/div[2]/div[2]/input",
        ))
        .await?;
    email_input.send_keys(email).await?;

    let mut password_input = client
        .find(Locator::XPath(
            "/html/body/form/div/div[2]/div[1]/div[3]/div[2]/input",
        ))
        .await?;
    password_input.send_keys(password).await?;

    let submit_button = client
        .find(Locator::XPath(
            "/html/body/form/div/div[2]/div[1]/div[5]/div[1]/div[2]/input",
        ))
        .await?;
    submit_button.click().await?;
    Ok(())
}

async fn submit_login(client: &mut Client) -> Result<(), fantoccini::error::CmdError> {
    let terms_button = client
        .find(Locator::XPath(
            "/html/body/form/div/div[3]/div[2]/label/input",
        ))
        .await?;
    terms_button.click().await?;

    let complete_booking_button = client.find(Locator::XPath("//*[@id='bs_submit']")).await?;
    complete_booking_button.click().await?;

    Ok(())
}
