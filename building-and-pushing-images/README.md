# Building and Pushing Container Images

In this blog post we are going to show how to build and push container images using the [oci-build task](https://github.com/vito/oci-build-task) and [registry-image resource](https://github.com/concourse/registry-image-resource). The first example will be very simple. More complex example images and pipelines will be provided later.

We will need a repo to store some files. All the files referenced in this blog post can be found in [github.com/concourse/examples](https://github.com/concourse/examples).

First we need a Dockerfile. You can store this in your own repo or reference the [github.com/concourse/examples](https://github.com/concourse/examples) repo. The rest of this post assumes you use the [examples](https://github.com/concourse/examples) repo.

We are going to use a very basic [Dockerfile](https://github.com/concourse/examples/blob/master/Dockerfiles/simple/Dockerfile) so we can focus on the Concourse mechanics.

```
FROM busybox

RUN echo "I'm simple!"
```

Now we can start building out our pipeline. Let's declare our [resources](https://concourse-ci.org/resources.html) first. We will need one resource to pull in the repo where our Dockerfile is located, and a second resource pointing to where we want to push the built image to.

_There are some [variables](https://concourse-ci.org/pipeline-vars-example.html#variables) in this file that we will fill out later._

```yaml
resources:
# The repo with our Dockerfile
- name: concourse-examples
  type: git
  icon: github
  source:
    uri: https://github.com/concourse/examples.git
    branch: master

# Where we will push the image to
- name: simple-image
  type: registry-image
  icon: docker
  source:
    repository: ((image-repo-name))/simple-image
    username: ((docker-username))
    password: ((docker-password))
```

Next we will create a [job](https://concourse-ci.org/jobs.html) that will build and push our image.

```yaml
jobs:
- name: build-and-push
```

The first [step](https://concourse-ci.org/jobs.html#schema.step) in the [job plan](https://concourse-ci.org/jobs.html#schema.job.plan) will be to retrieve the repo where our Dockerfile is.

```yaml
jobs:
- name: build-and-push
  plan:
  - get: concourse-examples
```

The second step will build the image.

To build the image we are going to use the [oci-build-task](https://github.com/vito/oci-build-task). The [oci-build-task](https://github.com/vito/oci-build-task) is an image that is meant to be used in a Concourse [task](https://concourse-ci.org/tasks.html) to build container images. Check out the [`README`](https://github.com/vito/oci-build-task/blob/master/README.md) in the repo for more details on how to configure and use the [oci-build-task](https://github.com/vito/oci-build-task) in more complex build scenarios.

Let's add a [task](https://concourse-ci.org/tasks.html) to our [job plan](https://concourse-ci.org/jobs.html#schema.job.plan) and give it a name.

```yaml
jobs:
- name: build-and-push
  plan:
  - get: concourse-examples
  - task: build-task-image
```

All configuration of the `oci-build-task` is done through a [task config](https://concourse-ci.org/tasks.html). Viewing the [`README`](https://github.com/vito/oci-build-task/blob/master/README.md) from the repo we can see that the task needs to be run as a [privileged task](https://concourse-ci.org/jobs.html#schema.step.task-step.privileged) on a linux worker.

```yaml
jobs:
- name: build-and-push
  plan:
  - get: concourse-examples
  - task: build-task-image
    privileged: true
    config:
      platform: linux
```

To use the `oci-build-task` image we specify the [`image_resource`](https://concourse-ci.org/tasks.html#schema.task.image_resource) that the task should use.

```yaml
jobs:
- name: build-and-push
  plan:
  - get: concourse-examples
  - task: build-task-image
    privileged: true
    config:
      platform: linux
      image_resource:
        type: registry-image
        source:
          repository: vito/oci-build-task
```

Next we will add [`concourse-examples`](https://github.com/concourse/examples) as an [input](https://concourse-ci.org/tasks.html#schema.task.inputs) to the task to ensure the artifact from the [get step](https://concourse-ci.org/jobs.html#get-step) is mounted in our `build-task-image` step.

```yaml
jobs:
- name: build-and-push
  plan:
  - get: concourse-examples
  - task: build-task-image
    privileged: true
    config:
      platform: linux
      image_resource:
        type: registry-image
        source:
          repository: vito/oci-build-task
      inputs:
      - name: concourse-examples
```

The `oci-build-task` [outputs the built image](https://github.com/vito/oci-build-task#outputs) in a directory called `image`. Let's add `image` as an output artifact of our task.

```yaml
jobs:
- name: build-and-push
  plan:
  - get: concourse-examples
  - task: build-task-image
    privileged: true
    config:
      platform: linux
      image_resource:
        type: registry-image
        source:
          repository: vito/oci-build-task
      inputs:
      - name: concourse-examples
      outputs:
      - name: image
```

Next we need to tell the `oci-build-task` what the [build context](https://docs.docker.com/engine/reference/commandline/build/) of our Dockerfile is. The [`README`](https://github.com/vito/oci-build-task) goes over a few other methods of creating your build context. We are going to use the simplest use-case.

```yaml
jobs:
- name: build-and-push
  plan:
  - get: concourse-examples
  - task: build-task-image
    privileged: true
    config:
      platform: linux
      image_resource:
        type: registry-image
        source:
          repository: vito/oci-build-task
      inputs:
      - name: concourse-examples
      outputs:
      - name: image
      params:
        CONTEXT: concourse-examples/Dockerfiles/simple
```

The last step is specifying what our `build-task-image` should execute. The `oci-build-task` image has a binary named [`build`](https://github.com/vito/oci-build-task/blob/230df3baa27fb389484ee0fb74355cd8b7977298/Dockerfile#L11) located in its `PATH` in the [`/usr/bin` directory](https://github.com/vito/oci-build-task/blob/230df3baa27fb389484ee0fb74355cd8b7977298/Dockerfile#L15). We'll tell our task to execute that binary, which will build our image.

```yaml
jobs:
- name: build-and-push
  plan:
  - get: concourse-examples
  - task: build-task-image
    privileged: true
    config:
      platform: linux
      image_resource:
        type: registry-image
        source:
          repository: vito/oci-build-task
      params:
        CONTEXT: concourse-examples/Dockerfiles/simple
      inputs:
      - name: concourse-examples
      outputs:
      - name: image
      run:
        path: build
```

At this point in our job the image is built! The `oci-build-task` has saved the image as a tarball named `image.tar` in the `image` artifact specified in the task outputs. This tar file is the same output you would get if you built the image using Docker and then did [`docker save`](https://docs.docker.com/engine/reference/commandline/save/).

Now let's push the image to an image registry! For this example we're pushing to [Docker Hub](https://hub.docker.com/) using the [`registry-image` resource](https://github.com/concourse/registry-image-resource). You can use the `registry-image` resource to push to any image registry, private or public. Check out the [`README.md`](https://github.com/concourse/registry-image-resource/blob/master/README.md) for more details on using the resource.

Pushing the image is simple, simply add a [put step](https://concourse-ci.org/jobs.html#put-step) to our job plan and tell the regstry-image resource where the tarball of the image is.

The put step will push the image using the information defined in the resource's [source](https://concourse-ci.org/resources.html#schema.resource.source).

This is where you'll need to replace the three [variables](https://concourse-ci.org/vars.html) found under `resource_types`. You can define them [statically](https://concourse-ci.org/vars.html#static-vars) using `fly`'s `--var` flag when [setting](https://concourse-ci.org/setting-pipelines.html) the pipeline. _(In production make sure to use [credential management](https://concourse-ci.org/creds.html) to store your secrets!)_

```yaml
jobs:
- name: build-and-push
  plan:
  - get: concourse-examples
  - task: build-task-image
    privileged: true
    config:
      platform: linux
      image_resource:
        type: registry-image
        source:
          repository: vito/oci-build-task
      params:
        CONTEXT: concourse-examples/Dockerfiles/simple
      inputs:
      - name: concourse-examples
      outputs:
      - name: image
      run:
        path: build
  - put: simple-image
    params:
      image: image/image.tar
```

Putting all the pieces together, here is our pipeline.

```yaml
resources:
# The repo with our Dockerfile
- name: concourse-examples
  type: git
  icon: github
  source:
    uri: https://github.com/concourse/examples.git
    branch: master

# Where we will push the image
- name: simple-image
  type: registry-image
  icon: docker
  source:
    repository: ((image-repo-name))/simple-image
    username: ((docker-username))
    password: ((docker-password))

jobs:
- name: build-and-push
  plan:
  - get: concourse-examples
  - task: build-task-image
    privileged: true
    config:
      platform: linux
      image_resource:
        type: registry-image
        source:
          repository: vito/oci-build-task
      inputs:
      - name: concourse-examples
      outputs:
      - name: image
      params:
        CONTEXT: concourse-examples/Dockerfiles/simple
      run:
        path: build
  - put: simple-image
    params:
      image: image/image.tar
```


---

I want to show a pipeline that combines multiple inputs to create a build context
