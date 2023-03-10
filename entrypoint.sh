#!/bin/bash
set -e

ARG_QUERY="$1"
ARG_COUNT="$2"
ARG_SRC_DIR="$3"
ARG_JAVA_CLASSPATH="$4"
ARG_ACTIVITY_GROUP="$5"
ARG_GH_TOKEN="$6"

WS_DIR="/github/workspace"
ES_INPUT_DIR="$WS_DIR/$ARG_SRC_DIR"
ES_JAVA_CLASSPATH="$WS_DIR/$ARG_JAVA_CLASSPATH"

OUT_DIR="$WS_DIR/output-exps"
ES_OUT_FILE="$OUT_DIR/activities.ndjson"


# Move to the project directory so that path are properly relativized
cd /github/workspace

[ -d "$OUT_DIR" ] || mkdir "$OUT_DIR"

java -jar /opt/expression-service/app.jar source \
  --format=ACTIVITY \
  --count="$ARG_COUNT" \
  --query="$ARG_QUERY" \
  --java-classpath="$ES_JAVA_CLASSPATH" \
  "$ES_INPUT_DIR" > "$ES_OUT_FILE"

function create_activity {
  instance_url="https://expressiontutor.org"
  activities_file=$1
  activity_group=$2

  if [ ! -r "$activities_file" ]; then
    echo "Error: \"$activities_file\" is not a readable file" 2>&1
    exit 2
  fi

  # Invoke the "lucky API" to generate an activity
  url="${instance_url}/api/activities/lucky?group=${activity_group}"
  while read -r line; do
    result=$(curl -s -X POST "$url" -d "$line" -H "Content-Type: application/json")
    success=$(echo "$result" | jq -r ".success")
    if [[ "$success" == "true" ]]; then
      uuid=$(echo "$result" | jq -r ".uuid")

      expression_code=$(echo "$line" | jq -r ".code" | sed 's/"/\\"/g')
      line_number=$(echo "$line" | jq -r ".line")
      file_path=$(echo "$line" | jq -r ".path")

      gh_url="https://github.com/${GITHUB_REPOSITORY}/blob/${GITHUB_SHA}/${file_path}#L${line_number}"
      et_url="${instance_url}/activity/do?task=${uuid}"

      # Create issue message
      issue_body=$(cat<<EOB
In the file \`${file_path}\` in line ${line_number} you can find the following expression:
\`\`\`
$expression_code
\`\`\`

${gh_url}

As we have seen in class, the structure of an expression forms a tree.
Please draw the structure of this expression using Expression Tutor by following
[this link](${et_url}).

Once you are done, click the Save button and paste the link as a comment to this issue.
EOB
)

      issue_body=$(echo "$issue_body" | sed '$ ! s/$/\\n/' | tr -d '\n')
      issue="{\"title\": \"Expression Tutor activity\", \"body\": \"$issue_body\"}"
      echo "$issue"

      # Create issue
      curl -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $ARG_GH_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.github.com/repos/$GITHUB_REPOSITORY/issues" \
        -d "$issue"
    else
      echo "Activity creation failed for $line" 2>&1
    fi
  done < "$activities_file"
}

create_activity "$ES_OUT_FILE" "$ARG_ACTIVITY_GROUP"

