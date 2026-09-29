const assert=require('node:assert/strict'),F=require('../dist/engine.js');
const s=F.fresh(),excluded=['warehouse','washer','foreman'];
for(const role of excluded){
  const position=F.positions(s).find(p=>p.role===role).key;
  if(!F.assigned(s,position))assert.ok(F.perform(s,{type:'personnel',action:'hire',position,candidateId:s.hr.candidates[position][0].id}).ok);
  const e=F.assigned(s,position);
  assert.equal(Object.hasOwn(e,'defect'),false);
  e.defect=15;e.salary=27.4;
}
for(const p of F.positions(s))for(const c of s.hr.candidates[p.key]||[]){
  if(excluded.includes(p.role)){assert.equal(Object.hasOwn(c,'defect'),false);c.defect=12;}
  else assert.ok(c.defect>=1&&c.defect<=15);
}
const expected=structuredClone(s.hr.employees).map(e=>{if(excluded.includes(e.role))delete e.defect;return e;});
const restored=F.restore(JSON.stringify(s));
assert.deepEqual(restored.hr.employees,expected);
assert.deepEqual(restored.payroll,s.payroll);
assert.deepEqual(restored.hr.lines,s.hr.lines);
for(const p of F.positions(restored))for(const c of restored.hr.candidates[p.key]||[])if(excluded.includes(p.role)){
  assert.equal(Object.hasOwn(c,'defect'),false);
  assert.equal(c.salary,F.candidateSalary(p.role,undefined,c.absence));
}
assert.deepEqual(F.restore(JSON.stringify(restored)).hr,restored.hr);
console.log('OK removed traits migrate without losing people, salaries or payroll; remaining roles retain quality risk');
