FactoryBot.define do
  factory :node do
    parent { create(:node) }
    edge { create(:node) }
  end
end
