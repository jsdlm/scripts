import sys

def parse_projects(file_path):
    """
    Lit le fichier texte et crée un dictionnaire regroupant les projets et leurs environnements.
    """
    projects = {}
    valid_envs = {"dv", "qa", "np", "pd"}  # Ensemble des environnements valides

    list_file = open(file_path, 'r')

    for line in list_file:
        line = line.strip()

        if "-" not in line:
            # Nom complet sans séparateur "-"
            if line not in projects:
                projects[line] = []
            continue

        project_name, env = line.rsplit("-", 1)

        if env not in valid_envs:
            # Nom complet sans environnement valide
            if line not in projects:
                projects[line] = []
            continue

        if project_name not in projects:
            projects[project_name] = []
        if env not in projects[project_name]:
            projects[project_name].append(env)

    return projects

def write_csv(projects_dict, output_csv):
    """
    Écrit un fichier CSV sans utiliser de bibliothèque externe.
    """
    headers = ["project", "dv", "qa", "np", "pd"]
    with open(output_csv, 'w') as csvfile:
        # Écrire l'en-tête
        csvfile.write(",".join(headers) + "\n")
        
        # Écrire les lignes des projets
        for project, envs in projects_dict.items():
            row = [project]
            for env in ["dv", "qa", "np", "pd"]:
                row.append("X" if env in envs else "")
            csvfile.write(",".join(row) + "\n")

def main(input_file, output_file):
    projects_dict = parse_projects(input_file)
    write_csv(projects_dict, output_file)
    print(f"CSV file generated: {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <input_file> <output_csv>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    main(input_file, output_file)
