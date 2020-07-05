# How To Automatically Set Pipelines

In this blog post we're going to cover how to use Concourse to automatically set and update your pipelines using the [`set_pipeline`](https://concourse-ci.org/set-pipeline-step.html) step. No longer will you need to use [`fly set-pipeline`]() for every one of your pipelines!

For consistency we will refer to the pipeline that contains all the [`set_pipeline`]() steps as the **reconfigure-pipeline**. The child pipelines will be called **pipelines**.

_Scroll to the bottom to see the final pipeline or [click here](). What follows is a detailed explanation of how the pipeline works._
