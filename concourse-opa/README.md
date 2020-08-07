# Connecting Concourse to OPA

Do you like applying policies to your services? Is Concourse one of those services? Then this is the guide for you!

In this blog post we are going to go over how to configure Concourse to do policy checks against an OPA server. If you want to learn more about OPA I suggest [reading the docs](https://www.openpolicyagent.org/docs/latest/) as a starting point. We will go over a few use-cases in this blog post so you can get started with some Concourse specific policies with your OPA server.

We will be doing everything locally by using a Docker Compose file to run Concourse and an OPA server.

### Configuring Concourse

We need to configure Concourse with a two things:
* The OPA endpoint
* The actions we want to apply policies to

To configure these two things we will use the following flags that we fetched from the Concourse binary (`concourse web --help`):
```
Policy Checking:
 --policy-check-filter-http-method=     API http method to go through policy check
 --policy-check-filter-action=          Actions in the list will go through policy check
 --policy-check-filter-action-skip=     Actions the list will not go through policy check

Policy Check Agent (Open Policy Agent):
 --opa-url=                             OPA policy check endpoint.
 --opa-timeout=                         OPA request timeout. (default: 5s)
```

The Policy Checker in Concourse has been designed to support any other policy checking servers. Currently only OPA is implemented. Anyone can feel free to add other policy checking agents.

Let's start by configuring the Open Policy Agent. We can do this by setting the `CONCOURSE_OPA_URL` variable. It will look like this in our docker-compose.yml file:

```yaml
concourse:
  image: concourse/concourse
  ...
  environment:
    ...
    CONCOURSE_OPA_URL: http://opa:8181/v1/data/concourse/allow
```

This will point Concourse to the `opa` service that we will define later in our docker-compose.yml file.

Next we need to specify which actions we want Concourse to policy check. To find out what actions we can ask Concourse to check we can look at the list of API actions at the top of [routes.go](https://github.com/concourse/concourse/blob/master/atc/routes.go). There is also one extra action called [`UseImage`](https://github.com/concourse/concourse/blob/master/atc/policy/checker.go) that we will look at later.

Since most actions refer to API endpoints you need to specify the HTTP method(s) and API endpoint in order to have Concourse perform a check against that endpoint. The same rule does not apply for non-HTTP actions, which is currently just the `UseImage` action.

To start we will check the `ListWorkers` and `ListContainers` endpoints, both are `GET` endpoints (_this info is also in [routes.go](https://github.com/concourse/concourse/blob/master/atc/routes.go) at the bottom_). We will also add the `UseImage` action.
```yaml
concourse:
  image: concourse/concourse
  ...
  environment:
    ...
    CONCOURSE_POLICY_CHECK_FILTER_HTTP_METHODS: GET
    CONCOURSE_POLICY_CHECK_FILTER_ACTION: ListWorkers,ListContainers,UseImage
```




---
Need to point concourse to an OPA server.
Need to specify which Actions/HTTP Methods will go through the policy check.

the resulting "policyChecker" is passed into the creation of API members and backend components.

API Members:
  -> fed into API handler creation to create a new wrappa to do policy checks. Wraps each action in routes.go and checks it!

Backend Members:
  -> what is it checking???
  -> another dbWorkerProvider??? why?? why do we initialize two??
  -> Fed into the worker provider and further fed into the Garden client. Used to check for image policy. Action is called "UseImage". Sends a bunch of data about the image in this map format:
		imageInfo["privileged"] = bool
		imageInfo["image_type"] = imageSpec.ImageResource.Type
		imageInfo["image_source"] = imageSpec.ImageResource.Source
        So you can probably use this to block privileged containers from runnin on certain workers, certain image types, and images from certain sources.



### What do we need to setup on the OPA Server end?

You need to give opa a .rego file. You can create one specific to a concourse cluster. The json passed in has these fields:

```go
type PolicyCheckInput struct {
	Service        string      `json:"service"`
	ClusterName    string      `json:"cluster_name"`
	ClusterVersion string      `json:"cluster_version"`
	HttpMethod     string      `json:"http_method,omitempty"`
	Action         string      `json:"action"`
	User           string      `json:"user,omitempty"`
	Team           string      `json:"team,omitempty"`
	Pipeline       string      `json:"pipeline,omitempty"`
	Data           interface{} `json:"data,omitempty"`
}
```

```json
{
    "servce": "",
    "cluster_name": "",
    "cluster_version": "",
    "http_method": "",
    "action": "",
    "user": "",
    "team": "",
    "pipeline": "",
    "data": {}
}
```

So you can access any field directly from `input`, like `input.cluster_name` or `input.action`
