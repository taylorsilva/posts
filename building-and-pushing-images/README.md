# Building and Pushing Container Images

In this blog post we are going to show how to build and push container images.

We'll need a repo to store everything. All the files referenced in this blog post can be found in [github.com/concourse/examples](https://github.com/concourse/examples).

We are going to be using the [oci-build task](https://github.com/vito/oci-build-task) and [registry-image resource](https://github.com/concourse/registry-image-resource).

First we need a Dockerfile. You can store this in your own repo or reference the [github.com/concourse/examples](https://github.com/concourse/examples) repo. The rest of this post assumes you used the examples repo.

```
dockerfile contents here
```
source: link-to-docker-file-here

Now we can start building out our pipeline. Let's declare our resources first. We'll need one resource to pull in the repo with our Dockerfile and a second resource pointing to where we want to push the built image to.

_There are some variables in this file that we'll fill out later_

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
- name: task-image
  type: registry-image
  icon: docker
  source:
    repository: ((image-repo-name))/task-image
    username: ((docker-username))
    password: ((docker-password))
```

Next we will create a job that will build and push our image.

To build the image we are going to use the [oci-build-task](https://github.com/vito/oci-build-task). The `oci-build-task` is an image that is meant to be used in a Concourse task to build container images. Check out the `README` in their repo for more details on how to configure and use the `oci-build-task`.

```yaml
jobs:
- name: build-and-push
  plan:
  - get: concourse-examples
    
```
