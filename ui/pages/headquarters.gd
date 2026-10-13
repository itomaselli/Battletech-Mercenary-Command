extends RefCounted
const H=preload("res://sim/headquarters.gd")
static func order(host,parent,label: String,args: Dictionary,description: String=""):
 return host.UI.button(parent,label,func():
  if description.is_empty():host.run(func():return host.sim.hq_command(args))
  else:host.confirm(label,description,func():return host.sim.hq_command(args)))
static func draw(host):
 var UI=host.UI;var sim=host.sim;var h=sim.state.hq
 host.page_title.text="HQ · "+(h.name if h.stage=="owned" else "UN HOGAR PARA LA COMPAÑÍA")
 var context=host.contextual("CUARTEL GENERAL")
 UI.text(context,"Union reacondicionada · sede móvil",true)
 if h.stage!="owned" or host.preference("hq_tab","Resumen")=="Resumen":UI.text(context,"El HQ acompaña a la compañía. El salto interestelar sigue contratado; no aumenta el límite de cuatro unidades en operaciones.")
 if h.stage!="owned":acquisition(host,context);return
 var money=H.forecast(sim)
 UI.text(context,"%d C-bills/día · próxima factura %d en %d días"%[money.daily,money.next_bill,money.days])
 UI.text(context,"Reserva" if h.reserve else "Ventajas suspendidas por deuda" if h.debt>0 else "En servicio")
 UI.text(context,"Enlace: "+sim.person_name(h.officer) if h.officer>=0 else "Enlace de compañía sin asignar")
 if h.debt>0:order(host,context,"Saldar deuda · %d"%h.debt,{"action":"pay"})
 order(host,context,"Reactivar HQ" if h.reserve else "Pasar a reserva",{"action":"reserve"},"En reserva cuesta 100/día; ventajas, obras y cursos se suspenden. No pierde instalaciones ni propiedad.")
 var tabs=HBoxContainer.new();host.content.add_child(tabs)
 for name in ["Resumen","Instalaciones","Proyectos","Historia"]:
  var b=UI.button(tabs,name,func():host.remember("hq_tab",name);host.render());b.theme_type_variation="TabButton";b.toggle_mode=true;b.button_pressed=host.preference("hq_tab","Resumen")==name
 match host.preference("hq_tab","Resumen"):
  "Instalaciones":installations(host,context)
  "Proyectos":projects(host,context)
  "Historia":
   var events=h.history.duplicate();events.reverse()
   var span=UI.pager(host.content,events.size(),int(host.preference("hq_history",0)),6,func(n):host.remember("hq_history",n);host.render())
   for e in events.slice(span[0],span[1]):UI.text(UI.block(host.content,"Día %d"%e.day),e.text)
  _:overview(host,context)
 if host.preference("hq_tab","Resumen")!="Instalaciones":host.set_task("REVISAR FINANZAS →",func():host.navigate("Finanzas","Previsión"))
static func acquisition(host,context):
 var UI=host.UI;var sim=host.sim;var h=sim.state.hq
 var body=UI.block(host.content,"Proyecto de adquisición","Precios adaptados a la economía del juego; no son precios canónicos de naves.")
 UI.text(body,"Hito: día 60, reputación 4 y cuatro operaciones cumplidas. Actualmente: día %d · reputación %d · %d éxitos registrados."%[sim.state.day,sim.state.reputation,h.wins])
 UI.text(body,"Una Union usada requiere rehabilitación antes de entrar en servicio. Tripulación naval, equipo médico y logística de a bordo incluidos en su coste base de 12000 por 30 días.")
 UI.text(context,"Fondos libres: %d C-bills\nReserva exigida para adquirir: %d (dos nóminas + un mes del HQ)."%[sim.available_funds(),H.reserve_required(sim)])
 match h.stage:
  "none":
   host.set_task("INSPECCIONAR · 10000 C-bills",func():host.confirm("Inspeccionar Union","La inspección cuesta 10000 y abre las tres rutas de adquisición. No compra la nave.",func():return sim.hq_command({"action":"inspect"})),H.eligible(sim))
  "inspected":
   UI.text(body,"Inspección completada. Elija una ruta; al comprometerla no puede cambiarse.")
   order(host,body,"Comprar · 450000 · 14 días",{"action":"buy"},"Compra y rehabilitación. Debe conservar la reserva operativa; no hay reembolso automático.")
   var employers={}
   for c in sim.state.offers:employers[c.employer]=c.employer
   var picker=UI.picker(body,"Patrocinador",employers)
   UI.button(body,"Solicitar recompensa por servicio",func():
    if picker.item_count==0:return
    host.confirm("Patrocinio","Requiere tres éxitos nuevos para este empleador y ceder 180000 de pagos finales positivos (máximo 50000 por éxito); rehabilitación posterior 60000. No acepta contratos automáticamente.",func():return sim.hq_command({"action":"pledge","employer":picker.get_item_metadata(picker.selected)})))
   order(host,body,"Prospección de casco · 20000 · 14 días",{"action":"survey"},"Requiere tres lotes procesados que acrediten relación con recuperadores. La prospección localiza otro casco con derechos verificables; rehabilitarlo costará 160000 y 21 días.")
   host.set_task("REVISAR CONTRATOS →",func():host.navigate("Operaciones","Contratos"))
  "pledged":
   UI.text(body,"Patrocinador: %s\nÉxitos nuevos: %d/3 · valor cedido: %d/180000\nNo se cede dinero por fracasos, anticipos ni después de la entrega."%[h.sponsor,h.sponsor_wins,h.credit])
   host.set_task("RECLAMAR Y REHABILITAR · 60000",func():host.confirm("Adquirir HQ","60000 y catorce días de rehabilitación; debe conservar la reserva operativa.",func():return sim.hq_command({"action":"claim"})),h.sponsor_wins>=3 and h.credit>=180000)
  "survey":
   UI.text(body,"Prospección: %d jornadas restantes. Avanza con servicios locales y sin operación ni viaje en curso."%h.survey_left)
   host.set_task("VOLVER A OPERACIONES →",func():host.navigate("Operaciones","Territorio"))
  "located":
   UI.text(body,"Casco localizado. Los derechos de recuperación fueron verificados por el corredor.")
   host.set_task("REHABILITAR · 160000",func():host.confirm("Recuperar Union","160000 y 21 jornadas en puerto; debe conservar la reserva operativa.",func():return sim.hq_command({"action":"claim"})))
  "refit":
   UI.text(body,"Rehabilitación: %d jornadas en puerto restantes. El proyecto se pausa durante operaciones o traslados. No hay ventajas hasta la entrega."%h.refit_left)
   host.set_task("VOLVER A OPERACIONES →",func():host.navigate("Operaciones","Territorio"))
 if not h.history.is_empty():UI.text(UI.block(host.content,"Último informe"),h.history[-1].text)
static func overview(host,context):
 var UI=host.UI;var h=host.sim.state.hq
 var identity=UI.block(host.content,h.name,h.origin+" · adquirido el día %d"%h.acquired)
 identity.add_child(preload("res://visual/emblems.gd").view(host.sim.state.emblem_id,64))
 var name=LineEdit.new();name.text=h.name;name.max_length=48;identity.add_child(name)
 UI.button(identity,"Bautizar HQ",func():host.run(func():return host.sim.hq_command({"action":"rename","name":name.text})))
 var candidates={}
 for p in host.sim.state.staff:candidates[p.id]=p.name
 var officer=UI.picker(identity,"Enlace con la tripulación (no reemplaza al capitán naval)",candidates,h.officer)
 UI.button(identity,"Asignar enlace",func():
  if officer.item_count>0:host.run(func():return host.sim.hq_command({"action":"officer","id":officer.get_item_metadata(officer.selected)})))
 var deck=UI.block(host.content,"Distribución funcional","Cuatro espacios modernizables · esquema de gestión, no plano canónico")
 var row=GridContainer.new();row.columns=2;deck.add_child(row)
 var installed=h.modules.keys()
 for i in range(4):
  var id=installed[i] if i<installed.size() else ""
  var slot=UI.button(row,"ESPACIO %d\n%s"%[i+1,H.MODULES[id].name if not id.is_empty() else "Disponible"],func():host.remember("hq_tab","Instalaciones");host.render())
  slot.size_flags_horizontal=Control.SIZE_EXPAND_FILL;slot.custom_minimum_size=Vector2(140,88)
 var crew=UI.disclosure(host.content,"Tripulación de la Union")
 for p in h.crew:UI.text(crew,p.name+" · "+p.role)
 UI.text(crew,"Equipo naval, sanitario y logístico incluido en mantenimiento. No aporta pilotos ni técnicos de máquinas a la plantilla operativa.")
 if not h.request.is_empty():
  var r=h.request;UI.text(context,"PETICIÓN DE LA TRIPULACIÓN",true);UI.text(context,r.text)
  for item in [["Apoyar propuesta","support"],["Aplazar","later"],["Rechazar","decline"]]:order(host,context,item[0],{"action":"respond","choice":item[1]})
static func installations(host,context):
 var UI=host.UI;var h=host.sim.state.hq
 UI.text(host.content,"%d/4 espacios ocupados · una obra a la vez · máximo dos niveles"%h.modules.size(),true)
 var selected=str(host.preference("hq_module","workshop"))
 var grid=GridContainer.new();grid.columns=2 if host.scroll.size.x>650 else 1;host.content.add_child(grid)
 for id in H.MODULES:
  var b=UI.button(grid,H.MODULES[id].name+"\nNivel %d"%h.modules.get(id,0),func():host.remember("hq_module",id);host.render());b.toggle_mode=true;b.button_pressed=id==selected;b.custom_minimum_size.y=64;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var spec=H.MODULES[selected];var level=int(h.modules.get(selected,0));UI.text(context,spec.name,true);UI.text(context,spec.effect)
 UI.text(context,"Nivel actual %d · coste operativo %d/día.\nSiguiente nivel: %d C-bills, %d jornadas en puerto y +40/día."%[level,level*40,int(spec.price)*(level+1),7+level*3] if level<2 else "Nivel máximo. Coste operativo: 80/día.")
 UI.text(context,"Ventaja activa: %d%%. En reserva o con deuda pasa a 0%%."%H.rate(host.sim,selected))
 host.set_task("INSTALAR" if level==0 else "MEJORAR" if level<2 else "NIVEL MÁXIMO",func():host.confirm("Modernizar "+spec.name,"Coste %d C-bills, %d jornadas en puerto y +40/día. Pago al autorizar; no reembolsable. El nuevo nivel sustituye al anterior."%[int(spec.price)*(level+1),7+level*3],func():return host.sim.hq_command({"action":"upgrade","module":selected})),level<2 and h.project.is_empty() and H.active(host.sim) and (level>0 or h.modules.size()<4))
 if level>0:order(host,context,"Desmontar instalación",{"action":"remove","module":selected},"Libera un espacio y elimina su ventaja. Sin reembolso. No puede desmontar simuladores con cursos pendientes.")
static func projects(host,context):
 var UI=host.UI;var h=host.sim.state.hq
 if h.project.is_empty():UI.text(host.content,"No hay obras en curso. Seleccione una instalación para modernizar el HQ.")
 else:
  var p=h.project;UI.text(UI.block(host.content,"Obra: "+H.MODULES[p.id].name),"Nivel %d · %d jornadas restantes · %d pagados.\nSolo avanza en puerto, sin operación activa, con HQ al día y fuera de reserva."%[p.level,p.left,p.cost]);order(host,context,"Cancelar obra",{"action":"cancel_project"},"El gasto no se devuelve; conserva el nivel anterior.")
 for id in h.promises:
  if h.promises[id].status=="pending":UI.text(host.content,"Compromiso pendiente: "+H.MODULES[id].name+". La obra debe financiarse en Instalaciones.")
 var school=UI.block(host.content,"Formación de pilotos y dotaciones","Simulador activo requerido · 1000 C-bills · siete jornadas · una matrícula cada 30 días por persona")
 for key in h.training:
  UI.text(school,"%s · %d jornadas restantes"%[host.sim.person_name(int(key)),h.training[key].left]);order(host,school,"Cancelar curso",{"action":"cancel_training","id":int(key)},"El alumno queda disponible; no se devuelve el coste de matrícula.")
 if h.training.is_empty():
  var candidates={}
  for p in host.sim.state.staff:
   if p.role in ["Piloto","Dotación"]:candidates[p.id]=p.name
  var picker=UI.picker(school,"Alumno",candidates)
  var b=UI.button(school,"Matricular",func():
   if picker.item_count>0:host.confirm("Matricular","El alumno queda reservado siete jornadas. Las lesiones, reserva o deuda pausan el curso.",func():return host.sim.hq_command({"action":"train","id":picker.get_item_metadata(picker.selected)})))
  b.disabled=H.rate(host.sim,"simulator")==0
