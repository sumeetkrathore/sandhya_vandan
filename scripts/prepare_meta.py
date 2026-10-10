import json
import urllib.parse
import subprocess
import sys

def main():
    with open('web_reader_data.json', 'r', encoding='utf-8') as f:
        data = f.read()

    encoded_data = urllib.parse.quote(data)
    
    php_code = f"""
    $json = urldecode("{encoded_data}");
    update_post_meta(34220, 'publication_native_text', wp_slash($json));
    return "Successfully updated meta for post 34220!";
    """
    
    # We will just print the PHP code to a file so we can run it via MCP
    with open('update_meta.php', 'w', encoding='utf-8') as f:
        f.write(php_code)
    
    print("Generated update_meta.php")

if __name__ == '__main__':
    main()
