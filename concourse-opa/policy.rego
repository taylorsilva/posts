package concourse

default check = false

check {
  count(violation) == 0
}

check {
  count(allowed) >= 1
}

violation[input.action] {
  input.action == "ListContainers"
}

allowed[input.action] {
  input.team == "main"
  input.action == "ListContainers"
}

allowed[input.action] {
  input.action == "UseImage"
  input.data.image_source.repository == "busybox"
}

violation[input.action] {
  input.action == "UseImage"
  input.data.privileged == true
}
