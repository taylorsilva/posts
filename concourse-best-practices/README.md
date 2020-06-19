# Concourse Best Practices

These are not necessarily "best" practices, they are common practices that we see a lot of teams follow

> There is no Best Practice. There’s just practice.
> - [Kelsey Hightower](https://www.youtube.com/watch?v=d_lFZtlM5KI)

Kelsey is definitely not the [first](https://www.satisfice.com/blog/archives/5164) [person](http://blogs.tedneward.com/post/there-is-no-such-thing-as-best-practices-context-matters/) to say this, but I found the quote fitting for this post. What follows are various "common" practices that we see many teams who use Concourse end up following.

## Put Task Config's in their own files

The [Task Step](https://concourse-ci.org/jobs.html#task-step) has this field, [config](https://concourse-ci.org/jobs.html#schema.step.task-step.config), where you can embed an enitre [Task Config](https://concourse-ci.org/tasks.html#schema.task) in your pipeline. This is helpful if you are building a pipeline and trying to get a feel for how many and what tasks your pipeline needs. Once you are past this pipeline development phase though you should move the [Task Config]() out to its own file.

### Example
Here's an example. When you are first writing your pipeline you may write it with the [Task Config]() embedded in the [Task step]() like this:
```yaml
jobs:
  - name: job
    public: true
    plan:
      - task: simple-task
        config:
          platform: linux
          image_resource:
            type: registry-image
            source: { repository: busybox }
          run:
            path: echo
            args: ["Hello, world!"]
```
Now let's break the pipeline up into two files.
_Note: we had to add a resource to make the task config availble in the pipeline_
[_separate-task-config.yaml_](https://github.com/concourse/examples/blob/master/pipelines/separate-task-config.yml)
```yaml
resources:
  - name: concourse-examples
    type: git
    icon: github
    source:
      uri: https://github.com/concourse/examples

jobs:
  - name: job
    public: true
    plan:
      - get: concourse-examples
      - task: simple-task
        file: concourse-examples/tasks/hello-world.yml
```

[_hello-world.yml_](https://github.com/concourse/examples/blob/master/tasks/hello-world.yml)
```yaml
platform: linux

image_resource:
  type: registry-image
  source: { repository: busybox }

run:
  path: echo
  args: ["Hello, world!"]
```

## Put Your CI Files in its Own Repo

If your team works out of multiple repositories (repo) then moving all your CI files into a single repository is a common practice. The Concourse team works out of [many repositories](https://github.com/concourse/) so we keep all of our CI files in our [CI repo](https://github.com/concourse/ci).

How you strucutre the files in this repo is up to you. Do what makes sense for your team. Here are some example directory layouts to get you started:

```
./ci
    /pipelines
        some-pipeline.yml
    /tasks
        test.yml
        build.yml
        /scripts
            test.sh
            build.sh
```
An alternative, keeping the task config and script together:
```
./ci
    /pipelines
        some-pipeline.yml
    /tasks
        /test
            test.yml
            run.sh
        /build
            build.yml
            run.sh
```

We have seen layouts where pipelines are heavily templated and broken into individual files for [Jobs](https://concourse-ci.org/jobs.html) and [Resources](https://concourse-ci.org/resources.html). It can become very hard to get a clear picture in your head of what the entire pipeline looks like if you break a single pipeline down into many files.

## Create A Common Task Image(s)

Your team probably depends on various cli tools and packages while developing. You probably need these same tools and packages to test, build, and deploy your software. Creating a common [task image](https://concourse-ci.org/tasks.html#schema.task.image_resource) that contains all the tools and packages you need to run your workflows in a pipeline is a common Concourse practice.

The Concourse team uses various images in our pipelines but there is one image that most of our tasks use, the [concourse/unit image](https://github.com/concourse/ci/blob/master/dockerfiles/unit/Dockerfile). This image is basically an installation script off all the tools we use to test and build Concourse.

## Separate Task Scripts From Task Configs

## Automate Updating Pipelines
