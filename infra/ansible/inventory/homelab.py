#!/usr/bin/env python3
"""Build the Ansible inventory directly from config/homelab.yaml."""

from __future__ import annotations

import json
import os
from pathlib import Path
import sys

import yaml


CONFIG_PATH = Path(__file__).resolve().parents[3] / "config" / "homelab.yaml"


def build_inventory() -> dict[str, object]:
    with CONFIG_PATH.open(encoding="utf-8") as config_file:
        config = yaml.safe_load(config_file)

    nodes = config["spec"]["network"]["nodes"]
    if len(nodes) != 3:
        raise ValueError("config/homelab.yaml must define exactly three nodes")

    hostvars = {
        node["name"]: {
            "ansible_host": node["address"],
            "ansible_user": os.environ.get("HOMELAB_ANSIBLE_USER", "ansible"),
            "homelab_node_interface": node["interface"],
        }
        for node in nodes
    }
    names = [node["name"] for node in nodes]

    return {
        "_meta": {"hostvars": hostvars},
        "all": {"children": ["k3s_cluster"]},
        "k3s_cluster": {"children": ["initial_server", "joining_servers"]},
        "initial_server": {"hosts": names[:1]},
        "joining_servers": {"hosts": names[1:]},
    }


def main() -> None:
    inventory = build_inventory()
    if len(sys.argv) == 3 and sys.argv[1] == "--host":
        print(json.dumps(inventory["_meta"]["hostvars"].get(sys.argv[2], {})))
        return
    print(json.dumps(inventory))


if __name__ == "__main__":
    main()
