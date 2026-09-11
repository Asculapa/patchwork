# Identifies Patchwork to the sites it fetches, with a contact URL (§7.7).
Rails.application.config.x.user_agent =
  "Patchwork/0.1 (+#{ENV.fetch("PATCHWORK_CONTACT_URL", "http://localhost:3000")})"
