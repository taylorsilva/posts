package concourse

default allow = false

allow {
  count(violation) == 0
}

violation[input.action] {
  input.action == "ListContainers"
}

allow {
  input.team == "main"
  input.action == "ListContainers"
}

allow {
  input.action == "UseImage"
  input.data.image_source.repository == "busybox"
}
