package concourse

default allow = false

allow {
  input.action == "ListContainers"
}

allow {
  input.action == "ScheduleJob"
}

allow {
  input.action == "UseImage"
}
