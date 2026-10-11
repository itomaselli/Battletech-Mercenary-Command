extends RefCounted
static func draw(host):
 var UI=host.UI
 var sim=host.sim
 if host.section=="Personal":
  UI.text(host.content,"Contratación · incorporación y salario indicados antes de confirmar")
  for i in range(sim.state.candidates.size()):
   var c=sim.state.candidates[i]
   UI.text(host.content,"%s · %s · competencia %d · salario %d"%[c.name,c.role,c.skill,c.salary],true)
   host.action(host.content,"Contratar · %d"%c.fee,func():return sim.hire(i))
  return
 if host.section=="Repuestos":host.admin.logistics_page(host.content);host.rpg_sections(host.content,"Taller",func(e):return e.title=="Taller y políticas");return
 var catalog=host.section=="Catálogo"
 var query=LineEdit.new();query.placeholder_text="Buscar chasis o variante";query.text=host.preference("query","");host.content.add_child(query)
 var category=UI.picker(host.content,"Clase",{"":"Todas","light":"Ligeros","medium":"Medios","heavy":"Pesados","ground":"Vehículos"},host.preference("category",""))
 var body=UI.column(host.content)
 var fill=func():
  UI.clear(body)
  var all=[]
  if catalog:
   for index in sim.Catalog.eligible(sim.state.scenario_year):all.append({"id":index,"model":index})
  else:all=sim.state.mech_market
  all=all.filter(func(o):return (query.text.is_empty() or sim.MECH_CATALOG[o.model].name.to_lower().contains(query.text.to_lower())) and (host.preference("category","")=="" or sim.MECH_CATALOG[o.model].class==host.preference("category","")))
  var id=int(host.preference("offer",all[0].id if not all.is_empty() else -1))
  if not all.any(func(o):return o.id==id) and not all.is_empty():id=int(all[0].id)
  var panes=UI.split(body,host.size.x)
  for o in all:
   var b=UI.button(panes[0],sim.MECH_CATALOG[o.model].name+(" · %d"%o.price if not catalog else ""),func():host.remember("offer",o.id);host.render());b.toggle_mode=true;b.button_pressed=o.id==id
  var found=all.filter(func(o):return o.id==id)
  if found.is_empty():UI.text(panes[1],"Sin coincidencias.");return
  var o=found[0]
  var model=sim.MECH_CATALOG[o.model]
  host.admin.unit_picture(panes[1],model)
  UI.text(panes[1],sim.Catalog.describe(model))
  UI.text(panes[1],"Fuente: "+model.sarna)
  if catalog:
   UI.button(panes[1],"Fijar comparación",func():host.remember("comparison",model.id);host.render())
   for reference in sim.MECH_CATALOG:
    if reference.id==host.preference("comparison",""):UI.text(panes[1],"REFERENCIA\n"+sim.Catalog.describe(reference))
  else:
   var estimate=sim.acquisition_estimate(o.id)
   UI.text(panes[1],"Integridad %d%% · entrega %d días · vence día %d\nCompra %d · compra/reparación/suministros/30 días %d\nPlazas %d/%d"%[o.hp,o.days,o.expires,o.price,estimate.total,sim.hangar_used(),sim.MAX_HANGAR])
   UI.button(panes[1],"Comprar · %d…"%o.price,func():host.confirm("Comprar unidad","Pago %d ahora; entrega %d días. No incluye personal. Reserva una plaza."%[o.price,o.days],func():return sim.purchase_mech(o.id,o.price)))
 query.text_changed.connect(func(q):host.remember("query",q);fill.call())
 category.item_selected.connect(func(i):host.remember("category",category.get_item_metadata(i));fill.call());fill.call()
