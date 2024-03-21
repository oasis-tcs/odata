import { readFileSync, writeFileSync } from "fs";

const jiraIssues = JSON.parse(readFileSync("./jiraIssues.json", "utf-8"));

console.log(jiraIssues.length, "issues");

const ASSIGNEE = {
  "chrispre@microsoft.com": "chrisspre",
  "George.Ericson@Dell.com": "GEricson",
  "Heiko.Theissen@sap.com": "HeikoTheissen",
  "hubert.heijkers@nl.ibm.com": "Hubert-Heijkers",
  "jinling@ca.ibm.com": "Hubert-Heijkers", //TODO: add to odata-specs repository
  "martin.zurmuehl@sap.com": "zurmuehl",
  "mikep@microsoft.com": "mikepizzo",
  "ralf.handl@sap.com": "ralfhandl",
  "stefan@drees.name ": "sthagen",
};

const gitHubIssues = [];

const resolution = {};

for (const j of jiraIssues) {
  const g = {
    title: j.fields.summary,
    body: reformat(j.fields.description),
    labels: [],
    assignees: [],
  };

  for (const component of j.fields.components) {
    g.labels.push(component.name);
  }

  for (const version of j.fields.fixVersions) {
    g.labels.push(version.name);
  }

  if (["Resolved", "Applied"].includes(j.fields.status.name))
    g.labels.push(j.fields.status.name);

  if (j.fields.status.name === "Deferred") {
    g.state = "closed";
    g.state_reason = "not_planned";
    g.labels.push("wontDo");
  } else if (j.fields.status.name === "Closed") {
    g.state = "closed";
    //TODO:
    // - label and state_reason depending on resolution.name
    if (j.fields.resolution) resolution[j.fields.resolution.name] = true;
    // g.state_reason = "not_planned";
    // g.labels.push("wontDo");
  }

  if (
    j.fields.assignee &&
    !["Deferred", "Closed"].includes(j.fields.status.name)
  ) {
    const email = j.fields.assignee.emailAddress;
    g.assignees.push(ASSIGNEE[email] || email);
    if (!ASSIGNEE[email]) {
      console.log("Unknown assignee", email);
    }
  }

  if (j.fields.customfield_10001) {
    g.body += `\n\n### Proposal\n\n${reformat(j.fields.customfield_10001)}`;
  }

  g.body += `\n\nImported from [${j.key}](https://issues.oasis-open.org/browse/${j.key})`;

  gitHubIssues.push(g);
}

writeFileSync("./gitHubIssues.json", JSON.stringify(gitHubIssues, null, 2));

//TODO: remove once all resolution names are known
console.log("Resolution names", resolution);

function reformat(jiraText) {
  if (jiraText == null) return "";
  return jiraText
    .replace(/ /g, " ") // non-breaking space
    .replace(/\r\n/g, "\n") // Windows line endings
    .replace(/\n *\* /g, "\n- ") // bullet list item
    .replace(/\n *\*\* /g, "\n  - ") // bullet list item, second level
    .replace(/\n *# /g, "\n1. ") // numbered list item
    .replace(/\n *## /g, "\n   1. ") // numbered list item, second level
    .replace(/{{([^}]+)}}/g, "`$1`") // monospace
    .replace(/\s-(?=\w)(.+?(?=-\s))-\s/g, " <del>$1</del> ") // deleted text
    .replace(/\s\+(?=\w)(.+?(?=\+\s))\+\s/g, " <ins>$1</ins> ") // added text
    .replace(/{code:([a-z]+)}/g, "```$1") // code block start with language
    .replace(/{code}/g, "```") // code block end (or start without language)
    .replace(/{quote}(.+?){quote}/gs, blockQuote) // block quotes
    .replace(/(ODATA-[0-9]+)/g, "[$1](https://issues.oasis-open.org/browse/$1)") // implicit Jira issue links
    .replace(/\[([^\|]+)\|([^\]]+)\]/g, "[$1]($2)"); // external links
}

function blockQuote(text) {
  const quotedText = text.substring(7, text.length - 7);
  return "> " + quotedText.replace(/\n/g, "\n> ") + "\n";
}
