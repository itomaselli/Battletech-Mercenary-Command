extends RefCounted
const Society=preload("res://sim/story/society.gd")
const Objectives=preload("res://sim/story/objectives.gd")
const Culture=preload("res://sim/story/culture.gd")
const People=preload("res://sim/story/people.gd")
## Player-visible history only. No private operational/world state is copied.
static func create(day: int) -> Dictionary:
 return {"revision":5,"society":Society.create(),"objectives":Objectives.create(),"culture":Culture.create(),"people":People.create(),"since":day,"next":1,"events":[],"threads":{}}
static func capture(sim,kind: String,text: String,people: Array=[],units: Array=[],thread: String="",parents: Array=[]) -> int:
 var s=sim.state.story
 var links=parents.duplicate()
 if not thread.is_empty() and s.threads.has(thread) and not s.threads[thread] in links:links.append(s.threads[thread])
 var id=int(s.next)
 s.next+=1
 s.events.append({"id":id,"day":int(sim.state.day),"kind":kind,"text":text,"people":people.duplicate(),"units":units.duplicate(),"parents":links,"thread":thread})
 if not thread.is_empty():s.threads[thread]=id
 return id
static func operation_key(sim) -> String:
 return "operation:%d:%d"%[sim.state.active.get("contract",{}).get("id",-1),sim.state.active.get("started",sim.state.military.current.get("started",sim.state.day))]
static func operation(sim,outcome: String):
 var people=[]
 var units=[]
 for i in sim.state.active.team:
  var m=sim.state.mechs[i]
  people.append(int(m.pilot_id));units.append(int(m.uid))
 sim.log_event("Historia de operación",sim.state.active.contract.name+": "+{"success":"objetivo cumplido","partial":"cumplimiento parcial","failure":"objetivo no cumplido","cancelled":"retirada ordenada"}.get(outcome,outcome),people,units,operation_key(sim))
static func describe(event: Dictionary) -> String:
 return "#%d · Día %d · %s\n%s"%[event.id,event.day,event.kind,event.text]
static func valid(s: Variant,day: int) -> bool:
 if not s is Dictionary or s.get("revision")!=5 or not integer(s.get("since"),0,day) or not integer(s.get("next"),1,1000000000):return false
 if not s.get("events") is Array or not s.get("threads") is Dictionary:return false
 if not Society.valid(s.get("society"),day):return false
 if not Objectives.valid(s.get("objectives"),day):return false
 if not Culture.valid(s.get("culture"),day):return false
 if not People.valid(s.get("people"),day):return false
 var seen={}
 for e in s.events:
  if not e is Dictionary or not integer(e.get("id"),1,s.next-1) or seen.has(e.id) or not integer(e.get("day"),s.since,day):return false
  for field in ["kind","text","thread"]:
   if not e.get(field) is String:return false
  for field in ["people","units","parents"]:
   if not e.get(field) is Array:return false
   for id in e[field]:
    if not integer(id,0,1000000000):return false
    if field=="parents" and not seen.has(id):return false
  seen[e.id]=true
 for id in s.threads.values():
  if not integer(id,1,s.next-1) or not seen.has(id):return false
 return s.next==s.events.size()+1
static func integer(v: Variant,low: int,high: int) -> bool:
 return preload("res://sim/operations.gd").integer(v,low,high)

static func upgrade(s: Dictionary):
 if s.get("revision")==1:
  s["people"]=People.create();s.revision=2
 if s.get("revision")==2:
  s["culture"]=Culture.create();s.revision=3
 if s.get("revision")==3:
  s["objectives"]=Objectives.create();s.revision=4
 if s.get("revision")==4:
  s["society"]=Society.create();s.revision=5

static func valid_links(data: Dictionary) -> bool:
 var s=data.story
 var people=[]
 for p in data.staff+data.alumni:people.append(int(p.id))
 var units=[]
 for m in data.mechs:units.append(int(m.uid))
 for key in s.culture.units:units.append(int(key))
 var events={}
 var threads={}
 for e in s.events:
  if e.id!=events.size()+1:return false
  for id in e.people:
   if not int(id) in people:return false
  for id in e.units:
   if not int(id) in units:return false
  for id in e.parents:
   if events[int(id)].day>e.day:return false
  events[int(e.id)]=e
  if not e.thread.is_empty():threads[e.thread]=e.id
 if threads!=s.threads:return false
 for key in s.people.profiles:
  if not int(key) in people:return false
  for id in s.people.profiles[key].memories:
   if not events.has(int(id)):return false
 for r in s.people.requests:
  if not events.has(int(r.event)) or r.day>data.day or r.expires<r.day:return false
 for key in s.culture.units:
  var u=s.culture.units[key]
  for id in u.events:
   if not events.has(int(id)):return false
  for id in u.pilots:
   if not int(id) in people:return false
 for g in s.objectives.goals:
  if not events.has(int(g.event)) or g.started>data.day or preload("res://sim/universe.gd").system(g.system).is_empty():return false
  if g.kind=="person" and not int(g.person) in people:return false
  if g.kind!="person" and g.person!=-1:return false
  if g.status=="completed" and g.progress!=3:return false
  if g.status=="open" and g.progress==3:return false
 for j in s.objectives.jobs:
  for id in [j.person,j.subject]:
   if id>=0 and not int(id) in people:return false
 for local in s.society.locals.values():
  if not events.has(int(local.event)):return false
  for id in local.memory:
   if not events.has(int(id)):return false
 if not s.society.pending.is_empty() and not events.has(int(s.society.pending.event)):return false
 return true
