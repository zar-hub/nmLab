import os
import re
import argparse

def parse_ipf_functions(folder_path, output_file="functions.md"):
    # Regex pattern for function definitions
    func_pattern = re.compile(r"^\s*function(?:/\w+)?\s+(\w+)\s*\(([^)]*)\)", re.IGNORECASE)
    results = []

    # Walk through all files in the folder
    for root, _, files in os.walk(folder_path):
        for file in files:
            if file.endswith(".ipf"):
                file_path = os.path.join(root, file)
                print(f"Scanning: {file_path}")
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    lines = f.readlines()

                i = 0
                while i < len(lines):
                    match = func_pattern.match(lines[i])
                    if match:
                        func_name = match.group(1)
                        params = match.group(2).strip()
                        description_lines = []

                        # Collect consecutive comment lines after function
                        j = i + 1
                        while j < len(lines) and lines[j].strip().startswith("//"):
                            description_lines.append(lines[j].strip().lstrip("/ ").rstrip())
                            j += 1

                        description = " ".join(description_lines)
                        results.append({
                            "file": file,
                            "name": func_name,
                            "params": params,
                            "description": description
                        })
                        i = j
                    else:
                        i += 1

    # Sort results alphabetically by function name
    results.sort(key=lambda x: x["name"].lower())

    # Write Markdown table
    with open(output_file, "w", encoding="utf-8") as out:
        out.write("# 📘 Parsed IPF Functions\n\n")
        out.write("| Function Name | Parameters | Description | File |\n")
        out.write("|---------------|-------------|--------------|------|\n")

        for r in results:
            out.write(f"| `{r['name']}` | `{r['params']}` | {r['description']} | `{r['file']}` |\n")

    print(f"\n✅ Parsed {len(results)} functions.")
    print(f"📄 Markdown table saved to: {output_file}")

def main():
    parser = argparse.ArgumentParser(
        description="Parse .ipf files to extract functions, parameters, and descriptions into a Markdown table."
    )
    parser.add_argument(
        "-f", "--folder",
        help="Path to the folder containing .ipf files",
        type=str
    )
    parser.add_argument(
        "-o", "--output",
        help="Output Markdown file name (default: functions.md)",
        type=str,
        default="functions.md"
    )

    args = parser.parse_args()

    print("🧩 IPF Function Parser")
    print("=====================")

    folder_path = args.folder or input("Enter path to folder with .ipf files: ").strip()
    output_file = args.output or input("Enter output file name [functions.md]: ").strip() or "functions.md"

    if not os.path.exists(folder_path):
        print("❌ Error: Folder not found!")
        return

    print(f"\n📂 Searching in: {folder_path}")
    print(f"📝 Output file: {output_file}")
    print("\nParsing, please wait...\n")

    parse_ipf_functions(folder_path, output_file)

if __name__ == "__main__":
    main()
