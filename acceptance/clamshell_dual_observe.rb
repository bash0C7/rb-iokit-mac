# frozen_string_literal: true

# HITL: Clamshell semantic verification (dual-read).
#
# Establishes the ground-truth mapping between AppleClamshellState's raw
# boolean and physical lid state on this hardware, and isolates whether our
# Swift registry path is correct.
#
# WHY periodic-sampling (not step-style): the lid must be closed while the
# machine keeps running AND the lid-close event is processed normally. The
# only configuration that satisfies both on Apple Silicon is external-display
# "clamshell mode" (external display + power + external keyboard/mouse). In
# that mode you cannot press Enter at each step, so we sample on a timer and
# analyze the CSV after reopening the lid.
#
# WHY dual-read: each sample records BOTH
#   - closed_swift : IokitMac::Clamshell.closed?  (our Swift IOPMrootDomain path)
#   - raw_ioreg    : `ioreg -rd1 -c IOPMrootDomain | grep AppleClamshellState`
# If the two columns ever disagree, our Swift code reads the wrong thing
# (hypothesis "c"). If they always agree, any odd behavior is the property's
# own nature, not our bug.
#
# Background: a prior attempt via `pmset -b disablesleep 1` showed the value
# never flipped (76/76 samples false) because disablesleep suppresses the
# lid-close event handling that updates the property. Hence clamshell mode.
#
# Procedure (HITL, roles):
#   Claude Code : launch this in tmux detached, then analyze the CSV log.
#   Human       : set up clamshell mode, lid OPEN for a few samples, CLOSE the
#                 lid (machine stays awake), hold ~30-60s, then OPEN again.
#
# env vars:
#   INTERVAL  sampling interval (seconds, default 3)
#   DURATION  total observation time (seconds, default 300 = 5 min)

require_relative "../lib/iokit_mac"

interval = (ENV["INTERVAL"] || "3").to_i
duration = (ENV["DURATION"] || "300").to_i
start = Time.now

# Independent verification path: read the raw property straight from ioreg so
# we do not depend on our own Swift binding for the ground-truth column.
def raw_ioreg_clamshell
  line = `ioreg -rd1 -c IOPMrootDomain 2>/dev/null`.lines.find { |l| l.include?("AppleClamshellState") }
  return "absent" if line.nil?

  # Typical form:  "AppleClamshellState" = Yes  /  = No  (or true/false)
  value = line.split("=", 2)[1].to_s.strip
  value.empty? ? "empty" : value
end

puts "timestamp,elapsed_s,closed_swift,raw_ioreg"
$stdout.flush

loop do
  elapsed = Time.now - start
  break if elapsed >= duration

  closed_swift = IokitMac::Clamshell.closed?
  raw = raw_ioreg_clamshell

  puts [
    Time.now.strftime("%H:%M:%S"),
    elapsed.round(1),
    closed_swift.inspect,
    raw
  ].join(",")
  $stdout.flush

  sleep interval
end

puts "# observation complete (#{duration}s)"
puts "# analyze: align lid OPEN/CLOSED windows against closed_swift & raw_ioreg columns."
puts "# decide in lib/iokit_mac.rb whether semantic inversion is needed."
