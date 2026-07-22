import os
import re

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Find all "static Type *varName = " inside methods and change to "static Type *varName;"
    # Actually it's local statics inside methods causing the clang 10 cxa_guard injection on older armv7, even if it's just "static id _mod = nil;"
    
    # We will just rewrite the specific problematic ones to global file-scope statics
    pass

