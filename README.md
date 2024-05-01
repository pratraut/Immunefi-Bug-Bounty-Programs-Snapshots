# Immunefi Bug Bounty Programs Snapshots
Every time a Bug Bounty Program in Immunefi modifies its **policy**, **assets-in-scope**, or **bounties-table**, a bot will commit those changes to this repo.

To get a before/after diff of a project go to `./project/{project-name}.json` and check it's latest commit.
To get a before/after diff of a boost project go to `./boost_project/{project-name}.json` and check it's latest commit.

## If a program is removed from Immunefi, will it be removed from here as well?
No, the information and history of changes will stay here forever.

## Can I use this as a public API to get a list of programs and assets in scope?
Yes.

To get **a list of programs** call this endpoint:

> `https://raw.githubusercontent.com/pratraut/Immunefi-Bug-Bounty-Programs-Snapshots/main/projects.json`
> `https://raw.githubusercontent.com/pratraut/Immunefi-Bug-Bounty-Programs-Snapshots/main/boost_projects.json`

For example, open your console and type:
```
wget -qO- https://raw.githubusercontent.com/pratraut/Immunefi-Bug-Bounty-Programs-Snapshots/main/projects.json
wget -qO- https://raw.githubusercontent.com/pratraut/Immunefi-Bug-Bounty-Programs-Snapshots/main/boost_projects.json
```

To get a list of **assets in scope** and **program details** call this endpoint (replacing {PROJECT_ID} with the project's id):

> `https://raw.githubusercontent.com/pratraut/Immunefi-Bug-Bounty-Programs-Snapshots/main/project/{PROJECT_ID}.json`
> `https://raw.githubusercontent.com/pratraut/Immunefi-Bug-Bounty-Programs-Snapshots/main/boost_project/{PROJECT_ID}.json`

For example, open your console and type:
```
wget -qO- https://raw.githubusercontent.com/pratraut/Immunefi-Bug-Bounty-Programs-Snapshots/main/project/2pi.json
```
