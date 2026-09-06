#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "uri"

require "jwt"
require "google/apis/androidpublisher_v3"
require "googleauth"

ROOT = File.expand_path("../..", __dir__)
BUNDLE = "pro.daddoodev.dailycompany"
UNLOCK = "A one-time unlock. No subscription."

PRODUCTS = [
  { sku: "benedict_daily_oblate", name: "Oblate",
    play: "Unlocks the rest of Benedict’s house." },
  { sku: "desales_companion", name: "Companion — de Sales",
    play: "Year-long Devout Life, Letters, Read Through." },
  { sku: "kempis_companion", name: "Companion — Kempis",
    play: "Imitation of Christ cycle and Read Through." },
  { sku: "liguori_companion", name: "Companion — Liguori",
    play: "The thirty-one Visits and Read Through." },
  { sku: "francis_companion", name: "Companion — Francis",
    play: "Writings, Little Flowers, Read Through." },
  { sku: "john_cross_companion", name: "Companion — John Cross",
    play: "Sayings on a repeating cycle and Read Through." },
  { sku: "gregory_companion", name: "Companion — Gregory",
    play: "Pastoral Rule twice a year and Read Through." },
  { sku: "augustine_companion", name: "Companion — Augustine",
    play: "Confessions through the year and Read Through." },
  { sku: "teresa_avila_companion", name: "Companion — Teresa",
    play: "Way of Perfection, Interior Castle, Read Through." },
  { sku: "ignatius_companion", name: "Companion — Ignatius",
    play: "Autobiography, Exercises, Read Through." },
  { sku: "therese_companion", name: "Companion — Thérèse",
    play: "Story of a Soul through the year and Read Through." },
  { sku: "catherine_companion", name: "Companion — Catherine",
    play: "The Dialogue through the year and Read Through." },
  { sku: "montfort_companion", name: "Companion — Montfort",
    play: "True Devotion through the year and Read Through." },
  { sku: "scupoli_companion", name: "Companion — Scupoli",
    play: "Spiritual Combat through the year and Read Through." },
  { sku: "lawrence_companion", name: "Companion — Lawrence",
    play: "Conversations and letters, Read Through." },
  { sku: "cassian_companion", name: "Companion — Cassian",
    play: "Conferences through the year and Read Through." },
  { sku: "serra_companion", name: "Companion — Serra",
    play: "Lasuén’s nine and the last three missions." },
  { sku: "all_saints", name: "Daily Company — All Saints",
    play: "Every open house. One-time.", usd: 14.99 },
].freeze

def usd_for(product)
  product[:usd] || 4.99
end

def micros(product)
  (usd_for(product) * 1_000_000).round.to_s
end

class Apple
  def initialize
    @token = jwt
  end

  def jwt
    key_id = File.read(File.join(ROOT, "secrets/apple/key_id")).strip
    issuer = File.read(File.join(ROOT, "secrets/apple/issuer_id")).strip
    pem = File.read(File.join(ROOT, "secrets/apple/AuthKey_K2MYWPZA23.p8"))
    JWT.encode(
      {
        iss: issuer,
        iat: Time.now.to_i,
        exp: Time.now.to_i + 1100,
        aud: "appstoreconnect-v1",
      },
      OpenSSL::PKey.read(pem),
      "ES256",
      { kid: key_id, typ: "JWT" },
    )
  end

  def call(method, path, body = nil)
    uri = URI("https://api.appstoreconnect.apple.com#{path}")
    req = Net::HTTP.const_get(method.capitalize).new(uri)
    req["Authorization"] = "Bearer #{@token}"
    req["Content-Type"] = "application/json"
    req.body = JSON.generate(body) if body
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(req)
    end
    parsed = res.body.to_s.empty? ? {} : JSON.parse(res.body)
    unless res.is_a?(Net::HTTPSuccess)
      raise "Apple #{method.upcase} #{path} #{res.code}: #{res.body}"
    end
    parsed
  end

  def app_id
    @app_id ||= begin
      data = call("get", "/v1/apps?filter[bundleId]=#{BUNDLE}")["data"]
      raise "Apple app not found" if data.nil? || data.empty?
      data.first["id"]
    end
  end

  def existing
    @existing ||= begin
      path = "/v1/apps/#{app_id}/inAppPurchasesV2?limit=200"
      rows = call("get", path)["data"] || []
      rows.to_h { |row| [row.dig("attributes", "productId"), row["id"]] }
    end
  end

  def price_point(iap_id, usd)
    path = "/v2/inAppPurchases/#{iap_id}/pricePoints?filter[territory]=USA&limit=200"
    points = call("get", path)["data"] || []
    want = format("%.2f", usd)
    hit = points.find { |p| p.dig("attributes", "customerPrice") == want }
    raise "No USA price point #{want} for #{iap_id}" unless hit
    hit["id"]
  end

  def localize(iap_id, product)
    call("post", "/v1/inAppPurchaseLocalizations", {
      data: {
        type: "inAppPurchaseLocalizations",
        attributes: {
          locale: "en-US",
          name: product[:name],
          description: UNLOCK,
        },
        relationships: {
          inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap_id } },
        },
      },
    })
  rescue RuntimeError => e
    raise unless e.message.include?("409") || e.message.include?("ENTITY_ERROR")
  end

  def price(iap_id, product)
    point = price_point(iap_id, usd_for(product))
    call("post", "/v1/inAppPurchasePriceSchedules", {
      data: {
        type: "inAppPurchasePriceSchedules",
        relationships: {
          inAppPurchase: { data: { type: "inAppPurchases", id: iap_id } },
          baseTerritory: { data: { type: "territories", id: "USA" } },
          manualPrices: { data: [{ type: "inAppPurchasePrices", id: "${price}" }] },
        },
      },
      included: [
        {
          type: "inAppPurchasePrices",
          id: "${price}",
          attributes: { startDate: nil },
          relationships: {
            inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap_id } },
            inAppPurchasePricePoint: {
              data: { type: "inAppPurchasePricePoints", id: point },
            },
          },
        },
      ],
    })
  end

  def ensure(product)
    sku = product[:sku]
    iap_id = existing[sku]
    if iap_id
      puts "Apple exists #{sku}"
    else
      created = call("post", "/v2/inAppPurchases", {
        data: {
          type: "inAppPurchases",
          attributes: {
            name: product[:name],
            productId: sku,
            inAppPurchaseType: "NON_CONSUMABLE",
            reviewNote: product[:play],
          },
          relationships: {
            app: { data: { type: "apps", id: app_id } },
          },
        },
      })
      iap_id = created.dig("data", "id")
      raise "Apple create missing id for #{sku}" unless iap_id
      existing[sku] = iap_id
      puts "Apple created #{sku}"
    end
    localize(iap_id, product)
    price(iap_id, product)
    iap_id
  end
end

class Play
  AP = Google::Apis::AndroidpublisherV3

  def initialize
    auth = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(File.join(ROOT, "secrets/google/play-store.json")),
      scope: "https://www.googleapis.com/auth/androidpublisher",
    )
    @svc = AP::AndroidPublisherService.new
    @svc.authorization = auth
  end

  def play_id(sku)
    sku.tr("-", "_")
  end

  def money(amount, currency)
    units, frac = format("%.2f", amount).split(".")
    AP::Money.new(
      currency_code: currency,
      units: units.to_i,
      nanos: frac.to_i * 10_000_000,
    )
  end

  def payload(product)
    sku = play_id(product[:sku])
    usd = usd_for(product)
    AP::OneTimeProduct.new(
      package_name: BUNDLE,
      product_id: sku,
      listings: [
        AP::OneTimeProductListing.new(
          language_code: "en-US",
          title: product[:name],
          description: product[:play],
        ),
      ],
      purchase_options: [
        AP::OneTimeProductPurchaseOption.new(
          purchase_option_id: "buy",
          buy_option: AP::OneTimeProductBuyPurchaseOption.new(
            legacy_compatible: true,
            multi_quantity_enabled: false,
          ),
          new_regions_config: AP::OneTimeProductPurchaseOptionNewRegionsConfig.new(
            availability: "AVAILABLE",
            usd_price: money(usd, "USD"),
            eur_price: money(usd == 14.99 ? 13.99 : 4.49, "EUR"),
          ),
          regional_pricing_and_availability_configs: [
            AP::OneTimeProductPurchaseOptionRegionalPricingAndAvailabilityConfig.new(
              region_code: "US",
              availability: "AVAILABLE",
              price: money(usd, "USD"),
            ),
          ],
        ),
      ],
      regions_version: AP::RegionsVersion.new(version: "2025/03"),
    )
  end

  def ensure(product)
    sku = play_id(product[:sku])
    @svc.patch_monetization_onetimeproduct(
      BUNDLE,
      sku,
      payload(product),
      allow_missing: true,
      regions_version_version: "2025/03",
      update_mask: "listings,purchaseOptions,packageName,productId",
    )
    puts "Play upserted #{sku}"
  rescue Google::Apis::ClientError => e
    raise "Play #{sku}: #{e.status_code} #{e.body}"
  end
end

apple = Apple.new
play = Play.new
unless ARGV.include?("--play-only")
  PRODUCTS.each do |product|
    raise "Apple name too long: #{product[:name]}" if product[:name].length > 30
    raise "Play title too long: #{product[:name]}" if product[:name].length > 55
    apple.ensure(product)
  end
end
PRODUCTS.each { |product| play.ensure(product) }
puts "Done #{PRODUCTS.length} products"
