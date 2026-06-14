#!/usr/bin/env python3
import sys
import xml.etree.ElementTree as ET

def parse(path):
    hosts = {}
    try:
        root = ET.parse(path).getroot()
    except Exception:
        return hosts
    for host in root.findall("host"):
        addr = host.find("address")
        if addr is None:
            continue
        ip = addr.get("addr")
        ports = hosts.setdefault(ip, [])
        for port in host.findall(".//port"):
            state = port.find("state")
            if state is not None and state.get("state") == "open":
                svc = port.find("service")
                name = svc.get("name") if svc is not None else ""
                ports.append((port.get("portid"), port.get("protocol").upper(), name))
    return hosts

tcp_hosts = parse(sys.argv[1])
udp_hosts = parse(sys.argv[2]) if len(sys.argv) > 2 else {}

all_ips = list(tcp_hosts.keys())
for ip in udp_hosts:
    if ip not in all_ips:
        all_ips.append(ip)

print("| IP Address | Port | Proto | Service |")
print("| ------- | ------- | ------- | ------- |")
for ip in all_ips:
    for p, proto, name in tcp_hosts.get(ip, []) + udp_hosts.get(ip, []):
        print(f"| {ip} | {p} | {proto} | {name} |")
