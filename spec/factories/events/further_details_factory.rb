FactoryBot.define do
  factory :events_further_details, class: Events::Steps::FurtherDetails do
    event_id { "abc123" }
    privacy_policy { true }
    mailing_list { true }
  end
end
