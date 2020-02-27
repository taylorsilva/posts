# How To Organize Your Pipeline, Task, And Other CI Files

There are many different ways to organize and store your CI/CD files. 

In general everyone agrees that these files should live in a
[VCS](https://en.wikipedia.org/wiki/Version_control) like
[git](https://en.wikipedia.org/wiki/Git) so the following strategies build from
that assumption. There is no wrong strategy
to go with, everyone needs to figure out which strategy works for their team
and their workflows.

In this blog post we are going to cover:

1. Places to store your CI/CD files 
2. How to organize your CI/CD files once you've settled on a place to store
   them

## Where To Store Your CI/CD Files

### In A CI Folder

You have all the code for your project in one repository and you simply make a
folder called `ci` at the root of your repository.

```
./
├── ci/
├── mycode/
├── vendor/
├── docker-compose.yaml
└── README.md
```

It's easy to start with this strategy and works well for smaller teams and projects.

### In A Different Repository From Your Application

Once a team or project gets large enough we usually see them migrate from the
previous location (a folder in the same repo as the code) to putting all of
their CI/CD files in a different repo. The Concourse team does this, you can
see our CI repo here: github.com/concourse/ci/

There are many reasons why teams eventually switch to this strategy. It usually
stems from too many CI/CD related commits being made in the same repo as
application code and the limits this places on a team to iterate on their teams
workflows. Placing CI/CD files in a place separate from the application code
allows a team to easily iterate on the workflows that surround their code,
which is a very different problem space from the one application code is trying
to solve.

## How To Organize Your CI/CD Files

Regardless of which of the above locations you choose here is the basic directory structure that we see teams use. You can think of this as a base structure that you can mold to meet your needs.

```
ci/
├── dockerfiles/
│   ├── imageOne
│   │   └── Dockerfile
│   └── imageOne
│       └── Dockerfile
├── pipelines/
│   ├── pipelineOne.yml
│   └── pipelineTwo.yml
├── tasks/
│   ├── taskOne.yml
│   ├── taskTwo.yml
│   └── scripts/
│       ├── taskOne.sh
│       └── taskTwo.sh
```

TODO: describe each folder

### dockerfiles/
This directory contains the dockerfiles for the images used by the tasks in
this repository. For example, in the Concourse team's main pipeline most tasks
run using the unit image. A dockerfile that does not go in this folder would be
the one's that ship your software. The Concourse team has a separate repository
for managing the dockerfile: https://github.com/concourse/concourse-docker

### pipelines/


### tasks/

TODO: show variation of having tasks & scripts in a sub-folder
