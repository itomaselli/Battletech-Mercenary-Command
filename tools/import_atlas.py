"""Import official Sarna SUCKit workbook with stdlib only; no spreadsheet macros executed."""
import zipfile,xml.etree.ElementTree as E,json,sys,hashlib,re,collections
from pathlib import Path
source=Path(sys.argv[1]);z=zipfile.ZipFile(source)
ns={'m':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
strings=[''.join(n.itertext()) for n in E.fromstring(z.read('xl/sharedStrings.xml'))]
def rows(name):
 result=[]
 for row in E.fromstring(z.read(name)).findall('m:sheetData/m:row',ns):
  values={}
  for c in row:
   value=c.find('m:v',ns)
   if value is not None:
    values[re.sub(r'\d','',c.attrib['r'])]=strings[int(value.text)] if c.get('t')=='s' else value.text
  result.append(values)
 return result
systems=[]; skipped=[]; allrows=rows('xl/worksheets/sheet3.xml')
for row in allrows[2:]:
 if not row.get('A') or not row.get('B'): continue
 try:
  item={'id':'sarna-'+str(int(float(row['A']))),'name':row['B'],'aliases':row.get('C',''),'x':float(row['D']),'y':float(row['E']),'source':row.get('G',''),'affiliations':{'3027':row.get('AB','U').split('|')[0],'3060':row.get('AP','U').split('|')[0]}}
  systems.append(item)
 except (ValueError,KeyError): skipped.append(row)
assert len({x['id'] for x in systems})==len(systems)
factions={}
for row in rows('xl/worksheets/sheet10.xml')[1:]:
 if row.get('A') and row.get('B'): factions[row['A']]={'name':row['B'],'color':row.get('C','#9cbab0')}
root=Path(__file__).resolve().parents[1]
data={'source':'https://github.com/sarna-net/sarna-maps','sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'reference_dates':{'3027':'3025','3060':'3059d'},'systems':systems,'factions':factions}
(root/'data/atlas.json').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')))
report={'source_system_count':allrows[0].get('D'),'imported':len(systems),'skipped':skipped,'duplicate_names':{n:c for n,c in collections.Counter(x['name'] for x in systems).items() if c>1},'coordinate_range':{axis:[min(x[axis] for x in systems),max(x[axis] for x in systems)] for axis in ['x','y']},'sha256':data['sha256'],'political_reference':data['reference_dates']}
(root/'docs/atlas-audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(json.dumps(report,ensure_ascii=False))
