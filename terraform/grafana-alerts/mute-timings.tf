# Create a mute timing for weekends (Friday 23:00 CET to Sunday 22:00 CET)
# This is to prevent alerts from being fired during the weekend.
resource "grafana_mute_timing" "weekend_mute" {
  name = "Weekend Hours"

  intervals {
    times {
      start = "23:00"
      end   = "24:00"
    }
    weekdays = ["friday"]
    location = "Europe/Berlin"
  }

  intervals {
    weekdays = ["saturday"]
    location = "Europe/Berlin"
  }

  intervals {
    times {
      start = "00:00"
      end   = "22:00"
    }
    weekdays = ["sunday"]
    location = "Europe/Berlin"
  }
}
