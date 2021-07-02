require "rails_helper"

RSpec.feature "Book a callback", type: :feature do
  include_context "wizard data"

  let(:quota) do
    GetIntoTeachingApiClient::CallbackBookingQuota.new(
      startAt: DateTime.now.utc + 2.hours,
      endAt: DateTime.now.utc + 3.hours,
    )
  end

  before do
    allow_any_instance_of(GetIntoTeachingApiClient::CallbackBookingQuotasApi).to \
      receive(:get_callback_booking_quotas) { [quota] }

    callback_attrs = {
      first_name: "John",
      last_name: "Doe",
      email: "email@address.com",
      address_telephone: "123456789",
      phone_call_scheduled_at: "#{quota.start_at.strftime('%Y-%m-%dT%H:%M:%S')}.000Z",
      accepted_policy_id: "123",
    }
    expect_any_instance_of(GetIntoTeachingApiClient::GetIntoTeachingApi).to \
      receive(:book_get_into_teaching_callback)
        .with(having_attributes(callback_attrs))
  end

  scenario "Full journey as a new candidate" do
    allow_any_instance_of(GetIntoTeachingApiClient::CandidatesApi).to \
      receive(:create_candidate_access_token).and_raise(GetIntoTeachingApiClient::ApiError)

    visit callbacks_steps_path

    expect(page).to have_title("Get Into Teaching: Book a callback, personal details step")

    expect(page).to have_text "Book a callback"
    fill_in_personal_details_step
    click_on "Next Step"

    expect(page).to have_text "Choose a time for your callback"
    fill_in "Phone number", with: "123456789"
    select_first_option "Select your preferred day and time for a callback"
    click_on "Next Step"

    expect(page).to have_text "Accept privacy policy"
    check "Yes"
    click_on "Book your callback"

    expect(page).to have_title("Get Into Teaching: Callback confirmed")
    expect(page).to have_text "Callback confirmed"

    date = quota.start_at.to_date.to_formatted_s(:govuk)
    time = quota.start_at.to_formatted_s(:govuk_time_with_period)
    expect(page).to have_text "call you on #{date} at #{time}"
  end

  scenario "Full journey as an existing candidate (that resends the verification code)" do
    allow_any_instance_of(GetIntoTeachingApiClient::CandidatesApi).to \
      receive(:create_candidate_access_token)

    response = GetIntoTeachingApiClient::GetIntoTeachingCallback.new(addressTelephone: "123456789")
    allow_any_instance_of(GetIntoTeachingApiClient::GetIntoTeachingApi).to \
      receive(:exchange_access_token_for_get_into_teaching_callback).with("654321", anything).and_raise(GetIntoTeachingApiClient::ApiError)
    allow_any_instance_of(GetIntoTeachingApiClient::GetIntoTeachingApi).to \
      receive(:exchange_access_token_for_get_into_teaching_callback).with("123456", anything) { response }

    visit callbacks_steps_path

    expect(page).to have_text "Book a callback"
    fill_in_personal_details_step
    click_on "Next Step"

    expect(page).to have_text "Verify your email address"
    fill_in "Check your email and enter the verification code sent to email@address.com", with: "654321"
    click_on "Next Step"

    expect(page).to have_text "Please enter the latest verification code"

    click_link "resend verification"
    expect(page).to have_text "We've sent you another email."

    fill_in "Check your email and enter the verification code sent to email@address.com", with: "123456"
    click_on "Next Step"

    expect(page).to have_text "Choose a time for your callback"
    expect(find_field("Phone number").value).to eq(response.address_telephone)
    select_first_option "Select your preferred day and time for a callback"
    click_on "Next Step"

    expect(page).to have_text "Accept privacy policy"
    check "Yes"
    click_on "Book your callback"

    expect(page).to have_title("Get Into Teaching: Callback confirmed")
    expect(page).to have_text "Callback confirmed"

    date = quota.start_at.to_date.to_formatted_s(:govuk)
    time = quota.start_at.to_formatted_s(:govuk_time_with_period)
    expect(page).to have_text "call you on #{date} at #{time}"
  end

  scenario "Journey encountering errors" do
    allow_any_instance_of(GetIntoTeachingApiClient::CandidatesApi).to \
      receive(:create_candidate_access_token).and_raise(GetIntoTeachingApiClient::ApiError)

    visit callbacks_steps_path

    expect(page).to have_text "Book a callback"

    click_on "Next Step"
    expect(page).to have_text "There is a problem"
    expect(page).to have_text "Enter your first name"
    expect(page).to have_text "Enter your last name"
    expect(page).to have_text "Enter your full email address"
    fill_in_personal_details_step
    click_on "Next Step"

    expect(page).to have_text "Choose a time for your callback"
    click_on "Next Step"
    expect(page).to have_text "Enter your telephone number"
    fill_in "Phone number", with: "12"
    click_on "Next Step"
    expect(page).to have_text "Enter a valid phone number"
    fill_in "Phone number", with: "123456789"
    select_first_option "Select your preferred day and time for a callback"
    click_on "Next Step"

    expect(page).to have_text "Accept privacy policy"
    click_on "Book your callback"
    expect(page).to have_text "Accept the privacy policy to continue"
    check "Yes"
    click_on "Book your callback"

    expect(page).to have_title("Get Into Teaching: Callback confirmed")
    expect(page).to have_text "Callback confirmed"

    date = quota.start_at.to_date.to_formatted_s(:govuk)
    time = quota.start_at.to_formatted_s(:govuk_time_with_period)
    expect(page).to have_text "call you on #{date} at #{time}"
  end

  def fill_in_personal_details_step(
    first_name: "John",
    last_name: "Doe",
    email: "email@address.com"
  )
    fill_in "First name", with: first_name if first_name
    fill_in "Last name", with: last_name if last_name
    fill_in "Email address", with: email if email
  end

  def select_first_option(field_label)
    find_field(field_label).first("option").select_option
  end
end