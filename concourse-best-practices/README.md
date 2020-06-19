# Concourse Best Practices

These are not necessarily "best" practices, they are common practices that we see a lot of teams follow

> There is no Best Practice. There’s just practice.
> - Kelsey Hightower

Kelsey is definitely not the [first ](https://www.satisfice.com/blog/archives/5164) [person](http://blogs.tedneward.com/post/there-is-no-such-thing-as-best-practices-context-matters/) to say this but I found the quote fitting for this post. What follows are various "common" practices that we see many teams who use Concourse end up following.

## Put Tasks Config's in their own files

## Put Your CI Files in a Different Repo

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
            test.sh
        /build
            build.yml
            build.sh
```

I have seen layouts where pipelines are heavily templated and broken into individual files for [Jobs](https://concourse-ci.org/jobs.html) and [Resources](https://concourse-ci.org/resources.html). It can become very hard to get a clear picture in your head of what the entire pipeline looks like if you break a single pipeline down into many files.

## Create A Common Task Image(s)

Your team probably depends on various cli tools and packages while developing. You probably need these same tools and packages to test, build, and deploy your software. Creating a common [task image](https://concourse-ci.org/tasks.html#schema.task.image_resource) that contains all the tools and packages you need to run your workflows in a pipeline is a common Concourse practice.

The Concourse team uses various images in our pipelines but there is one image that most of our tasks use, the [concourse/unit image](https://github.com/concourse/ci/blob/master/dockerfiles/unit/Dockerfile). This image is basically an installation script off all the tools we use to test and build Concourse.

## Separate Task Scripts From Task Configs

## Automate Updating Pipelines
