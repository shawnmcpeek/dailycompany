#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "pathname"

ROOT = Pathname.new(__dir__).join("../..").expand_path
SOURCE = ROOT.join("store/listing.yml")

LIMITS = {
  name: 30,
  subtitle: 30,
  short_description: 80,
  promotional_text: 170,
  description: 4000,
  keywords: 100,
  release_notes: 4000
}.freeze

def fail!(msg)
  warn(msg)
  exit 1
end

def one_line(text)
  text.to_s.gsub(/\s+/, " ").strip
end

def body(text)
  text.to_s.gsub("\r\n", "\n").rstrip
end

def write!(path, text)
  fail!("Refusing empty file: #{path}") if text.strip.empty?
  path.dirname.mkpath
  path.write("#{text}\n")
end

def check_limit!(field, text)
  limit = LIMITS.fetch(field)
  n = text.length
  fail!("#{field} is #{n} chars (limit #{limit})") if n > limit
  printf("%-22s %4d / %4d\n", field, n, limit)
end

def words_in(*texts)
  texts.join(" ").downcase.scan(/[a-z0-9]+/)
end

fail!("Missing #{SOURCE}") unless SOURCE.file?

data = YAML.safe_load(SOURCE.read, filename: SOURCE.to_s) || {}
%w[
  name subtitle short_description promotional_text description
  keywords release_notes support_url marketing_url privacy_url copyright
].each do |key|
  fail!("listing.yml missing #{key}") if data[key].to_s.strip.empty?
end

name = one_line(data["name"])
subtitle = one_line(data["subtitle"])
short_description = one_line(data["short_description"])
promotional_text = one_line(data["promotional_text"])
description = body(data["description"])
keywords = one_line(data["keywords"]).delete(" ")
release_notes = one_line(data["release_notes"])
support_url = one_line(data["support_url"])
marketing_url = one_line(data["marketing_url"])
privacy_url = one_line(data["privacy_url"])
copyright = one_line(data["copyright"])

banned = words_in(name, subtitle)
overlap = keywords.split(",").map(&:strip).reject(&:empty?).select { |k| banned.include?(k.downcase) }
fail!("keywords repeat name/subtitle words: #{overlap.join(', ')}") unless overlap.empty?

check_limit!(:name, name)
check_limit!(:subtitle, subtitle)
check_limit!(:short_description, short_description)
check_limit!(:promotional_text, promotional_text)
check_limit!(:description, description)
check_limit!(:keywords, keywords)
check_limit!(:release_notes, release_notes)

ios = ROOT.join("fastlane/metadata/en-US")
play = ROOT.join("fastlane/metadata/android/en-US")

write!(ios.join("name.txt"), name)
write!(ios.join("subtitle.txt"), subtitle)
write!(ios.join("promotional_text.txt"), promotional_text)
write!(ios.join("description.txt"), description)
write!(ios.join("keywords.txt"), keywords)
write!(ios.join("release_notes.txt"), release_notes)
write!(ios.join("support_url.txt"), support_url)
write!(ios.join("marketing_url.txt"), marketing_url)
write!(ios.join("privacy_url.txt"), privacy_url)
write!(ROOT.join("fastlane/metadata/copyright.txt"), copyright)

write!(play.join("title.txt"), name)
write!(play.join("short_description.txt"), short_description)
write!(play.join("full_description.txt"), description)

puts "Wrote iOS + Play metadata from #{SOURCE.relative_path_from(ROOT)}"
