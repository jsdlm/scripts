#!/usr/bin/env python3

import json
import csv
import sys
import os
from typing import Any, Dict, List

def flatten_json(y: Dict[str, Any], prefix: str = '', sep: str = '_') -> Dict[str, Any]:
    out = {}
    def flatten(x, name=''):
        if isinstance(x, dict):
            for a in x:
                flatten(x[a], f'{name}{a}{sep}')
        elif isinstance(x, list):
            for i, a in enumerate(x):
                flatten(a, f'{name}{i}{sep}')
        else:
            out[name[:-1]] = x
    flatten(y, prefix)
    return out

def folder_json_to_csv(input_dir: str, output_csv: str):
    all_rows: List[Dict[str, Any]] = []

    for filename in os.listdir(input_dir):
        if filename.endswith(".json"):
            filepath = os.path.join(input_dir, filename)

            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    data = json.load(f)

                if isinstance(data, list):
                    datasets = data
                else:
                    datasets = [data]

                for ds in datasets:
                    base = ds.copy()
                    access_list = base.pop("access", [])

                    base_flat = flatten_json(base)

                    if isinstance(access_list, list) and access_list:
                        for access in access_list:
                            row = base_flat.copy()
                            row.update(flatten_json(access, prefix="access_"))
                            row["_source_file"] = filename
                            all_rows.append(row)
                    else:
                        row = base_flat.copy()
                        row["_source_file"] = filename
                        all_rows.append(row)

            except Exception as e:
                print(f"Erreur avec {filename}: {e}")

    if not all_rows:
        print("Aucune donnée à écrire.")
        return

    fieldnames = sorted({k for d in all_rows for k in d})

    with open(output_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_rows)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <dossier_json> <output_csv>")
        sys.exit(1)

    input_dir = sys.argv[1]
    output_csv = sys.argv[2]

    if not os.path.isdir(input_dir):
        print(f"Le dossier {input_dir} n'existe pas.")
        sys.exit(1)

    folder_json_to_csv(input_dir, output_csv)
