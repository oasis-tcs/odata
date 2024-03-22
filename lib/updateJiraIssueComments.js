import axios from "axios";
import { readFileSync, writeFileSync } from "node:fs";
import { env } from "node:process";
import { Octokit, RequestError } from "octokit";

const REPO = "oasis-tcs/odata-specs";

const octokit = new Octokit({ auth: env.GITHUB_TOKEN });

const githubIssues = await readGithubIssues(REPO);
// writeFileSync("./githubIssues.json", JSON.stringify(githubIssues, null, 2));
// const githubIssues = JSON.parse(readFileSync("./githubIssues.json", "utf-8"));
console.log(githubIssues.length, `issues in ${REPO}`);

for (const issue of githubIssues) {
  const [, jiraKey] =
    issue.body.match(/\nImported from \[(ODATA-[0-9]+)\]/) || [];
  if (!jiraKey) continue;
  const comments = await readJiraIssueComments(jiraKey);

  for (const comment of comments) {
    if (
      comment.body ===
      "Cloned to https://github.com/oasis-tcs/odata-specs/issues"
    ) {
      await updateJiraIssueComment(comment.self, `Cloned to ${issue.html_url}`);
      console.log(jiraKey, issue.html_url);
      // process.exit(0);
    }
  }
}

async function readGithubIssues(repo) {
  const data = await octokit.paginate(`GET /repos/${repo}/issues?state=open`, {
    per_page: 100,
  });

  return data.filter((issue) => !issue.pull_request);
}

async function readJiraIssueComments(key) {
  const res = await axios.get(
    `https://issues.oasis-open.org/rest/api/2/issue/${key}/comment`,
  );

  if (res.status != 200) console.dir(res);

  return res.data.comments;
}

async function updateJiraIssueComment(url, body) {
  const res = await axios.put(
    url,
    { body },
    {
      auth: {
        username: "ralfhandl",
        password: "Want2Stand",
      },
    },
  );

  if (res.status != 200) console.dir(res);
}
