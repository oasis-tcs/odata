import axios from "axios";
import { readFileSync, writeFileSync } from "fs";

const issueLists = JSON.parse(readFileSync("./lib/issueLists.json", "utf-8"));

const markdown = [
  "# OData Issues",
  "",
  `Generated ${new Date().toString()}`,
  "",
];

for (const list of issueLists) {
  markdown.push(
    `## ${list.topic}: [${
      list.name
    }](https://issues.oasis-open.org/issues/?jql=${encodeURIComponent(
      list.jql
    )})`,
    ""
  );
  const issues = await jiraIssues(list.jql);
  markdown.push(...issuesList(issues));
  markdown.push("");
}

writeFileSync("./issues.md", markdown.join("\n"));

async function jiraIssues(jql) {
  const res = await axios.post(
    "https://issues.oasis-open.org/rest/api/2/search",
    {
      jql: jql,
      fields: ["summary"],
      maxResults: 500,
    }
  );

  if (res.status != 200) console.dir(res);

  if (res.data.total > res.data.maxResults)
    console.log(
      `WARN: only ${res.data.maxResults} of ${res.data.total} issues retrieved`
    );

  return res.data.issues;
}

function issuesList(issues) {
  return issues.map(
    (issue, index) =>
      `${index + 1}. [${issue.key}](https://issues.oasis-open.org/browse/${
        issue.key
      }) ${issue.fields.summary}`
  );
}
