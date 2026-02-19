import json
import csv
import sys
from typing import Any, Dict

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

def json_to_csv(json_file: str, csv_file: str):
    with open(json_file, 'r') as f:
        data = json.load(f)

    if isinstance(data, dict):
        data = [data]

    flat_data = [flatten_json(item) for item in data]

    with open(csv_file, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=sorted({k for d in flat_data for k in d}))
        writer.writeheader()
        writer.writerows(flat_data)

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python script.py input.json output.csv")
        sys.exit(1)
    json_to_csv(sys.argv[1], sys.argv[2])
