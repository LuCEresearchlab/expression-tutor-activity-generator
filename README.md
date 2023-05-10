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
  contents: read

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
          count: '1'
          srcDir: '.'
          activityGroup: 'my-activity-group-uuid'
          javaClassPath: '+libs'
          ghToken: ${{ secrets.GITHUB_TOKEN }}
```

## Development

### Test locally

Build a docker image

```bash
docker build -t "expression-tutor-activity-generator" .
```

Run the activity generation with the live instance of ExpressionTutor

```bash
docker run \
  -e "GITHUB_REPOSITORY=foo/bar" \
  -e "GITHUB_SHA=main" \
  -v$(pwd):/github/workspace \
  expression-tutor-activity-generator \
  "$COUNT" "$SRC_DIR" "$EXTRA_JAVA_CP" "$GROUP_UUID"
```

Run the activity generation with a local instance of ExpressionTutor

```bash
docker run \
  -e "GITHUB_REPOSITORY=foo/bar" \
  -e "GITHUB_SHA=main" \
  -e "ET_URL=http://localhost:3000" \
  -v$(pwd):/github/workspace \
  --net=host \
  expression-tutor-activity-generator \
  "$COUNT" "$SRC_DIR" $EXTRA_JAVA_CP" "$GROUP_UUID"
```
