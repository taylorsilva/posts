# Inputs & Outputs 101

Let's define some jargon first.

Each `step` (a container running code) in a Concourse job may have inputs
and/or outputs.

What is an `input`/`output`? To your tasks and resources, these are simply
directories that contain files.

To Concourse, these directories are volumes that get mounted inside a step's
container under some name. You, as a writer of Concourse pipelines, have
control over what this name will be.

Let's do some weird things with inputs and outputs to see how things work in
the real world.

## Example One - Two Tasks

This pipeline has two tasks. The first task outputs a file with the date. The
second task reads and prints the contents of the file.

```yaml
---
jobs:
  - name: a-job
    plan:
      - task: create-one-output
        config:
          platform: linux
          image_resource:
            type: registry-image
            source: {repository: alpine}
          outputs:
            - name: the-output
          run:
            path: /bin/sh
            args:
              - -cx
              - |
                ls -lah
                date > ./the-output/file
      - task: read-ouput-from-previous-step
        config:
          platform: linux
          image_resource:
            type: registry-image
            source: {repository: alpine}
          # you must explicitly name the inputs you expect this task to have
          # If you don't then outputs from previous steps will not appear
          # Try removing the inputs to see what happens!
          inputs:
            - name: the-output
          run:
            path: /bin/sh
            args:
              - -cx
              - |
                ls -lah
                cat ./the-output/file
```

## Example Two - Input/Output Name Mapping

Sometimes the names of inputs and outputs don't match. That's when
`input_mapping` and `out_mapping` become helpful. Both of these features map
the inputs/outputs in the task's config to some volume name in the build plan.

This pipeline has three tasks. The first task outputs a file with the date to
the `the-ouput` directory. `the-output` is mapped to the new name `demo-disk`.
The volume `demo-disk` is now available in the rest of the build plan for
future steps to consume.

The second task reads and prints the contents of the file under the new name
`demo-disk`.

The third task reads and prints the contents of the file under another name,
`generic-input`. The `demo-disk` volume in the buidl plan is mapped to
`generic-input`.

```yaml
---
jobs:
  - name: a-job
    plan:
      - task: create-one-output
        # The task config has the output `the-output`
        # this will rename `the-output` to `demo-disk` in the rest of the job's plan
        output_mapping:
          the-output: demo-disk
        config:
          platform: linux
          image_resource:
            type: registry-image
            source: {repository: busybox}
          outputs:
            - name: the-output
          run:
            path: /bin/sh
            args:
              - -cx
              - |
                ls -lah
                date > ./the-output/file
      - in_parallel:
        # this task expects the output `demo-disk` so no mapping is needed
        - task: read-ouput-from-previous-step
          config:
            platform: linux
            image_resource:
              type: registry-image
              source: {repository: busybox}
            inputs:
              - name: demo-disk
            run:
              path: /bin/sh
              args:
                - -cx
                - |
                  ls -lah
                  cat ./demo-disk/file
        - task: rename-and-read-output
          # This task expects the input `generic-input`
          # input_mapping will map the tasks `generic-input` to the job plans `demo-disk`
          input_mapping:
            generic-input: demo-disk
          config:
            platform: linux
            image_resource:
              type: registry-image
              source: {repository: busybox}
            inputs:
              - name: generic-input
            run:
              path: /bin/sh
              args:
                - -cx
                - |
                  ls -lah
                  cat ./generic-input/file
```

## Example 3 - Two tasks with the same output, who wins?

This example is to statisfy the curiousity in us all. Never do this in real
life because you're definitely going to hurt yourself!

There are two jobs in the pipeline. If you run the
`writing-to-the-same-output-in-parallel` pipeline multiple times you'll see the
file in the output folder changes depending on which of the parallel tasks
finish first.

For the serial job the second task always wins so only `file2` will be in
`the-output` folder.

This pipeline illustrates that you could accidently overwrite the output from a previous step if you're not careful with the names of your outputs.

```yaml
---
jobs:
  - name: writing-to-the-same-output-in-parallel
    plan:
      - in_parallel:
        - task: create-one-output
          config:
            platform: linux
            image_resource:
              type: registry-image
              source: {repository: busybox}
            outputs:
              - name: the-output
            run:
              path: /bin/sh
              args:
                - -cx
                - |
                  ls -lah
                  date > ./the-output/file1
        - task: create-another-output
          config:
            platform: linux
            image_resource:
              type: registry-image
              source: {repository: busybox}
            outputs:
              - name: the-output
            run:
              path: /bin/sh
              args:
                - -cx
                - |
                  ls -lah
                  date > ./the-output/file2
      - task: read-ouput-from-previous-step
        config:
          platform: linux
          image_resource:
            type: registry-image
            source: {repository: busybox}
          inputs:
            - name: the-output
          run:
            path: /bin/sh
            args:
              - -cx
              - |
                ls -lah ./the-output
                cat ./the-output/file1 ./the-output/file2

  - name: writing-to-the-same-output-serially
    plan:
      - task: create-one-output
        config:
          platform: linux
          image_resource:
            type: registry-image
            source: {repository: busybox}
          outputs:
            - name: the-output
          run:
            path: /bin/sh
            args:
              - -cx
              - |
                ls -lah
                date > ./the-output/file1
      - task: create-another-output
        config:
          platform: linux
          image_resource:
            type: registry-image
            source: {repository: busybox}
          outputs:
            - name: the-output
          run:
            path: /bin/sh
            args:
              - -cx
              - |
                ls -lah
                date > ./the-output/file2
      - task: read-ouput-from-previous-step
        config:
          platform: linux
          image_resource:
            type: registry-image
            source: {repository: busybox}
          inputs:
            - name: the-output
          run:
            path: /bin/sh
            args:
              - -cx
              - |
                ls -lah ./the-output
                cat ./the-output/file1 ./the-output/file2
```

## Example 4 - Can you add files to an existing output volume?

This pipeline will also have two jobs in order to illustrate this point.

```yaml

```
