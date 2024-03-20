import axios from "axios";
import { readFileSync } from "node:fs";
import { env } from "node:process";

const REPO = "oasis-tcs/odata-specs";

const gitHubIssues = JSON.parse(readFileSync("./gitHubIssues.json", "utf-8"));
console.log(gitHubIssues.length, "issues to potentially write to", REPO);

const existingIssues = await readGithubIssues(REPO);
console.log(existingIssues.length, `existing issues in ${REPO}`);

const exists = {};
for (const issue of existingIssues) exists[issue.title] = true;

let newIssues = 0;
for (const issue of gitHubIssues) {
  if (exists[issue.title]) continue;

  const done = await createGithubIssue(REPO, issue);
  if (done) newIssues++;
  //TODO: add a delay to avoid rate limits
}
console.log(newIssues, "new issues written to", REPO);

async function readGithubIssues(repo) {
  const res = await axios.get(`https://api.github.com/repos/${repo}/issues`, {
    validateStatus: () => true,
  });
  if (res.status != 200)
    console.log("Could not read issues:", res.status, res.data);

  return res.data;
}

async function createGithubIssue(repo, issue) {
  // see https://docs.github.com/en/rest/issues/issues#create-an-issue

  const res = await axios.post(
    `https://api.github.com/repos/${repo}/issues`,
    issue,
    {
      headers: { Authorization: `Bearer ${env.GITHUB_TOKEN}` },
      validateStatus: () => true,
    },
  );

  if (res.status == 201) return true;
  console.log("Could not create issue:", issue.title);
  console.log(res.status, res.data);

  return false;
}
