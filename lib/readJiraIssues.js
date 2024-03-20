import axios from "axios";
import { writeFileSync } from "fs";

const issues = await jiraIssues(
  "project = ODATA AND status in (Open, Resolved, New, Applied) ORDER BY key ASC",
);

writeFileSync("./jiraIssues.json", JSON.stringify(issues, null, 2));

async function jiraIssues(jql) {
  const res = await axios.post(
    "https://issues.oasis-open.org/rest/api/2/search",
    {
      jql: jql,
      // fields: ["summary"],
      maxResults: 500,
    },
  );

  if (res.status != 200) console.dir(res);

  if (res.data.total > res.data.maxResults)
    console.log(
      `WARN: only ${res.data.maxResults} of ${res.data.total} issues retrieved`,
    );

  return res.data.issues;
}
