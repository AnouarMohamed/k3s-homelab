#!/usr/bin/env python3
"""Build a temporary EC2 inventory from OpenTofu outputs without exposing public IPs."""

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

import yaml


REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
CONFIG_PATH = REPOSITORY_ROOT / "config" / "homelab.yaml"
TOFU_ROOT = REPOSITORY_ROOT / "infra" / "tofu" / "aws-validation"


def checked_environment_value(name: str, default: str, pattern: str) -> str:
    value = os.environ.get(name, default)
    if not re.fullmatch(pattern, value):
        raise ValueError(f"{name} contains unsupported characters")
    return value


def tofu_outputs() -> dict[str, object]:
    tofu = shutil.which("tofu") or str(REPOSITORY_ROOT / ".tools" / "bin" / "tofu")
    result = subprocess.run(
        [tofu, f"-chdir={TOFU_ROOT}", "output", "-json"],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def build_inventory() -> dict[str, object]:
    with CONFIG_PATH.open(encoding="utf-8") as config_file:
        config = yaml.safe_load(config_file)

    outputs = tofu_outputs()
    instance_ids = outputs["instance_ids"]["value"]
    endpoint = outputs["control_plane_endpoint"]["value"]
    backup_bucket = outputs["backup_bucket"]["value"]
    backup_endpoint = outputs["backup_endpoint"]["value"]
    nodes = config["spec"]["network"]["nodes"]
    if set(instance_ids) != {node["name"] for node in nodes}:
        raise ValueError("OpenTofu instance outputs do not match the three configured nodes")

    profile = checked_environment_value("AWS_PROFILE", "homelab-aws", r"[A-Za-z0-9_.-]+")
    region = checked_environment_value("AWS_REGION", "eu-west-1", r"[a-z]{2}-[a-z]+-[0-9]")
    aws = shutil.which("aws")
    if not aws:
        raise RuntimeError("aws CLI is required for the Systems Manager SSH tunnel")
    private_key = os.environ.get(
        "AWS_VALIDATION_SSH_PRIVATE_KEY_FILE",
        str(REPOSITORY_ROOT / ".runtime" / "aws-validation" / "id_ed25519"),
    )
    known_hosts = REPOSITORY_ROOT / ".runtime" / "aws-validation" / "known_hosts"
    proxy_command = (
        f"ProxyCommand={aws} ssm start-session --profile {profile} --region {region} "
        "--target %h --document-name AWS-StartSSHSession --parameters portNumber=%p"
    )

    hostvars = {
        node["name"]: {
            "ansible_host": instance_ids[node["name"]],
            "ansible_user": "ubuntu",
            "ansible_ssh_common_args": (
                f"-o {proxy_command} -o StrictHostKeyChecking=accept-new "
                f"-o UserKnownHostsFile={known_hosts}"
            ),
            "ansible_ssh_private_key_file": private_key,
            "homelab_control_plane_endpoint": endpoint,
            "homelab_enable_kube_vip": False,
            "homelab_node_address": node["address"],
            "homelab_node_interface": "ens5",
            "homelab_s3_bucket": backup_bucket,
            "homelab_s3_endpoint": backup_endpoint,
            "homelab_s3_region": region,
            "homelab_use_instance_role_for_s3": True,
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
