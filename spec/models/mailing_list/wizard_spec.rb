require "rails_helper"

describe MailingList::Wizard do
  describe ".steps" do
    subject { described_class.steps }

    it do
      is_expected.to eql [
        MailingList::Steps::Name,
        MailingList::Steps::DegreeStage,
        MailingList::Steps::TeacherTraining,
        MailingList::Steps::Subject,
        MailingList::Steps::Postcode,
        MailingList::Steps::Contact,
      ]
    end
  end
end