# Expression Tutor Activity generator Action

GitHub action that can generate Expression Tutor activities by
using Expression Service.

## Example

```yml
name: Expression Tutor Activity

on:
  push:
   tags:
     - '*'

permissions:
  issues: write

jobs:
  et_activity_generation:
    runs-on: ubuntu-latest
    name: Activity generation
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - name: Expression Tutor Activity generation
        uses: LuCEresearchlab/expression-tutor-activity-generator@v1.0.0
        id: exps
        with:
          query: '(/.*/ "(" [_ ","]* _ ")")'
          count: '1'
          srcDir: '.'
          activityGroup: 'my-activity-group'
          javaClassPath: '+libs'
          ghToken: ${{ secrets.GITHUB_TOKEN }}
```
