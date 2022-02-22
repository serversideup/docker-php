name: "\U0001F41B Bug Report"
description: "You found a bug in the code \U0001F914"
labels: ["Bug: Needs Confirmation 🧐"]
body:
- type: textarea
  attributes:
    label: Current Behavior
    description: A concise description of what you're experiencing.
  validations:
    required: true
- type: textarea
  attributes:
    label: Expected Behavior
    description: A concise description of what you expected to happen.
  validations:
    required: true
- type: textarea
  attributes:
    label: Steps To Reproduce
    description: Steps to reproduce the behavior.
    placeholder: |
      1. In this environment...
      2. With this config...
      3. Run '...'
      4. See error...
  validations:
    required: true
- type: textarea
  attributes:
    label: Docker Version
    description: |
      Run `docker version` and paste your output
    render: markdown
  validations:
    required: true
- type: textarea
  attributes:
    label: Anything else?
    description: |
      Links? References? Anything that will give us more context about the issue you are encountering!

      Tip: You can attach images or log files by clicking this area to highlight it and then dragging files in.
  validations:
    required: false