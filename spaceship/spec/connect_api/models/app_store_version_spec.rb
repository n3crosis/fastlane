describe Spaceship::ConnectAPI::AppStoreVersion do
  describe "#fetch_app_store_review_detail" do
    let(:app_store_version) { Spaceship::ConnectAPI::AppStoreVersion.new('id', {}) }
    let(:client) { double("client") }

    def stub_review_response(body, status: 200)
      response = Spaceship::ConnectAPI::Response.new(body: body, status: status)
      expect(client).to receive(:get_app_store_review_detail).with(
        app_store_version_id: 'id', includes: 'appStoreReviewAttachments'
      ).and_return(response)
    end

    it "returns nil when the review detail is absent" do
      stub_review_response({ "data" => nil })

      expect(app_store_version.fetch_app_store_review_detail(client: client)).to be_nil
    end

    it "returns an existing review detail with its attachments" do
      stub_review_response({
        "data" => {
          "type" => "appStoreReviewDetails", "id" => "review-id", "attributes" => { "notes" => "Review notes" },
          "relationships" => { "appStoreReviewAttachments" => { "data" => [{ "type" => "appStoreReviewAttachments", "id" => "attachment-id" }] } }
        },
        "included" => [{ "type" => "appStoreReviewAttachments", "id" => "attachment-id", "attributes" => { "fileName" => "review.pdf" } }]
      })

      detail = app_store_version.fetch_app_store_review_detail(client: client)
      expect(detail.id).to eq("review-id")
      expect(detail.notes).to eq("Review notes")
      expect(detail.app_store_review_attachments.map(&:id)).to eq(["attachment-id"])
    end

    it "does not treat a malformed response as an absent review detail" do
      stub_review_response({})

      expect { app_store_version.fetch_app_store_review_detail(client: client) }.to raise_error(RuntimeError, "No data")
    end

    it "does not treat a non-success response as an absent review detail" do
      stub_review_response({ "data" => nil }, status: 500)

      expect { app_store_version.fetch_app_store_review_detail(client: client) }.to raise_error(RuntimeError, "No data")
    end
  end

  describe "AppStoreVersion object" do
    describe "reverse maps attributes" do
      let(:app_store_version) { Spaceship::ConnectAPI::AppStoreVersion.new('id', {}) }
      let(:attribute_attributes) do
        {
          contact_first_name: "",
          contact_last_name: "",
          contact_phone: "",
          contact_email: "",
          demo_account_name: "",
          demo_account_password: "",
          demo_account_required: "",
          notes: ""
        }
      end

      it "maps attributes names to API names" do
        resp = double
        allow(resp).to receive(:to_models).and_return([])

        expect(Spaceship::ConnectAPI).to receive(:post_app_store_review_detail).with(app_store_version_id: 'id', attributes: {
          "contactFirstName" => "",
          "contactLastName" => "",
          "contactPhone" => "",
          "contactEmail" => "",
          "demoAccountName" => "",
          "demoAccountPassword" => "",
          "demoAccountRequired" => "",
          "notes" => ""
        }).and_return(resp)

        app_store_version.create_app_store_review_detail(attributes: attribute_attributes)
      end
    end
  end
end
