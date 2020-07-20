require "rails_helper"

describe Wizard::Steps::Authenticate do
  include_context "wizard step"
  it_behaves_like "a wizard step"

  before { allow(instance).to receive(:perform_existing_candidate_request).with(anything) { {} } }

  it { is_expected.to respond_to :timed_one_time_password }

  context "validations" do
    before { instance.valid? }
    subject { instance.errors.messages }
    it { is_expected.to include(:timed_one_time_password) }
  end

  context "timed one time password" do
    it { is_expected.to allow_value("000000").for :timed_one_time_password }
    it { is_expected.to allow_value(" 123456").for :timed_one_time_password }
    it { is_expected.not_to allow_value("abc123").for :timed_one_time_password }
    it { is_expected.not_to allow_value("1234567").for :timed_one_time_password }
    it { is_expected.not_to allow_value("12345").for :timed_one_time_password }
  end

  describe "skipped?" do
    it "returns true if authenticate is false" do
      wizardstore["authenticate"] = false
      expect(subject).to be_skipped
    end

    it "returns false if authenticate is true" do
      wizardstore["authenticate"] = true
      expect(subject).to_not be_skipped
    end
  end

  describe "#save" do
    before do
      subject.timed_one_time_password = "123456"
      wizardstore["email"] = "email@address.com"
      wizardstore["first_name"] = "First"
      wizardstore["last_name"] = "Last"
    end

    let(:request) do
      GetIntoTeachingApiClient::ExistingCandidateRequest.new(
        email: wizardstore["email"],
        firstName: wizardstore["first_name"],
        lastName: wizardstore["last_name"],
      )
    end

    context "when invalid" do
      it "does not attempt to call the API" do
        subject.timed_one_time_password = nil
        subject.save
        expect { subject.save }.to_not raise_error
      end
    end

    context "when valid" do
      it "attempts to call the API exactly once for each valid timed_one_time_password" do
        expect(subject).to receive(:perform_existing_candidate_request).with(request).exactly(2).times
        subject.timed_one_time_password = "123456"
        subject.save
        subject.save
        subject.timed_one_time_password = "000000"
        subject.save
      end

      it "throws an error if #f is not defined" do
        expect(instance).to receive(:perform_existing_candidate_request).and_call_original
        expect { subject.save }.to raise_error(NotImplementedError)
      end
    end

    context "when TOTP is correct" do
      it "updates the store with the response" do
        response = GetIntoTeachingApiClient::TeachingEventAddAttendee.new(candidateId: "abc123")
        expect(subject).to receive(:perform_existing_candidate_request).with(request) { response }
        subject.save
        expect(wizardstore["candidate_id"]).to eq(response.candidate_id)
      end

      it "does not overwrite data already in the store" do
        response = GetIntoTeachingApiClient::TeachingEventAddAttendee.new(candidateId: "abc123", firstName: "Jim")
        expect(subject).to receive(:perform_existing_candidate_request).with(request) { response }
        subject.save
        expect(wizardstore["candidate_id"]).to eq(response.candidate_id)
        expect(wizardstore["first_name"]).to eq("First")
      end
    end

    context "when TOTP is incorrect" do
      it "is marked as invalid" do
        expect(subject).to receive(:perform_existing_candidate_request).with(request)
          .and_raise(GetIntoTeachingApiClient::ApiError)
        expect(subject).to be_invalid
      end
    end
  end
end