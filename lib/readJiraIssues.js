import axios from "axios";
import { writeFileSync } from "node:fs";
import { parseArgs } from "node:util";

const args = parseArgs({ allowPositionals: true });
const start = args.positionals[0] || 0;

const issues = await jiraIssues(
  "project = ODATA AND status in (Closed) ORDER BY key DESC",
);

writeFileSync("./jiraIssues.json", JSON.stringify(issues, null, 2));

async function jiraIssues(jql) {
  const res = await axios.post(
    "https://issues.oasis-open.org/rest/api/2/search",
    {
      jql: jql,
      maxResults: 100,
      startAt: start,
    },
  );

  if (res.status != 200) console.dir(res);

  if (res.data.total > res.data.maxResults)
    console.log(
      `WARN: only ${res.data.maxResults} of ${res.data.total} issues retrieved, starting at ${res.data.startAt}`,
    );

  return res.data.issues;
}
