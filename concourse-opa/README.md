# Connecting Concourse to OPA

In this blog post we are going to go over how to configure Concourse to do policy checks against an OPA server. If you want to learn more about the OPA project I suggest [reading the docs](https://www.openpolicyagent.org/docs/latest/) as a starting point. We will go over a few use-cases in this blog post so you can get started with some Concourse specific policies with your OPA server.

The audience for this blog post is people who run and manage one or more Concourse clusters. Policies are an easy way to ensure the tenants of your Concourse cluster are being good citizens. We'll dig into this as we start writing OPA rules.

We will be doing everything locally by using a Docker Compose file to run Concourse and an OPA server. The [docker-compose.yml can be found in this gist](https://gist.github.com/taylorsilva/2bdbeb8c0d985f1c61ff539a9dd16a24). Simply download that file to a directory and run `docker-compose up -d` to start Concourse and an OPA service.

## Configuring Concourse

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

For the BOSH release of Concourse look here.
For the Concourse Helm chart look here.

Let's start by configuring the Open Policy Agent. We can do this by setting the `CONCOURSE_OPA_URL` variable. It will look like this in our docker-compose.yml file:

```yaml
concourse:
  image: concourse/concourse
  ...
  environment:
    ...
    CONCOURSE_OPA_URL: http://opa:8181/v1/data/concourse/check
```

The OPA URL has the format of `http://host/v1/data/<package path>/<rule name>`. You can read more about how OPA package and rule naming works in the [OPA docs](https://www.openpolicyagent.org/docs/latest/integration/#named-policy-decisions).

This will point Concourse to the `opa` service that we will define later in our docker-compose.yml file.

Next we need to specify which actions we want Concourse to policy check. To find out what actions we can ask Concourse to check we can look at the list of API actions at the top of [routes.go](https://github.com/concourse/concourse/blob/master/atc/routes.go). There is also one extra action called [`UseImage`](https://github.com/concourse/concourse/blob/master/atc/policy/checker.go) that we will look at later.

Since most actions refer to API endpoints you need to specify the HTTP method(s) and API endpoint in order to have Concourse perform a check against that endpoint. The same rule does not apply for non-HTTP actions, which is currently only the `UseImage` action.

To start we will check the `ListAllJobs` and `ListContainers` endpoints, both are `GET` endpoints (_this info is also in [routes.go](https://github.com/concourse/concourse/blob/master/atc/routes.go) at the bottom half of the file_). We will also add the `UseImage` action for experimenting with later.
```yaml
concourse:
  image: concourse/concourse
  ...
  environment:
    ...
    CONCOURSE_POLICY_CHECK_FILTER_HTTP_METHODS: GET
    CONCOURSE_POLICY_CHECK_FILTER_ACTION: ListContainers,UseImage
```

Concourse is now ready to start talking to an OPA server. Let's setup an OPA server next.

## Setup the OPA Server

In our docker-compose.yml file there is an `opa` service that Concourse will be able to reach. It has been configured to watch for any `*.rego` files that are in the same directory.

```yaml
  opa:
    image: openpolicyagent/opa
    command:
    - run
    - --server
    - --log-level=debug
    - --watch
    - /concourse-opa
    volumes:
    # we assume your .rego file(s) are in the current working dir as this
    # docker-compose file
    - ./:/concourse-opa
```

In the same directory as the `docker-compose.yml` file, create a `policy.rego` file and put the following into it:

```
package concourse

# replace with 'false' to add rules
default check = true
```

The package name is `concourse` and the only rule in it is the `check` rule, which matches what we set the `CONCOURSE_OPA_URL` to. Currently it will allow all checks to pass. We will change this later.

At this point we can bring up Concourse and the OPA server:

```bash
$ docker-compose up -d
```

Visit [http://localhost:8080/](http://localhost:8080/) to verify that Concourse is up.

Let's set the [time-triggered](https://github.com/concourse/examples/blob/master/pipelines/time-triggered.yml) pipeline to seed some data and activity in our Concourse.

```bash
$ fly -t dev login -c "http://localhost:8080" -u test -p test -n main

$ fly -t dev sp -p time-triggered -c time-triggered.yml

$ fly -t dev up -p time-triggered
```

Now we can start experimenting with OPA rules!

## OPA Rules

The OPA server has been configured to watch for for updates to our `policy.rego` file, so we can make changes and immediately see the effect it has on a Concourse user. Currently our policy allows every check from Concourse to pass. Let's change that and add some rules.

Lets add some rules that still allow every check to pass. This package logic says:

```
policy check passes if the action is ListContainers OR the action is UseImage
```

```
package concourse

default check = false

check {
  input.action == "ListContainers"
}

check {
  input.action == "UseImage"
}
```

If you trigger the pipeline or wait for it to be triggered you should see the job continue to pass:

![image of passing job](dashboard-job-green.png)

## OPA Fields

In order to start writing rules we need to know what data Concourse is passing to OPA when performing a check. Here's the JSON that Concourses ends to OPA:

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
The following table gives more details on each key:

Key | Details
--- | ---
`service` | Always present and set to `concourse`
`cluster_name` | Always present
`cluster_version` | Always present and set to the Concourse version
`cluster_version` | Always present
`action` | Always present
`http_method` | Only for HTTP API actions
`user` | Only for HTTP API actions
`team` | Only for HTTP API actions where the team name is in the URL path
`pipeline` | Only for HTTP API actions where pipeline name is in the URL path
`data` | A map. For API actions the request body is passed in here.

Now that we know what fields we have access to we can start writing some rules!

## Block ListContainers

When someone runs `fly containers` they see all the containers for their team. We can disable this endpoint completely by writing the following rule, which has the following logic:

```
policy check passes if violations are zero
```

```
package concourse

default check = false

check {
  count(violation) == 0
}

violation[input.action] {
  input.action == "ListContainers"
}
```
If you run `fly containers` now you'll get the following:
```
$ fly -t dev containers
error: forbidden
```

Now what if we still want some subset of uesrs or a team to still be able to call this endpoint? 
We can add a rule, `allowed`, so users on the `main` team can still run the `containers` command. The logic of the following package is now:

```
policy check passes if violations are zero OR allowed is >= to one
```

```
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
```

Now if you run `fly containers` you should see a list of containers instead of an error. If someone that is not on the `main` team tries to list containers they'll get `error forbidden`.

Hopefully this example gave you an idea about what kinds of rules you can write for the API endpoints. I highly recommend reading the [OPA docs](https://www.openpolicyagent.org/docs/latest/) to help you think of other rules you can write.

Let's move onto one last very interesting usage of OPA and Concourse.

## The UseImage Action

The `UseImage` action allows Concourse operators to have some say over what images users are allowed to use in their pipelines.

The `UseImage` action populates the `data` key with the following properties:

Key | Details
--- | ---
privileged | The value of [task-step.privileged](https://concourse-ci.org/jobs.html#schema.step.task-step.privileged)
image_type | The resource type used to fetch the task image (e.g. `registry-image`)
image_source | The [Source](https://concourse-ci.org/resource-types.html#schema.resource_type.source) passed into the resource type

For example, if someone was using the [registry-image-resource](https://github.com/concourse/registry-image-resource/) to fetch the [concourse/concourse image](https://hub.docker.com/r/concourse/concourse) the `data` field would be populated with the fields we find in [source of the registry-image](https://github.com/concourse/registry-image-resource/#source-configuration).

Give this resource type in a pipeline:

```yaml
resources:
- name: concourse-image
  type: registry-image
  source:
    repository: concourse/concourse
    tag: latest
```

The following JSON will be sent to OPA:

```json
{
    "servce": "concourse",
    "cluster_name": "my-ci",
    "cluster_version": "6.4.0",
    "action": "UseImage",
    "team": "some-team",
    "pipeline": "some-pipeline",
    "data": {
        "privileged": false,
        "image_type": "registry-image",
        "image_source": {
            "repository": "concourse/concourse",
            "tag": "latest"
        }
    }
}
```

With this information we can do a few things, such as:
* Prevent users from running privileged tasks
* Block users from using certain images
* Only allows images from a specific image registry

Let's write some policies that implement the above behaviour.

### Block Privileged Tasks

If we want to prevent everyone on our Concourse cluster from running privileged tasks we can add the following rule to `policy.rego`.

```
allow {
  count(violation) == 0
}

violation[input.action] {
  input.action == "UseImage"
  input.data.privileged == "true"
}
```

Now if we change our pipeline to run a `privileged` task we'll get the following error:



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
