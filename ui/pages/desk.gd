extends RefCounted
static func draw(host):
 var UI=host.UI;var sim=host.sim
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);host.content.add_child(row)
 var force=UI.block(row,"Estado de la compañía")
 var ready=0
 for i in range(sim.state.mechs.size()):
  if preload("res://ui/pages/operations.gd").eligible(sim,sim.state.mechs[i].uid):ready+=1
 UI.text(force,"%d / %d unidades listas en base · %d empleados"%[ready,sim.state.mechs.size(),sim.state.staff.size()])
 var agenda=UI.block(row,"Próximo compromiso")
 var dates=[{"day":sim.financial_report().next_payroll,"text":"Nómina del personal"}]
 for order in sim.state.orders:dates.append({"day":order.due,"text":"Entrega de suministros"})
 if not sim.state.accepted.is_empty() and sim.state.active.is_empty():dates.append({"day":sim.state.accepted.deadline,"text":"Límite de despliegue"})
 for module in ["agenda","workshop","delegation"]:
  for job in sim.state.rpg[module].jobs:dates.append({"day":job.due,"text":"Trabajo de "+sim.person_name(job.get("person",-1))})
 dates.sort_custom(func(a,b):return a.day<b.day)
 for item in dates.slice(0,1):UI.text(agenda,"En %d días · %s"%[maxi(0,item.day-sim.state.day),item.text])
