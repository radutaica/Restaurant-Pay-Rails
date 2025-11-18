# Minimal Pry configuration
# pry-rails handles most of the setup automatically

# Enable awesome_print for pretty printing (if available)
begin
  require 'awesome_print'
  AwesomePrint.pry!
rescue LoadError
  # awesome_print not available, skip
end

# Enable syntax highlighting with CodeRay (if available)
begin
  require 'coderay'
  Pry.config.color = true
rescue LoadError
  # coderay not available, skip
end
