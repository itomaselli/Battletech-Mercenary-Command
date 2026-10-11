extends RefCounted
const Start=preload("res://sim/career_start.gd")
const Campaign=preload("res://sim/campaign.gd")
var step=0
var seed_value=0
var year=3027
var unit_roll=0
var people_roll=0
var company="Compañía independiente"
var captain="Comandante"
var origin=""
var specialty=""
var motivation=""
var bond=-1
var economy=100
var danger=100
var frequency=14
var draft={}
var confirming=false
func _init():
 seed_value=int(Time.get_ticks_usec()%2147483647)
 origin=Campaign.RPG.ORIGINS.keys()[0];specialty=Campaign.RPG.SKILLS.keys()[0];motivation=Campaign.RPG.MOTIVES.keys()[0]
 regenerate()
func regenerate():draft=Start.generate(seed_value,year,unit_roll,people_roll)
func build():
 var sim=Campaign.new(seed_value,year,draft)
 if not sim.set_identity(company,captain):return null
 sim.rpg_command("configure",{"origin":origin,"specialty":specialty,"motivation":motivation,"bond":bond})
 sim.rpg_command("arcs",{"action":"settings","economy":economy,"danger":danger,"frequency":frequency})
 sim.log_event("Primer informe","Fuerza inicial: cuatro unidades operativas; cuatro puestos de combate, taller y logística cubiertos. Revise mantenimiento y nómina antes de aceptar su primer contrato.")
 return sim
func draw(host):
 var UI=host.UI;var parent=host.content
 UI.text(parent,"Nueva carrera · %d/4 · %s"%[step+1,["Escenario e identidad","Capitán","Fuerza y personal","Revisión"][step]],true)
 controls(host,parent)
 if step==0:
  var years=UI.picker(parent,"Escenario",{3027:"3027 · Guerras de Sucesión",3060:"3060 · Catálogo ampliado"},year)
  years.item_selected.connect(func(i):year=int(years.get_item_metadata(i));regenerate();host.render())
  UI.text(parent,"Cambiar escenario regenera el equipo. Los nombres personalizados se conservan.")
  for spec in [["Mantenimiento",{80:"80%",100:"100%",120:"120%"},"economy"],["Daño de operaciones",{80:"80%",100:"100%",120:"120%"},"danger"],["Invitaciones narrativas",{7:"Cada 7 días elegibles",14:"Cada 14 días elegibles",28:"Cada 28 días elegibles"},"frequency"]]:
   var option=UI.picker(parent,spec[0],spec[1],get(spec[2]))
   option.item_selected.connect(func(i):set(spec[2],option.get_item_metadata(i)))
  field(parent,"Compañía",company,func(v):company=v)
  field(parent,"Capitán",captain,func(v):captain=v)
  var seed_input=field(parent,"Semilla",str(seed_value),func(_v):pass)
  UI.button(parent,"Aplicar semilla",func():
   if seed_input.text.is_valid_int() and abs(int(seed_input.text))<=2147483647:
    seed_value=int(seed_input.text);unit_roll=0;people_roll=0;regenerate();host.render()
   else:host.status.text="La semilla debe ser un entero entre −2147483647 y 2147483647.")
 elif step==1:
  for spec in [["Origen",Campaign.RPG.ORIGINS,"origin"],["Especialidad",Campaign.RPG.SKILLS,"specialty"],["Motivación",Campaign.RPG.MOTIVES,"motivation"]]:
   var picker=UI.picker(parent,spec[0],spec[1],get(spec[2]))
   picker.item_selected.connect(func(i):set(spec[2],picker.get_item_metadata(i)))
  UI.text(parent,"El vínculo inicial se elige después de revisar el personal. El trasfondo progresa mediante sus actos.")
 elif step==2:
  var row=HFlowContainer.new();parent.add_child(row)
  UI.button(row,"Sortear unidades",func():unit_roll+=1;regenerate();host.render())
  UI.button(row,"Sortear personas",func():people_roll+=1;regenerate();host.render())
  UI.button(row,"Sortear ambos",func():unit_roll+=1;people_roll+=1;regenerate();host.render())
  UI.text(parent,"Cuatro unidades del pool completo del año: variantes y vehículos con igual probabilidad por entrada; pueden repetirse. Sin compensación oculta por tonelaje o valor.")
  roster(host)
 else:
  UI.text(parent,"%s · Capitán %s · %d · semilla %d"%[company,captain,year,seed_value],true)
  var people={-1:"Sin vínculo inicial"}
  for i in range(draft.people.size()):people[i]=draft.people[i].name+" · "+draft.people[i].role
  var picker=UI.picker(parent,"Persona con vínculo inicial",people,bond)
  picker.item_selected.connect(func(i):bond=int(picker.get_item_metadata(i)))
  roster(host)
  UI.text(parent,"Mantenimiento %d%% · daño %d%% · invitaciones cada %d días elegibles"%[economy,danger,frequency])
  UI.text(parent,"240.000 C-bills · 90 suministros · Galatea. Se creará un guardado independiente; su campaña anterior se conserva.")
func roster(host):
 var UI=host.UI
 var panes=UI.split(host.content,host.content.size.x)
 UI.text(panes[0],"Fuerza inicial",true);UI.text(panes[1],"Personal inicial",true)
 var monthly=0;var upkeep=0
 for i in range(4):
  var model=Start.model(draft.units[i]);upkeep+=int(model.maintenance)
  host.admin.unit_picture(panes[0],model)
  UI.text(panes[0],"Asignado: %s · %s"%[draft.people[i].name,draft.people[i].role])
 for p in draft.people:
  monthly+=int(p.salary)
  var row=HBoxContainer.new();panes[1].add_child(row)
  row.add_child(preload("res://visual/art.gd").portrait_view(int(p.portrait_seed),int(p.portrait_id),2))
  UI.text(row,"%s · %s\n%s · competencia %d · salario %d\n%s"%[p.name,p.callsign,p.role,p.skill,p.salary,p.background])
 UI.text(host.content,"Nómina base: %d / mes · mantenimiento de unidades: %d / día. La composición puede resultar costosa."%[monthly,int(upkeep*economy/100.0)])
func field(parent,caption: String,value: String,callback: Callable) -> LineEdit:
 preload("res://ui/components.gd").text(parent,caption)
 var input=LineEdit.new();input.text=value;input.max_length=48;parent.add_child(input);input.text_changed.connect(callback);return input

func controls(host,parent):
 var UI=host.UI
 var bar=HFlowContainer.new();parent.add_child(bar)
 UI.button(bar,"Cancelar",func():host.wizard=null;host.render())
 if step>0:UI.button(bar,"← Atrás",func():step-=1;host.render())
 if step<3:UI.button(bar,"Siguiente →",func():step+=1;host.render())
 else:UI.button(bar,"Iniciar carrera",func():host.finish_career())
