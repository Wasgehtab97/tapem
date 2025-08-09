import argparse
import json
import os
import subprocess
import requests

API = "https://api.github.com"


def get_repo():
    repo = os.environ.get("GITHUB_REPOSITORY")
    if repo:
        return repo
    try:
        url = subprocess.check_output(["git", "config", "--get", "remote.origin.url"], text=True).strip()
    except subprocess.CalledProcessError:
        raise SystemExit("cannot determine repository; set GITHUB_REPOSITORY")
    if url.endswith(".git"):
        url = url[:-4]
    if url.startswith("git@github.com:"):
        return url[len("git@github.com:") :]
    if url.startswith("https://github.com/"):
        return url[len("https://github.com/") :]
    return url


def ensure_labels(session, repo, labels):
    existing = {l["name"] for l in session.get(f"{API}/repos/{repo}/labels").json()}
    for label in labels:
        if label["name"] not in existing:
            session.post(f"{API}/repos/{repo}/labels", json=label)


def ensure_milestone(session, repo, title):
    res = session.get(f"{API}/repos/{repo}/milestones", params={"state": "all"}).json()
    for m in res:
        if m["title"] == title:
            return m["number"]
    created = session.post(f"{API}/repos/{repo}/milestones", json={"title": title}).json()
    return created["number"]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--token", required=True)
    parser.add_argument("--manifest", default="project/roadmap/issues_pilot.json")
    args = parser.parse_args()

    repo = get_repo()
    session = requests.Session()
    session.headers["Authorization"] = f"token {args.token}"
    session.headers["Accept"] = "application/vnd.github+json"

    with open(".github/labels.json") as f:
        labels = json.load(f)
    ensure_labels(session, repo, labels)

    with open(args.manifest) as f:
        issues = json.load(f)["issues"]
    milestone_title = issues[0]["milestone"] if issues else ""
    milestone_number = ensure_milestone(session, repo, milestone_title)

    for issue in issues:
        payload = {
            "title": issue["title"],
            "body": issue.get("body", ""),
            "labels": issue.get("labels", []),
            "milestone": milestone_number,
        }
        session.post(f"{API}/repos/{repo}/issues", json=payload)


if __name__ == "__main__":
    main()
