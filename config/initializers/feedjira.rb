# Some Atom feeds skip <icon> and only publish a <logo> -- Feedjira's Atom
# parser doesn't expose it by default. FeedDocument falls back to it when
# <icon> is missing (see FeedDocument#initialize).
Feedjira::Parser::Atom.class_eval do
  element :logo
end
