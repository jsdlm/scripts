import requests
import csv
import time

def read_cve_list(filename):
    with open(filename, "r", encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip()]

def fetch_cve_data(cve_id, max_retries=10):
    url = f"https://services.nvd.nist.gov/rest/json/cves/2.0?cveId={cve_id}"
    default_sleep_duration = 3
    retries = 0

    while retries < max_retries:
        try:
            response = requests.get(url)
            if response.status_code == 429:
                sleep_duration = default_sleep_duration + retries
                print(f"Rate limited for {cve_id}. Waiting 3 seconds before retry...")
                time.sleep(default_sleep_duration + retries)
                retries += 1
                continue

            response.raise_for_status()
            data = response.json()
            vuln = data.get("vulnerabilities", [{}])[0].get("cve", {})
            metrics = vuln.get("metrics", {})

            # CVSS v3.1
            cvss31 = ""
            metric_31 = metrics.get("cvssMetricV31", [])
            if metric_31:
                cvss31 = str(metric_31[0].get("cvssData", {}).get("baseScore", ""))

            # CVSS v3.0
            cvss30 = ""
            metric_30 = metrics.get("cvssMetricV30", [])
            if metric_30:
                cvss30 = str(metric_30[0].get("cvssData", {}).get("baseScore", ""))

            # CVSS v2
            cvss2 = ""
            metric_v2 = metrics.get("cvssMetricV2", [])
            if metric_v2:
                cvss2 = str(metric_v2[0].get("cvssData", {}).get("baseScore", ""))

            # CWE
            cwe = ""
            for weakness in vuln.get("weaknesses", []):
                if weakness.get("type") == "Primary":
                    for desc in weakness.get("description", []):
                        if desc.get("lang") == "en":
                            cwe = desc.get("value", "")
                            break

            return {
                "CVEid": cve_id,
                "CVSSv3.1": cvss31,
                "CVSSv3.0": cvss30,
                "CVSSv2": cvss2,
                "CWE": cwe
            }

        except requests.exceptions.HTTPError as http_err:
            return {
                "CVEid": cve_id,
                "CVSSv3.1": f"HTTPError: {http_err}",
                "CVSSv3.0": f"HTTPError: {http_err}",
                "CVSSv2": f"HTTPError: {http_err}",
                "CWE": f"HTTPError: {http_err}"
            }
        except Exception as e:
            return {
                "CVEid": cve_id,
                "CVSSv3.1": str(e),
                "CVSSv3.0": str(e),
                "CVSSv2": str(e),
                "CWE": str(e)
            }

    return {
        "CVEid": cve_id,
        "CVSSv3.1": "ERROR",
        "CVSSv3.0": "ERROR",
        "CVSSv2": "ERROR",
        "CWE": "ERROR"
    }

def main():
    cve_ids = read_cve_list("CVE_list_unique.txt")
    output_file = "cve_results.csv"
    fieldnames = ["CVEid", "CVSSv3.1", "CVSSv3.0", "CVSSv2", "CWE"]

    with open(output_file, mode="w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()

    for cve_id in cve_ids:
        print(f"Processing {cve_id}...")
        result = fetch_cve_data(cve_id)
        print(result)

        with open(output_file, mode="a", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writerow(result)

        time.sleep(2)

    print(f"\nRésultats enregistrés dans {output_file}")

if __name__ == "__main__":
    main()
