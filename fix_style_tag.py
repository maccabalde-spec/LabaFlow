path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# The </style> is missing. Find where CSS ends and HTML begins.
# HTML starts at </div><!-- end #landing --> ... but wait, that's in the HTML body
# Actually the CSS block ends before the landing HTML div
# The <style> opened at char ~9347 (line 215)
# Find where the CSS block ends by finding the last CSS rule before the HTML

# Strategy: find "}\n\n\n" followed by "<!-- " or "<div" or "<script"
# which indicates end of CSS block

import re

style_open = content.find('<style>')
print(f"<style> at char {style_open}")

# Find where HTML tags begin after the style block
# Look for the first HTML comment or div that appears to be actual HTML content
# The landing page starts around line 1700+

# Find the pattern: a CSS closing brace followed by newlines then an HTML tag or comment
# Find last occurrence of "}\n\n" before the first "<div id="landing">" 
landing_start = content.find('<div id="landing">')
print(f"<div id=\"landing\"> at char {landing_start}")

# Find the end of CSS — look for the last } before landing
# Go backwards from landing_start to find the last }
last_brace = content.rfind('}', style_open, landing_start)
print(f"Last CSS brace at char {last_brace}")
print(f"Context: {repr(content[last_brace:last_brace+50])}")

# Insert </style> right after the last CSS brace, before the HTML
insert_pos = last_brace + 1
print(f"Will insert </style> at char {insert_pos}")
print(f"Content around insert: {repr(content[insert_pos-20:insert_pos+50])}")

# Do the insertion
content = content[:insert_pos] + '\n\n</style>\n\n' + content[insert_pos:]

# Verify
opens = content.count('<style')
closes = content.count('</style>')
print(f"\nAfter fix: style opens={opens}, closes={closes}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
