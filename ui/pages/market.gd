extends RefCounted
static func draw(host):
 var UI=host.UI
 var sim=host.sim
 if host.section=="Personal":
  UI.text(host.content,"Contratación · incorporación y salario indicados antes de confirmar")
  var interval=UI.pager(host.content,sim.state.candidates.size(),int(host.preference("candidate_page",0)),4,func(page):host.remember("candidate_page",page);host.render())
  var grid=GridContainer.new();grid.columns=4 if host.size.x>=1250 else 2;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",16);host.content.add_child(grid)
  for i in range(interval[0],interval[1]):
   var c=sim.state.candidates[i];var card=UI.block(grid,c.name,c.role)
   UI.text(card,"Competencia %d · salario %d"%[c.skill,c.salary])
   UI.muted(card,"Incorporación: %d C-bills"%c.fee)
   UI.primary(card,"REVISAR CONTRATACIÓN →",func():host.confirm("Contratar a "+c.name,"Incorporación %d C-bills y salario %d/mes. ¿Confirmar?"%[c.fee,c.salary],func():return sim.hire(i)))
  if sim.state.candidates.is_empty():UI.text(host.content,"No hay candidatos disponibles en este momento.")
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
  var panes=[body,host.contextual("FICHA DE MERCADO")]
  var interval=UI.pager(panes[0],all.size(),maxi(0,int(all.map(func(o):return o.id).find(id)/4)),4,func(page):host.remember("offer",all[page*4].id);host.render())
  var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);panes[0].add_child(grid)
  for o in all.slice(interval[0],interval[1]):
   var card=UI.block(grid,sim.MECH_CATALOG[o.model].name)
   UI.unit_icon(card,sim.MECH_CATALOG[o.model])
   var b=UI.button(card,sim.MECH_CATALOG[o.model].name+(" · %d"%o.price if not catalog else ""),func():host.remember("offer",o.id);host.render());b.toggle_mode=true;b.button_pressed=o.id==id
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
   host.set_task("Comprar · %d…"%o.price,func():host.confirm("Comprar unidad","Pago %d ahora; entrega %d días. No incluye personal. Reserva una plaza."%[o.price,o.days],func():return sim.purchase_mech(o.id,o.price)))
 query.text_changed.connect(func(q):host.remember("query",q);fill.call())
 category.item_selected.connect(func(i):host.remember("category",category.get_item_metadata(i));fill.call());fill.call()
