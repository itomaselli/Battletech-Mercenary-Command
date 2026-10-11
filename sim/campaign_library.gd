extends RefCounted
const Campaign=preload("res://sim/campaign.gd")
var directory="user://careers"
func entries() -> Array:
 var result=[]
 var dir=DirAccess.open(directory)
 if dir==null:return result
 for file in dir.get_files():
  if not file.ends_with(".json"):continue
  var data=JSON.parse_string(FileAccess.get_file_as_string(directory+"/"+file))
  if data is Dictionary:result.append({"path":directory+"/"+file,"name":str(data.get("company_name","Partida")),"year":data.get("scenario_year",3027),"day":data.get("day",0)})
 result.sort_custom(func(a,b):return a.path>b.path)
 return result
func create(sim) -> String:
 if DirAccess.make_dir_recursive_absolute(directory)!=OK:return ""
 var stem=directory+"/career-"+str(Time.get_unix_time_from_system()).replace(".","-")+"-"+str(Time.get_ticks_usec())
 var path=stem+".json";var suffix=0
 while FileAccess.file_exists(path):suffix+=1;path=stem+"-"+str(suffix)+".json"
 return path if sim.save_game(path)==OK else ""
func import_legacy(path: String="user://campaign.json") -> Error:
 if not FileAccess.file_exists(path):return ERR_FILE_NOT_FOUND
 var destination=directory+"/legacy-import.json"
 if FileAccess.file_exists(destination):return OK
 var sim=Campaign.new();var error=sim.load_game(path)
 if error!=OK:return error
 error=DirAccess.make_dir_recursive_absolute(directory)
 return sim.save_game(destination) if error==OK else error
