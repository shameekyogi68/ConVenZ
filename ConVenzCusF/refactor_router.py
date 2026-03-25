import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replacements
    # Navigator.pushReplacementNamed(context, '/route') -> context.go('/route')
    new_content = re.sub(r"Navigator\.pushReplacementNamed\(\s*context\s*,\s*('[^']+')\s*\)", r"context.go(\1)", content)
    
    # Navigator.pushNamed(context, '/route') -> context.push('/route')
    new_content = re.sub(r"Navigator\.pushNamed\(\s*context\s*,\s*('[^']+')\s*\)", r"context.push(\1)", new_content)
    
    # Navigator.pushNamedAndRemoveUntil(context, '/route', (route) => false) -> context.go('/route')
    new_content = re.sub(r"Navigator\.pushNamedAndRemoveUntil\(\s*context\s*,\s*('[^']+')\s*,\s*\([^)]*\)\s*=>\s*false\s*\)", r"context.go(\1)", new_content)

    # Navigator.pushNamed(context, '/route', arguments: args) -> context.push('/route', extra: args)
    new_content = re.sub(r"Navigator\.pushNamed\(\s*context\s*,\s*('[^']+')\s*,\s*arguments\s*:\s*([^)]+)\)", r"context.push(\1, extra: \2)", new_content)

    if new_content != content:
        # Add import if missing
        if "package:go_router/go_router.dart" not in new_content:
            new_content = "import 'package:go_router/go_router.dart';\n" + new_content
        
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            try:
                process_file(os.path.join(root, file))
            except Exception as e:
                print(f"Skipping {os.path.join(root, file)} due to {e}")
