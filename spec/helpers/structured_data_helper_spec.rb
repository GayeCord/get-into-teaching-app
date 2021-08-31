require "rails_helper"

describe StructuredDataHelper, type: "helper" do
  include ERB::Util
  include EventsHelper

  describe ".structured_data" do
    let(:malicious_text) { "</script><script>alert('PWNED!')</script>" }
    let(:html) { structured_data("Type", { text: malicious_text }) }

    subject(:script_tag) { Nokogiri::HTML.parse(html).at_css("script") }

    it "wraps JSON in a script tag" do
      expect(script_tag).to be_present
      expect(script_tag[:type]).to eq("application/ld+json")
      expect { JSON.parse(script_tag.content) }.not_to raise_error
    end

    it "includes the context, type and data" do
      json = JSON.parse(script_tag.content)

      expect(json["@context"]).to eq("https://schema.org")
      expect(json["@type"]).to eq("Type")
      expect(json["text"]).to eq(malicious_text)
    end

    it "outputs escaped JSON" do
      escaped_malicious_text = json_escape(malicious_text)
      expect(script_tag.content).to include(escaped_malicious_text)
    end
  end

  describe ".event_structured_data" do
    let(:event) { build(:event_api, building: nil) }
    let(:html) { event_structured_data(event) }
    let(:script_tag) { Nokogiri::HTML.parse(html).at_css("script") }

    subject(:data) { JSON.parse(script_tag.content, symbolize_names: true) }

    it "includes event information" do
      expect(data).to include({
        name: event.name,
        startDate: event.start_at,
        endDate: event.end_at,
        description: strip_tags(event.description).strip,
        eventStatus: described_class::EVENT_SCHEDULED,
        eventAttendanceMode: described_class::OFFLINE_EVENT,
        offers: {
          "@type": "Offer",
          price: 0,
          priceCurrency: "GBP",
          availability: described_class::IN_STOCK,
        },
      })

      expect(data).to_not have_key(:organizer)
      expect(data).to_not have_key(:location)
    end

    context "when the event is online" do
      let(:event) { build(:event_api, :online) }

      it { is_expected.to include({ eventAttendanceMode: described_class::ONLINE_EVENT }) }
    end

    context "when the event is closed" do
      let(:event) { build(:event_api, :closed) }

      it { expect(data[:offers]).to include({ availability: described_class::SOLD_OUT }) }
    end

    context "when there is provider information" do
      let(:event) { build(:event_api, :with_provider_info) }

      it "includes organizer" do
        expect(data[:organizer]).to include({
          "@type": "Organization",
          name: event.provider_organiser,
          email: event.provider_contact_email,
          url: event.provider_website_url,
        })
      end
    end

    context "when there is a building" do
      let(:event) { build(:event_api) }
      let(:building) { event.building }
      let(:street_address) do
        [
          building.address_line1,
          building.address_line2,
        ].compact.join(", ")
      end

      it "includes a location" do
        expect(data[:location]).to include({
          "@type": "Place",
          name: building.venue,
          address: {
            "@type": "PostalAddress",
            addressCountry: "GB",
            streetAddress: street_address,
            addressLocality: building.address_city,
            addressRegion: building.address_line3,
            postalCode: building.address_postcode,
          },
        })

        expect(data[:image]).to contain_exactly(building.image_url)
      end

      context "when the building does not have an image" do
        before { building.image_url = nil }

        it "does not include the image" do
          expect(data).not_to have_key(:image)
        end
      end
    end
  end
end
