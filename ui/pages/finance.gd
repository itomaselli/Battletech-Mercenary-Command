extends RefCounted
static func draw(host):
 var UI=host.UI;var sim=host.sim;var report=sim.financial_report()
 var explanation=host.contextual("PREVISIÓN FINANCIERA")
 UI.text(explanation,"La previsión utiliza los compromisos actuales. Los pagos condicionados al éxito no se cuentan como fondos disponibles.")
 var metrics=HBoxContainer.new();metrics.add_theme_constant_override("separation",12);host.content.add_child(metrics)
 for item in [["Fondos libres",report.free],["Comprometido",report.reserved],["Proyección a 30 días",report.projected]]:
  UI.text(UI.block(metrics,item[0]),"%d C-bills"%item[1],true)
 var tabs=HBoxContainer.new();host.content.add_child(tabs)
 for name in ["Previsión","Movimientos","Categorías"]:
  var tab=UI.button(tabs,name,func():host.remember("finance_tab",name);host.render());tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tab.custom_minimum_size.x=140;tab.toggle_mode=true;tab.button_pressed=host.preference("finance_tab","Previsión")==name
 var selected=host.preference("finance_tab","Previsión")
 if selected=="Movimientos":ledger(host);return
 if selected=="Categorías":
  var categories=UI.block(host.content,"Ingresos y gastos por categoría","Desde el inicio del registro")
  for category in report.categories:
   var c=report.categories[category];UI.text(categories,"%s · ingresos %d · gastos %d · neto %+d"%[category,c.income,c.expense,c.income-c.expense])
  if report.categories.is_empty():UI.text(categories,"Todavía no hay movimientos registrados.")
  return
 var panes=[host.content,host.contextual("DEUDAS Y COMPROMISOS")]
 var due=UI.block(panes[0],"Próximos pagos")
 UI.text(due,"Nómina · %d C-bills · en %d días"%[report.payroll,report.next_payroll-sim.state.day])
 UI.text(due,"Propiedad · %d C-bills · en %d días"%[report.ownership.next_bill,report.ownership.days])
 UI.text(due,"Taller previsto a 30 días · %d C-bills"%report.repairs_30)
 UI.button(due,"Revisar taller →",func():host.navigate("Compañía","Taller"))
 var debt=UI.block(panes[1],"Deudas y regularización")
 for item in [["Salarial",sim.state.arrears,sim.settle_arrears],["Contractual",sim.state.contract_debt,sim.settle_contract_debt],["Mantenimiento",report.ownership.debt,sim.settle_ownership_debt]]:
  if item[1]<=0:UI.muted(debt,item[0]+" · sin deuda")
  else:
   var b=UI.button(debt,"Pagar %s · %d"%[item[0],item[1]],func():host.run(item[2]));b.disabled=report.free<=0
 var assumptions=UI.disclosure(host.content,"Cómo se calcula la previsión")
 UI.text(assumptions,"Caja actual %d. Se descuentan entregas, nómina, deudas, taller previsto y próxima factura de propiedad. Plantilla y taller actuales; recursos suficientes y sin compras nuevas. No incluye %d de cobro condicionado al éxito."%[sim.state.funds,report.conditional])
 UI.text(assumptions,"Propiedad %d/día · devengado %d. Taller autorizado total %d."%[report.ownership.daily,report.ownership.accrued,report.repairs])
static func ledger(host):
 var UI=host.UI;var sim=host.sim
 var ledger=UI.block(host.content,"Movimientos recientes","Registro real de la campaña · más recientes primero")
 var entries=sim.state.ledger.duplicate();entries.reverse()
 var interval=UI.pager(ledger,entries.size(),int(host.preference("ledger_page",0)),6,func(page):host.remember("ledger_page",page);host.render())
 if entries.is_empty():UI.text(ledger,"Todavía no hay movimientos registrados.")
 for e in entries.slice(interval[0],interval[1]):
  var line=UI.block(ledger,"Día %d · %s · %+d C-bills"%[e.day,e.category,e.amount]);UI.text(line,e.detail)
