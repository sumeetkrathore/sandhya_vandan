import json

def inject_geeta():
    geeta_text = """جيڪو ٿيو سُٺو ٿِيو
جو ٿي رھيو آھي، اُھو سُٺوٿي رھيو آھي
جيڪِي ٿيندو، اُھو پِڻ سُٺو ئي ٿيندو
تُنھنجو ڇا ويو، جو تون روئِين ٿو؟
تون ڇا آندو ھو، جو تون وِڃايو آھي؟
تون ڇا پيدا ڪَيو، جو ناس ٿي ويو؟
تون جيڪو ورتو، ھتان .ئِي ورتو
تون جيڪِي ڏنو، ھتي ئِي ڏِنو
جيڪِي اَڄ تُنھنجو آھي،ڪالھ ڪَنھن ٻئي جو ٿيندو
بَدل سَدل سَنسار جو نِيم آھي
چِنتا نہ ڪر، ھَلندو ھَل"""

    with open('assets/data/pustak_data.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    for page in data['pages']:
        if page['assetPage'] == 68:
            page['digitalText'] = geeta_text
            page['textStatus'] = 'verified'
            break
            
    with open('assets/data/pustak_data.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        
    print("Successfully injected Geeta Jo Saar into page 68.")

if __name__ == '__main__':
    inject_geeta()
