#!/usr/bin/env ruby
# frozen_string_literal: true

require "base64"
require "fileutils"
require "json"
require "net/http"
require "openssl"
require "uri"

ISSUER_ID = ENV.fetch("ASC_ISSUER_ID", "69a6de78-ba5a-47e3-e053-5b8c7c11a4d1")
KEY_ID = ENV.fetch("ASC_KEY_ID", "WZBYHD6QVD")
KEY_PATH = ENV.fetch(
  "ASC_KEY_FILE",
  "/Volumes/Crucial X6/@CodexAPP 13套戰略/永久列管/AuthKey_WZBYHD6QVD.p8"
)

BUNDLE_ID = "net.boss888.pocketarcade"
BUNDLE_NAME = "Pocket Arcade"
PROFILE_NAME = "Pocket Arcade App Store"
PROFILE_TYPE = "IOS_APP_STORE"
IAP_PRODUCT_IDS = [
  ["net.boss888.pocketarcade.unlockall", "Unlock All Games", "一次買斷，永久解鎖全部 10 款遊戲。"],
  ["net.boss888.pocketarcade.removeads", "Remove Ads", "一次買斷，移除廣告入口。"]
].freeze

class AppStoreConnectClient
  API_BASE = "https://api.appstoreconnect.apple.com"

  def initialize
    @private_key = OpenSSL::PKey.read(File.read(KEY_PATH))
  end

  def get(path, query = {})
    request(:get, path, query: query)
  end

  def post(path, body)
    request(:post, path, body: body)
  end

  def delete(path)
    request(:delete, path)
  end

  private

  def request(method, path, query: {}, body: nil)
    uri = URI("#{API_BASE}#{path}")
    uri.query = URI.encode_www_form(query) unless query.empty?
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = case method
              when :post then Net::HTTP::Post.new(uri)
              when :delete then Net::HTTP::Delete.new(uri)
              else Net::HTTP::Get.new(uri)
              end
    request["Authorization"] = "Bearer #{jwt}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(body) if body

    response = http.request(request)
    response_body = response.body.to_s
    parsed = response_body.empty? ? {} : JSON.parse(response_body)
    return parsed if response.code.to_i.between?(200, 299)

    raise "App Store Connect API #{method.upcase} #{path} failed #{response.code}: #{JSON.pretty_generate(parsed)}"
  end

  def jwt
    now = Time.now.to_i
    header = { alg: "ES256", kid: KEY_ID, typ: "JWT" }
    payload = { iss: ISSUER_ID, iat: now, exp: now + 1200, aud: "appstoreconnect-v1" }
    signing_input = [base64_json(header), base64_json(payload)].join(".")
    der_signature = @private_key.sign(OpenSSL::Digest::SHA256.new, signing_input)
    raw_signature = OpenSSL::ASN1.decode(der_signature).value.map do |integer|
      bytes = integer.value.to_s(2)
      ("\x00" * (32 - bytes.bytesize) + bytes)[-32, 32]
    end.join
    [signing_input, base64(raw_signature)].join(".")
  end

  def base64_json(object)
    base64(JSON.generate(object))
  end

  def base64(value)
    Base64.urlsafe_encode64(value).delete("=")
  end
end

def first_data(response)
  response.fetch("data", []).first
end

def exact_bundle_id(client)
  client.get("/v1/bundleIds", "filter[identifier]" => BUNDLE_ID, "limit" => "10")
        .fetch("data", [])
        .find { |item| item.dig("attributes", "identifier") == BUNDLE_ID }
end

def ensure_bundle_id(client)
  existing = exact_bundle_id(client)
  return existing if existing

  puts("Creating Bundle ID #{BUNDLE_ID}")
  client.post(
    "/v1/bundleIds",
    data: {
      type: "bundleIds",
      attributes: {
        identifier: BUNDLE_ID,
        name: BUNDLE_NAME,
        platform: "IOS"
      }
    }
  ).fetch("data")
end

def ensure_capability(client, bundle, capability)
  existing = client.get("/v1/bundleIds/#{bundle.fetch('id')}/bundleIdCapabilities")
                   .fetch("data", [])
                   .find { |item| item.dig("attributes", "capabilityType") == capability }
  return existing if existing

  puts("Enabling #{capability}")
  client.post(
    "/v1/bundleIdCapabilities",
    data: {
      type: "bundleIdCapabilities",
      attributes: { capabilityType: capability },
      relationships: {
        bundleId: {
          data: {
            type: "bundleIds",
            id: bundle.fetch("id")
          }
        }
      }
    }
  ).fetch("data")
end

def app_record(client)
  client.get("/v1/apps", "filter[bundleId]" => BUNDLE_ID, "limit" => "10")
        .fetch("data", [])
        .find { |item| item.dig("attributes", "bundleId") == BUNDLE_ID }
end

def ensure_iap(client, app, product_id, name, description)
  existing = first_data(client.get(
    "/v1/apps/#{app.fetch('id')}/inAppPurchasesV2",
    "filter[productId]" => product_id,
    "limit" => "1"
  ))
  return existing if existing

  iap = client.post(
    "/v2/inAppPurchases",
    data: {
      type: "inAppPurchases",
      attributes: {
        name: name,
        productId: product_id,
        inAppPurchaseType: "NON_CONSUMABLE",
        familySharable: false
      },
      relationships: {
        app: {
          data: {
            type: "apps",
            id: app.fetch("id")
          }
        }
      }
    }
  ).fetch("data")

  client.post(
    "/v1/inAppPurchaseLocalizations",
    data: {
      type: "inAppPurchaseLocalizations",
      attributes: {
        locale: "zh-Hant",
        name: name,
        description: description
      },
      relationships: {
        inAppPurchaseV2: {
          data: {
            type: "inAppPurchases",
            id: iap.fetch("id")
          }
        }
      }
    }
  )

  iap
rescue StandardError => error
  warn("IAP setup warning for #{product_id}: #{error.message}")
  nil
end

def distribution_certificate(client)
  client.get("/v1/certificates", "limit" => "100").fetch("data").find do |item|
    item.dig("attributes", "certificateType") == "DISTRIBUTION" &&
      item.dig("attributes", "name").to_s.include?("Apple Distribution")
  end || raise("No Apple Distribution certificate is available through this API key")
end

def recreate_profile(client, bundle, certificate)
  existing_profiles = client.get(
    "/v1/profiles",
    "filter[name]" => PROFILE_NAME,
    "filter[profileType]" => PROFILE_TYPE,
    "limit" => "10"
  ).fetch("data", [])
  existing_profiles.each do |profile|
    puts("Deleting old profile #{PROFILE_NAME}: #{profile.fetch('id')}")
    client.delete("/v1/profiles/#{profile.fetch('id')}")
  end

  client.post(
    "/v1/profiles",
    data: {
      type: "profiles",
      attributes: {
        name: PROFILE_NAME,
        profileType: PROFILE_TYPE
      },
      relationships: {
        bundleId: {
          data: {
            type: "bundleIds",
            id: bundle.fetch("id")
          }
        },
        certificates: {
          data: [
            {
              type: "certificates",
              id: certificate.fetch("id")
            }
          ]
        }
      }
    }
  ).fetch("data")
end

def install_profile(profile)
  content = profile.dig("attributes", "profileContent")
  raise "Profile #{PROFILE_NAME} has no profileContent" unless content

  local_dir = File.expand_path("../Build/profiles", __dir__)
  install_dir = File.expand_path("~/Library/MobileDevice/Provisioning Profiles")
  FileUtils.mkdir_p(local_dir)
  FileUtils.mkdir_p(install_dir)

  profile_filename = "#{profile.fetch('id')}.mobileprovision"
  local_path = File.join(local_dir, profile_filename)
  install_path = File.join(install_dir, profile_filename)
  File.binwrite(local_path, Base64.decode64(content))
  FileUtils.cp(local_path, install_path)
  puts("Profile id: #{profile.fetch('id')}")
  puts("Profile name: #{PROFILE_NAME}")
  puts("Installed: #{install_path}")
end

client = AppStoreConnectClient.new
bundle = ensure_bundle_id(client)
ensure_capability(client, bundle, "GAME_CENTER")
ensure_capability(client, bundle, "IN_APP_PURCHASE")

if (app = app_record(client))
  IAP_PRODUCT_IDS.each { |args| ensure_iap(client, app, *args) }
else
  warn("App record for #{BUNDLE_ID} does not exist yet. Create it in App Store Connect before IAP setup.")
end

certificate = distribution_certificate(client)
profile = recreate_profile(client, bundle, certificate)
install_profile(profile)
