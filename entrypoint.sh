#!/bin/bash
set -e

ARG_COUNT="$1"
ARG_SRC_DIR="$2"
ARG_JAVA_CLASSPATH="$3"
ARG_ACTIVITY_GROUP="$4"
ARG_GH_TOKEN="$5"

ET_URL="${ET_URL:=https://expressiontutor.org}"

WS_DIR="/github/workspace"
ES_INPUT_DIR="$WS_DIR/$ARG_SRC_DIR"
ES_JAVA_CLASSPATH="$WS_DIR/$ARG_JAVA_CLASSPATH"

OUT_DIR="$WS_DIR/output-exps"
GROUP_INFO_FILE="$OUT_DIR/group.json"
ES_OUT_FILE="$OUT_DIR/activities.ndjson"


# Move to the project directory so that path are properly relativized
cd /github/workspace

[ -d "$OUT_DIR" ] || mkdir "$OUT_DIR"

if [ -z "$ARG_ACTIVITY_GROUP" ]; then
  java -jar /opt/expression-service/app.jar source \
    --format=ACTIVITY \
    --count="$ARG_COUNT" \
    --java-classpath="$ES_JAVA_CLASSPATH" \
    "$ES_INPUT_DIR" > "$ES_OUT_FILE"
else
  curl -s -X GET "$ET_URL/api/activities/group/$ARG_ACTIVITY_GROUP" > "$GROUP_INFO_FILE"
  ETL_QUERY="$(cat "$GROUP_INFO_FILE" | jq '.query' | sed 's/\\"/"/g' | sed 's/^"//' | sed 's/"$//')"
  java -jar /opt/expression-service/app.jar source \
    --format=ACTIVITY \
    --count="$ARG_COUNT" \
    --query="$ETL_QUERY" \
    --java-classpath="$ES_JAVA_CLASSPATH" \
    "$ES_INPUT_DIR" > "$ES_OUT_FILE"
fi


if [ ! -r "$ES_OUT_FILE" ]; then
  echo "Error: \"$ES_OUT_FILE\" is not a readable file" 2>&1
  exit 2
fi

# Invoke the "lucky API" to generate an activity
CREATE_URL="${ET_URL}/api/activities/lucky?group=${ARG_ACTIVITY_GROUP}"
while read -r line; do
  CREATE_RES=$(curl -s -X POST "$CREATE_URL" -d "$line" -H "Content-Type: application/json")
  if [[ "$(echo "$CREATE_RES" | jq -r ".success")" == "true" ]]; then
    UUID=$(echo "$CREATE_RES" | jq -r ".uuid")

    EXPR_CODE=$(echo "$line" | jq -r ".code" | sed 's/"/\\"/g')
    LINE_NUMBER=$(echo "$line" | jq -r ".line")
    FILE_PATH=$(echo "$line" | jq -r ".path")

    GH_URL="https://github.com/${GITHUB_REPOSITORY}/blob/${GITHUB_SHA}/${FILE_PATH}#L${LINE_NUMBER}"
    ACTIVITY_URL="${ET_URL}/activity/do?task=${UUID}"

    # Create issue message
    ISSUE_BODY=$(cat<<EOB
In the file \`${FILE_PATH}\` in line ${LINE_NUMBER} you can find the following expression:
\`\`\`
$EXPR_CODE
\`\`\`

${GH_URL}

As we have seen in class, the structure of an expression forms a tree.
Please draw the structure of this expression using Expression Tutor by following
[this link](${ACTIVITY_URL}).

Once you are done, click the Save button and paste the link as a comment to this issue.
EOB
)

    ISSUE_BODY=$(echo "$ISSUE_BODY" | sed '$ ! s/$/\\n/' | tr -d '\n')
    ISSUE="{\"title\": \"Expression Tutor activity\", \"body\": \"$ISSUE_BODY\"}"
    echo "$ISSUE"

    if [ ! -z "$ARG_GH_TOKEN" ]; then
      # Create issue
      curl -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $ARG_GH_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.github.com/repos/$GITHUB_REPOSITORY/issues" \
        -d "$ISSUE"
    fi
  else
    echo "Activity creation failed for $line" 2>&1
  fi
done < "$ES_OUT_FILE"

