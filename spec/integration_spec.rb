# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Integration" do
  let(:model_class) do
    build_test_model("TestUser") do
      self.base_key = "appTest123"
      self.table_name = "Users"

      field :first_name, "First Name"
      field :last_name, "Last Name"
      field :email, "Email Address"
      field :age, "Age"
      field :role, "Role"

      validates :first_name, :last_name, presence: true
      validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :age, numericality: { greater_than: 0 }, allow_nil: true

      before_save :normalize_email

      attr_accessor :email_normalized

      scope :adults, -> { where("AND({Age} >= 18, {Age} < 65)") }
      scope :admins, -> { where(role: "admin") }

      def normalize_email
        self.email = email&.downcase
        @email_normalized = true
      end

      def self.records(**params)
        @last_params = params
        []
      end

      class << self
        attr_reader :last_params
      end
    end
  end

  describe "full workflow" do
    it "combines field mappings, validations, callbacks, and queries" do
      # create with field mappings
      user = model_class.new(
        first_name: "Alice",
        last_name: "Smith",
        email: "ALICE@EXAMPLE.COM",
        age: 30,
        role: "admin"
      )

      # validations work
      expect(user.valid?).to be true

      # callbacks run on save
      allow(user).to receive(:_save).and_return(true)
      user.save
      expect(user.email_normalized).to be true
      expect(user.email).to eq("alice@example.com")

      # scopes use field mappings
      relation = model_class.adults.admins
      relation.to_a

      params = model_class.last_params
      expect(params[:filter]).to include("{Role} = 'admin'")
    end

    it "handles invalid records correctly" do
      user = model_class.new(email: "invalid")

      expect(user.valid?).to be false
      expect(user.save).to be false
      expect do
        user.save!
      end.to raise_error(AirctiveRecord::RecordInvalid)
    end
  end

  describe "dirty tracking with field mappings" do
    it "tracks changes through mapped fields" do
      user = model_class.new(first_name: "Alice", last_name: "Smith")

      user.first_name = "Alicia"

      expect(user.changed?).to be true
      expect(user.first_name_changed?).to be true
      expect(user.changes).to eq({ "first_name" => %w[Alice Alicia] })
    end
  end

  describe "query building with special characters" do
    it "escapes quotes properly" do
      relation = model_class.where(
        first_name: "O'Reilly",
        last_name: 'Say "hello"'
      )
      relation.to_a

      filter = model_class.last_params[:filter]
      expect(filter).to include("'O\\'Reilly'")
      expect(filter).to include('Say \\"hello\\"')
    end
  end

  describe "complex queries" do
    it "combines hash and raw formulas with field mappings" do
      relation = model_class
                 .where(role: "admin")
                 .where("{Age} >= 18")
                 .order(first_name: :asc, last_name: :desc)
                 .limit(20)

      relation.to_a
      params = model_class.last_params

      expect(params[:filter]).to eq("AND({Role} = 'admin', {Age} >= 18)")
      expect(params[:sort]).to eq([
                                    { field: "First Name", direction: "asc" },
                                    { field: "Last Name", direction: "desc" }
                                  ])
      expect(params[:max_records]).to eq(20)
    end
  end
end
