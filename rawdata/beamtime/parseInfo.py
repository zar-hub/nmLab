import os
import re
import csv

def extract_from_folders(folder_list, csv_output_path):
    results = []

    for folder in folder_list:
        for filename in os.listdir(folder):

            # ✔ Only parse files ending with _summary.txt
            if not filename.lower().endswith("_summary.txt"):
                continue

            file_path = os.path.join(folder, filename)

            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()

            # Split text into blocks beginning with "File:"
            blocks = re.split(r"(?=File:\s*)", content)[1:]

            for block in blocks:
                # Extract the file header name
                m_file = re.search(r"File:\s*([A-Za-z0-9_]+)", block)
                if not m_file:
                    continue
                file_name = m_file.group(1)

                # Extract values
                excitation_energy = re.search(r"Excitation energy:\s*([\d.]+)\s*eV", block)
                pe = re.search(r"P\.E\.\s*=\s*([\d.]+)\s*eV", block)
                dwell = re.search(r"Dwell Time\s*=\s*([\d.]+)s", block)
                scans = re.search(r"Scans\s*=\s*(\d+)", block)

                results.append({
                    #"Folder": os.path.basename(folder),
                    #Source_File": filename,
                    "File_Block": file_name,
                    "Excitation_Energy_eV": excitation_energy.group(1) if excitation_energy else "",
                    "PE_eV": pe.group(1) if pe else "",
                    "Dwell_Time_s": dwell.group(1) if dwell else "",
                    "Scans": scans.group(1) if scans else ""
                })

    # Write to CSV
    with open(csv_output_path, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=[
            #"Folder",
            #"Source_File",
            "File_Block",
            "Excitation_Energy_eV",
            "PE_eV",
            "Dwell_Time_s",
            "Scans"
        ])
        writer.writeheader()
        writer.writerows(results)

    print(f"CSV successfully created: {csv_output_path}")


# ----------------------------
# Example Usage
# ----------------------------

folders = [
    r"250523",
    r"250524",
    r"250525"
]

csv_output = "BeamtimeSummary.csv"
extract_from_folders(folders, csv_output)
