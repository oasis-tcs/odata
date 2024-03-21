import { readFileSync } from "node:fs";
import { env } from "node:process";
import { Octokit, RequestError } from "octokit";

const REPO = "oasis-tcs/odata-specs";

const octokit = new Octokit({ auth: env.GITHUB_TOKEN });

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
}
console.log(newIssues, "new issues written to", REPO);

async function readGithubIssues(repo) {
  const data = await octokit.paginate(`GET /repos/${repo}/issues?state=all`, {
    per_page: 100,
  });

  return data.filter((issue) => !issue.pull_request);
}

async function createGithubIssue(repo, issue) {
  // see https://docs.github.com/en/rest/issues/issues#create-an-issue
  try {
    const response = await octokit.request(`POST /repos/${repo}/issues`, issue);

    if (issue.state === "closed") {
      await octokit.request(
        `PATCH /repos/${repo}/issues/${response.data.number}`,
        { state: issue.state, state_reason: issue.state_reason },
      );
    }
    return true;
  } catch (error) {
    if (error instanceof RequestError) {
      // handle Octokit errors
      console.error("Could not create issue:", issue.title);
      console.error(error.status, error.message);
      return false;
    } else {
      // handle all other errors
      throw error;
    }
  }
}
