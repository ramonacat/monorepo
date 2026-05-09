resource "google_billing_budget" "budget" {
  billing_account = "011C80-70ED0E-2572B5"
  display_name    = "Budget"
  amount {
    specified_amount {
      currency_code = "EUR"
      units         = "10"
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }

  all_updates_rule {
    monitoring_notification_channels = []
    enable_project_level_recipients  = true
  }
}
