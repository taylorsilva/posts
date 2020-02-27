# How To Automatically Set Pipelines

In this blog post we're going to cover how to use Concourse to automatically
set and update your pipelines using the new
[`set_pipeline`](https://concourse-ci.org/set-pipeline-step.html) step. No
longer will you need to do `fly set-pipeline` for every one of your pipelines.
One caveat with this setup is that this will not dynamically find and
set/update pipelines.

The reference pipeline for this blog post is our team's [reconfigure
pipeline](https://github.com/concourse/ci/blob/80a979a7f39aac04b457c29af73ad8eb53d48087/pipelines/reconfigure.yml)
