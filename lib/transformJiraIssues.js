import { readFileSync, writeFileSync } from "fs";

const jiraIssues = JSON.parse(readFileSync("./jiraIssues.json", "utf-8"));

console.log(jiraIssues.length, "issues");

const ASSIGNEE = {
  "chrispre@microsoft.com": "chrisspre",
  "George.Ericson@Dell.com": "GEricson",
  "Heiko.Theissen@sap.com": "HeikoTheissen",
  "hubert.heijkers@nl.ibm.com": "Hubert-Heijkers",
  "jinling@ca.ibm.com": "Hubert-Heijkers", //TODO: add to repo
  "martin.zurmuehl@sap.com": "zurmuehl",
  "mikep@microsoft.com": "mikepizzo",
  "ralf.handl@sap.com": "ralfhandl",
  "stefan@drees.name ": "sthagen",
};

const gitHubIssues = [];

for (const j of jiraIssues) {
  const g = {
    title: j.fields.summary,
    body: j.fields.description,
    labels: [],
    assignees: [],
  };

  // - labels from components[*].name only if repo === odata-specs
  for (const component of j.fields.components) {
    g.labels.push(component.name);
  }

  if (j.fields.assignee) {
    const email = j.fields.assignee.emailAddress;
    g.assignees.push(ASSIGNEE[email] || email);
    if (!ASSIGNEE[email]) {
      console.log("Unknown assignee", email);
    }
  }

  //TODO:
  // - repo from components[*].name: Vocabularies -> odata-vocabularies, ABNF -> odata-abnf, other -> odata-specs
  // - labels from fixVersions[*].name
  // - proposal (customfield_10001): append to body with headline
  // - resolution (customfield_10002): ???
  // - tweak description and proposal to translate Jira/wiki markup into GitHub markdown?

  gitHubIssues.push(g);
}

writeFileSync("./gitHubIssues.json", JSON.stringify(gitHubIssues, null, 2));
