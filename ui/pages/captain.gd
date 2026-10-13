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
 var profile=host.contextual("EL COMANDANTE")
 profile.add_child(preload("res://visual/art.gd").portrait_view(int(host.sim.state.military.seed),-1,3))
 host.UI.text(profile,host.sim.state.captain_name,true)
 host.UI.muted(profile,"Sus decisiones dejan consecuencias en la compañía. Revise sus vínculos, asuntos e iniciativas antes de comprometer su tiempo.")
 if not host.sim.state.rpg.captain.configured:configure(host);return
 if host.section=="Asuntos":
  var bar=HBoxContainer.new();host.content.add_child(bar)
  for name in ["Escena","Iniciativa","Asuntos"]:
   var b=host.UI.button(bar,name,func():host.remember("chapter",name);host.render());b.toggle_mode=true;b.button_pressed=host.preference("chapter","Escena")==name
  var chapter=host.preference("chapter","Escena")
  if chapter=="Iniciativa":preload("res://ui/story.gd").objectives(host,host.UI.block(host.content,"Iniciativa del capitán"))
  else:
   host.rpg_sections(host.content,chapter)
   if chapter=="Escena" and host.sim.state.rpg.scene.is_empty():host.UI.text(host.content,"No hay una escena pendiente. Puede trabajar en una iniciativa o revisar sus asuntos.")
 elif host.section=="Legado":host.rpg_sections(host.content,"Legado")
 else:
  host.rpg_sections(host.content,"Personaje",func(e):return not e.title.begins_with("Conversar con "))
  for id in host.sim.state.rpg.circle:
   host.UI.button(host.content,"Expediente: "+host.sim.person_name(id),func():host.navigate("Compañía","Personal");host.remember("id",id);host.render())
