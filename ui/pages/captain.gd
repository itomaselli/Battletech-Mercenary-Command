extends RefCounted
static func configure(host):
 var UI=host.UI
 var sim=host.sim
 var origin=UI.picker(host.content,"Origen",sim.RPG.ORIGINS)
 var skill=UI.picker(host.content,"Especialidad",sim.RPG.SKILLS)
 var motive=UI.picker(host.content,"Motivación",sim.RPG.MOTIVES)
 var people={-1:"Sin vínculo inicial"}
 for p in sim.state.staff:people[p.id]=p.name
 var bond=UI.picker(host.content,"Vínculo",people)
 host.action(host.content,"Establecer trasfondo",func():return sim.rpg_command("configure",{"origin":origin.get_item_metadata(origin.selected),"specialty":skill.get_item_metadata(skill.selected),"motivation":motive.get_item_metadata(motive.selected),"bond":bond.get_item_metadata(bond.selected)}))
static func draw(host):
 if not host.sim.state.rpg.captain.configured:configure(host);return
 if host.section=="Asuntos":
  preload("res://ui/story.gd").objectives(host,host.content)
  host.rpg_sections(host.content,"Escena")
  host.rpg_sections(host.content,"Asuntos")
 elif host.section=="Legado":host.rpg_sections(host.content,"Legado")
 else:
  host.rpg_sections(host.content,"Personaje",func(e):return not e.title.begins_with("Conversar con "))
  for id in host.sim.state.rpg.circle:
   host.UI.button(host.content,"Expediente: "+host.sim.person_name(id),func():host.navigate("Compañía","Personal");host.remember("id",id);host.render())
