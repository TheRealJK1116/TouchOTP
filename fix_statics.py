import os
import re

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Find patterns like:
    # static Type *varName = nil;
    # static dispatch_once_t onceToken;
    # dispatch_once(&onceToken, ^{
    #   varName = ...;
    # });

    pattern = re.compile(r'static\s+(\w+ \*\w+)\s*=\s*nil;\s*static dispatch_once_t onceToken;\s*dispatch_once\(&onceToken,\s*\^\{', re.MULTILINE)
    
    def replacer(match):
        var_decl = match.group(1)
        var_name = var_decl.split('*')[1].strip()
        return f'static {var_decl} = nil;\n  if (!{var_name}) {{'

    content = pattern.sub(replacer, content)
    
    # We also need to replace the closing `});` with `}` but only where we modified.
    # A simple regex hack for these specific files:
    content = content.replace('  });', '  }')

    with open(filepath, 'w') as f:
        f.write(content)

files_to_fix = [
    'src/ZXingObjC/common/reedsolomon/ZXGenericGF.m',
    'src/ZXingObjC/oned/ZXUPCAWriter.m'
]

for f in files_to_fix:
    fix_file(f)

