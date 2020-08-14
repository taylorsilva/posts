package concourse

default allow = false

allow {
# the team was not set. Guessing it's not set for non-team endpoints which makes sense...
  input.user == "test"
  input.action == "ListWorkers"
}

allow {
  input.action == "ListContainers"
}

allow {
  input.action == "ListContainers"
}
