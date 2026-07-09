require "rails_helper"

module Paprika
  RSpec.describe Recipe do
    describe "#display_image_url" do
      def signed(expires_at) = "https://s3.amazonaws.com/x.jpg?AWSAccessKeyId=k&Expires=#{expires_at}&Signature=s"

      it "prefers the Paprika photo while its signed URL is still valid" do
        url = signed(Time.now.to_i + 3600)
        recipe = Recipe.new(ZPHOTOURL: url, ZIMAGEURL: "https://src.example/img.jpg")
        expect(recipe.display_image_url).to eq(url)
      end

      it "falls back to the stable source image once the photo URL has expired" do
        recipe = Recipe.new(ZPHOTOURL: signed(Time.now.to_i - 3600), ZIMAGEURL: "https://src.example/img.jpg")
        expect(recipe.display_image_url).to eq("https://src.example/img.jpg")
      end

      it "returns nil for a photo-only recipe whose signed URL has expired" do
        recipe = Recipe.new(ZPHOTOURL: signed(Time.now.to_i - 3600), ZIMAGEURL: nil)
        expect(recipe.display_image_url).to be_nil
      end

      it "uses the source image when there is no photo" do
        recipe = Recipe.new(ZPHOTOURL: nil, ZIMAGEURL: "https://src.example/img.jpg")
        expect(recipe.display_image_url).to eq("https://src.example/img.jpg")
      end
    end
  end
end
