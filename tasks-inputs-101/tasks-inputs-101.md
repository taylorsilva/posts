# Tasks - Inputs & Outputs 101

Let's define some jargon first.

Each `step` (a container running code) in a Concourse job may have inputs and/or outputs.

What is an `input`/`output`? To your tasks and resources, these are simply directories that contain files.

To Concourse, these directories are volumes that get mounted inside a step's container under different names.

Let's do some weird things with inputs and outputs to see how things work in the real world.

## Example One - Two Tasks

Uncommon. Most jobs have at least one `get` step.

```yaml
# This pipeline has two tasks. The first task outputs a file with the date
# The second task reads and prints the contents of the file

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
the input/outputs in the task's config to some volume name in the build plan.

```yaml


```


