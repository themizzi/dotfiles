# CLI packages from the shared manifest; application bundles are separate.
File.foreach(File.join(__dir__, "packages/cli.tsv")) do |line|
  next if line.start_with?("#") || line.strip.empty?
  formula = line.split[4]
  brew formula unless formula == "-"
end
