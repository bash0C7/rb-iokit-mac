# frozen_string_literal: true

require_relative "lib/iokit_mac/version"

Gem::Specification.new do |spec|
  spec.name = "rb-iokit-mac"
  spec.version = IokitMac::VERSION
  spec.authors = ["bash0C7"]
  spec.email = ["ksb.4038.nullpointer+github@gmail.com"]

  spec.summary = "Ruby binding for macOS IOKit host-state signals"
  spec.description = "Reads root-free, public/stable IOKit signals from Ruby on macOS / Apple Silicon: battery, power adapter, clamshell, idle, thermal state, USB device enumeration, Bluetooth paired devices. Built on top of swift_gem. SPU HID sensors (ambient light, accelerometer, gyroscope, lid angle) live in a separate rb-spu-hid-mac gem."
  spec.homepage = "https://github.com/bash0C7/rb-iokit-mac"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bash0C7/rb-iokit-mac"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ acceptance/ docs/])
    end
  end
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/iokit_mac/extconf.rb"]
end
