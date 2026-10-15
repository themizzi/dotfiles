# CLI dev profile; desktop and personal apps require an explicit selection.
File.foreach(File.join(__dir__, "packages/cli.tsv")) do |line|
  next if line.start_with?("#") || line.strip.empty?
  formula = line.split[5]
  brew formula unless formula == "-"
end
