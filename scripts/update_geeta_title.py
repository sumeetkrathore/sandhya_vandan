import json

def update_geeta_title():
    title = "گــــيتا جو سار\n\n"
    
    with open('assets/data/pustak_data.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    for page in data['pages']:
        if page['assetPage'] == 68:
            current_text = page.get('digitalText', '')
            if not current_text.startswith("گــــيتا"):
                page['digitalText'] = title + current_text
                print("Title prepended successfully.")
            else:
                print("Title already exists.")
            break
            
    with open('assets/data/pustak_data.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

if __name__ == '__main__':
    update_geeta_title()
