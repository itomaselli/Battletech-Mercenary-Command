extends RefCounted
const Memory=preload("res://sim/story/memory.gd")
static func history(host,parent: Node,person: int=-1,unit: int=-1):
 var events=host.sim.state.story.events.filter(func(e):return (person<0 or person in e.people) and (unit<0 or unit in e.units))
 if events.is_empty():host.UI.text(parent,"Sin recuerdos nuevos desde la incorporación de la memoria causal.");return
 host.UI.text(parent,"Acontecimientos enlazados",true)
 var options={}
 for e in events.slice(-60):options[e.id]="#%d · Día %d · %s"%[e.id,e.day,e.kind]
 var selected=int(host.preference("memory",events[-1].id))
 if not options.has(selected):
  var older=host.sim.state.story.events.filter(func(e):return e.id==selected)
  if not older.is_empty():options[selected]="#%d · Día %d · %s"%[older[0].id,older[0].day,older[0].kind]
  else:selected=int(events[-1].id)
 var picker=host.UI.picker(parent,"Acontecimiento",options,selected)
 var detail=host.UI.column(parent)
 var show=func(id):
  host.UI.clear(detail)
  var found=host.sim.state.story.events.filter(func(e):return e.id==id)
  if found.is_empty():return
  var e=found[0]
  host.UI.text(detail,Memory.describe(e))
  for pid in e.people:host.UI.button(detail,"Persona: "+host.sim.person_name(pid),func():host.navigate("Compañía","Personal");host.remember("id",pid);host.render())
  for uid in e.units:
   var index=host.sim.mech_index(uid)
   if index>=0:host.UI.button(detail,"Unidad: "+host.sim.state.mechs[index].name,func():host.navigate("Compañía","Hangar");host.remember("uid",uid);host.render())
  for previous in e.parents:
   var ancestor=host.sim.state.story.events.filter(func(item):return item.id==previous)
   if not ancestor.is_empty():
    host.UI.text(detail,"Antecedente · "+Memory.describe(ancestor[0]))
    host.UI.button(detail,"Seguir antecedente #%d"%previous,func():host.remember("memory",previous);host.render())
  if e.parents.is_empty():host.UI.text(detail,"Sin antecedente vinculado; no se infiere una causa a partir de la fecha.")
 picker.item_selected.connect(func(i):host.remember("memory",picker.get_item_metadata(i));show.call(picker.get_item_metadata(i)))
 show.call(selected)

static func culture(host,parent: Node):
 var sim=host.sim
 var c=sim.state.story.culture
 host.UI.text(parent,"Identidad de compañía",true)
 var lines=[]
 for key in sim.Story.Culture.PRACTICES:lines.append("%s: %d antecedentes"%[sim.Story.Culture.PRACTICES[key],c.practices[key]])
 host.UI.text(parent,"\n".join(lines)+"\nSon prácticas observadas, no una puntuación moral. Cada persona las interpreta según sus prioridades.")
 host.action(parent,"Repartir 1.000 por empleado · total %d"%(sim.state.staff.size()*1000),func():return sim.rpg_command("story_culture",{"action":"bonus"}))
 host.UI.text(parent,"Disponible desde día %d. Tras dos repartos surge una expectativa de revisión en 56 días, sin deuda automática."%c.next_bonus)
 if c.expectation>0:host.UI.text(parent,"Revisión esperada: día %d%s"%[c.expectation," · solicitada" if c.reviewed else ""])

static func objectives(host,parent: Node):
 var sim=host.sim
 host.UI.text(parent,"Iniciativas propias",true)
 var g=sim.Story.Objectives.current(sim)
 if g.is_empty():
  var kinds=host.UI.picker(parent,"Propósito",sim.Story.Objectives.KINDS)
  var people={}
  for p in sim.state.staff:people[p.id]=p.name
  var person=host.UI.picker(parent,"Persona a desarrollar (solo desarrollo)",people)
  var contacts={}
  for contact in sim.RPG.Agenda.known(sim):contacts[contact]=contact
  var link=host.UI.picker(parent,"Enlace (solo red de apoyo)",contacts)
  host.action(parent,"Elegir iniciativa",func():return sim.rpg_command("story_objective",{"action":"choose","kind":kinds.get_item_metadata(kinds.selected),"person":person.get_item_metadata(person.selected) if person.selected>=0 else -1,"contact":link.get_item_metadata(link.selected) if link.selected>=0 else ""}))
 else:
  host.UI.text(parent,"%s · %d/3 · %s%s"%[sim.Story.Objectives.KINDS[g.kind],g.progress,sim.Universe.system(g.system).name," · "+sim.person_name(g.person) if g.kind=="person" else " · "+g.contact if g.kind=="network" else ""])
  var details={"person":"Cada sesión dura dos días y reserva al alumno: 3.000 con el capitán u oficial (también reservado), o 5.000 con un formador externo que libera al mando. Concede +1 experiencia y un avance. Tres sesiones completan el programa; también cuenta para su aspiración de formación.","community":"Entregar 10 suministros: +1 avance cada 7 días. Negociar: 2.000 y dos días, Trato 9 (7–8 parcial). Contratos locales de defensa, extracción o reconocimiento: +2 por éxito, +1 parcial. Al completar: presión −2, abastecimiento +1 y tensión de la disputa −2.","network":"Financiar enlaces: 5.000 y un día del capitán, +1 seguro. Negociar: 2.000 y dos días, Trato 9 (7–8 parcial). Al completar: +1 favor con el enlace elegido y +1 relación."}
  host.UI.text(parent,details[g.kind]+" Los encargos impiden viajar. No hay plazo obligatorio ni devolución de gastos al abandonar.")
  if not sim.state.story.objectives.jobs.is_empty():
   host.UI.text(parent,"Trabajo en curso hasta el día %d."%sim.state.story.objectives.jobs[0].due)
  else:
   host.action(parent,"Contratar formador externo · 5.000" if g.kind=="person" else "Aportar 10 suministros" if g.kind=="community" else "Financiar enlaces · 5.000",func():return sim.rpg_command("story_objective",{"action":"material"}))
   host.action(parent,"Dedicar tiempo del capitán",func():return sim.rpg_command("story_objective",{"action":"captain"}))
   var people={}
   for p in sim.state.staff:
    if p.id!=g.person:people[p.id]=p.name+" · competencia %d"%p.skill
   var officer=host.UI.picker(parent,"Delegar en",people)
   host.action(parent,"Encargar al oficial · mismo coste y plazo",func():return sim.rpg_command("story_objective",{"action":"delegate","officer":officer.get_item_metadata(officer.selected) if officer.selected>=0 else -1}))
  host.action(parent,"Abandonar objetivo · sin reembolso",func():return sim.rpg_command("story_objective",{"action":"abandon"}))
 for old in sim.state.story.objectives.goals.filter(func(item):return item.status!="open").slice(-3):host.UI.text(parent,"%s · %s · %d/3"%[sim.Story.Objectives.KINDS[old.kind],"cumplido" if old.status=="completed" else "abandonado",old.progress])

static func society(host,parent: Node):
 var sim=host.sim
 host.UI.text(parent,"Personas y memoria local",true)
 if sim.state.story.society.locals.is_empty():host.UI.text(parent,"Los enlaces civiles se presentan al pasar un día en un sistema con servicios.")
 for system in sim.state.story.society.locals:
  var local=sim.state.story.society.locals[system]
  host.UI.text(parent,"%s · %s\\nReconocimiento %+d · ayudas disponibles %d · último contacto día %d"%[local.name,sim.Universe.system(system).name,local.standing,local.credits,local.last])
  for id in local.memory.slice(-2):
   var events=sim.state.story.events.filter(func(e):return e.id==id)
   if not events.is_empty():host.UI.text(parent,Memory.describe(events[0]))
 host.UI.text(parent,"Los enlaces son personajes de esta campaña. Sus informes no revelan fuerzas ni intenciones ocultas. Apoyar una comunidad puede generar reciprocidad; las necesidades surgen del estado regional.")
