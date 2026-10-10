import json
import re

def process_text():
    with open('scripts/raw_text.txt', 'r', encoding='utf-8') as f:
        raw_text = f.read()
    
    # Split the document by major headings
    sections = {}
    
    # Find Mangla Charan
    mc_start = raw_text.find("مَنگلاچَرن")
    ustati_start = raw_text.find("اُستتي")
    av_start = raw_text.find("اَمبرت واڻي")
    prarthana1_start = raw_text.find("پرارٿنا")
    aarti1_start = raw_text.find("آرتي صاحب")
    aarti2_start = raw_text.find("آرتي\nسَتگُرو بابا شِو ڀَڄن صاحب")
    prarthana2_start = raw_text.find("پِــــرارٿــنـــــا\nجئه سماڌا")
    
    sections['mangla_charan'] = raw_text[mc_start:ustati_start].strip()
    sections['ustati'] = raw_text[ustati_start:av_start].strip()
    
    # Amrit Vani
    av_text = raw_text[av_start:prarthana1_start]
    # Split by numbers
    av_parts = re.split(r'\n\s*\d+\.\s*', av_text)
    # The first part contains the title and maybe the first stanza which is numbered with .1 instead of 1.
    av_parts_cleaned = []
    # Let's fix the first stanza manually because it's written as `رُوپ ڀَڄن آ نُور اِيشور، .1`
    first_part = av_parts[0]
    if '.1' in first_part:
        title, stanza1 = first_part.split('.1')
        av_parts_cleaned.append(stanza1.strip())
    
    for part in av_parts[1:]:
        av_parts_cleaned.append(part.strip())
        
    sections['amrit_vani'] = av_parts_cleaned # Should be 26 items
    
    prarthana1 = raw_text[prarthana1_start:aarti1_start].strip()
    sections['prarthana1'] = prarthana1
    
    aarti1_text = raw_text[aarti1_start:aarti2_start].strip()
    # Split by numbers 1. 2. 3. 4. 5.
    aarti1_parts = re.split(r'\n\s*\d+\.\s*', aarti1_text)
    sections['aarti1'] = [p.strip() for p in aarti1_parts] # Should be 6 items (chorus + 5 stanzas)
    
    aarti2_text = raw_text[aarti2_start:prarthana2_start].strip()
    aarti2_parts = re.split(r'\n\s*\d+\.\s*', aarti2_text)
    sections['aarti2'] = [p.strip() for p in aarti2_parts] # Should be 5 items (chorus + 4 stanzas)
    
    prarthana2 = raw_text[prarthana2_start:].strip()
    sections['prarthana2'] = prarthana2
    
    # Now update pustak_data.json
    with open('assets/data/pustak_data.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    for page in data['pages']:
        page_num = page['assetPage']
        text = None
        
        if page_num == 15:
            text = sections['mangla_charan']
        elif page_num == 16:
            text = sections['ustati']
        elif 17 <= page_num <= 42:
            idx = page_num - 17
            if idx < len(sections['amrit_vani']):
                text = sections['amrit_vani'][idx]
        elif page_num == 43:
            text = sections['prarthana1']
        elif 44 <= page_num <= 49:
            idx = page_num - 44
            if idx < len(sections['aarti1']):
                text = sections['aarti1'][idx]
        elif 50 <= page_num <= 54:
            idx = page_num - 50
            if idx < len(sections['aarti2']):
                text = sections['aarti2'][idx]
        elif page_num == 59:
            text = sections['prarthana2']
            
        if text:
            page['digitalText'] = text
            page['textStatus'] = 'verified'
            
    with open('assets/data/pustak_data.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        
    print(f"Amrit Vani stanzas: {len(sections['amrit_vani'])}")
    print(f"Aarti1 stanzas: {len(sections['aarti1'])}")
    print(f"Aarti2 stanzas: {len(sections['aarti2'])}")
    print("Done updating pustak_data.json")

if __name__ == '__main__':
    process_text()
