# Create a mute timing for weekend market closing hours (Friday 22:00 UTC to Sunday 22:00 UTC)
# This is to prevent alerts from being fired during the weekend when FX markets are closed.
resource "grafana_mute_timing" "weekend_mute" {
  name = "Weekend Market Closing Hours"

  intervals {
    times {
      start = "22:00"
      end   = "24:00"
    }
    weekdays = ["friday"]
    location = "UTC"
  }

  intervals {
    weekdays = ["saturday"]
    location = "UTC"
  }

  intervals {
    times {
      start = "00:00"
      end   = "22:00"
    }
    weekdays = ["sunday"]
    location = "UTC"
  }
}
