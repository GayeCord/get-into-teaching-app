require "rails_helper"

describe "Mailing list calls to action", type: :request do
  describe "banner" do
    subject { Nokogiri.parse(response.body) }

    before { get root_path }

    it "the mailing list banner has a close link" do
      link = subject.at_css("#mailing-list-bar-dismiss")

      expect(link).to be_truthy
    end

    it "the mailing list banner has an accept link" do
      link = subject.at_css("#mailing-list-bar-accept")

      expect(link).to be_truthy
    end
  end
end
