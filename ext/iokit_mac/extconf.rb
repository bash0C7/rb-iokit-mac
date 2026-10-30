# frozen_string_literal: true

require_relative "swift_mkmf"

SwiftGem::Mkmf.create_swift_makefile(
  "iokit_mac/iokit_mac",
  package: "IokitMac",
  source_dir: __dir__
)
