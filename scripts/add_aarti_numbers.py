import json

def update_aarti_numbers():
    with open('assets/data/pustak_data.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    for page in data['pages']:
        # Baba Roop Bhajan Aarti Stanzas
        if page['assetPage'] == 45:
            if not page['digitalText'].startswith('1.'):
                page['digitalText'] = '1. ' + page['digitalText']
        elif page['assetPage'] == 46:
            if not page['digitalText'].startswith('2.'):
                page['digitalText'] = '2. ' + page['digitalText']
        elif page['assetPage'] == 47:
            if not page['digitalText'].startswith('3.'):
                page['digitalText'] = '3. ' + page['digitalText']
        elif page['assetPage'] == 48:
            if not page['digitalText'].startswith('4.'):
                page['digitalText'] = '4. ' + page['digitalText']
        elif page['assetPage'] == 49:
            if not page['digitalText'].startswith('5.'):
                page['digitalText'] = '5. ' + page['digitalText']
                
        # Baba Shiv Bhajan Aarti Stanzas
        elif page['assetPage'] == 51:
            if not page['digitalText'].startswith('1.'):
                page['digitalText'] = '1. ' + page['digitalText']
        elif page['assetPage'] == 52:
            if not page['digitalText'].startswith('2.'):
                page['digitalText'] = '2. ' + page['digitalText']
        elif page['assetPage'] == 53:
            if not page['digitalText'].startswith('3.'):
                page['digitalText'] = '3. ' + page['digitalText']
        elif page['assetPage'] == 54:
            if not page['digitalText'].startswith('4.'):
                page['digitalText'] = '4. ' + page['digitalText']

    with open('assets/data/pustak_data.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

if __name__ == '__main__':
    update_aarti_numbers()
    print("Numbers added to Aarti stanzas in pustak_data.json")
