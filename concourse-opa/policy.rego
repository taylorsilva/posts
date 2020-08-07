package concourse

default allow = false

allow {
  input.user == "test"
  input.action == "ListWorkers"
}

allow {
  input.action == "ListContainers"
}

allow {
  input.action == "ListContainers"
}

# main_team_only {
#     input.team == "main"
#     input.action == "ListContainers"
# }
