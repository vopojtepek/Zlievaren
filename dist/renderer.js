window.FoundryView={create(canvas,detail){
  const F=window.Foundry,ctx=canvas.getContext('2d'),dc=detail.getContext('2d');
  const positions=[{x:365,y:330},{x:620,y:330},{x:875,y:330},{x:365,y:555},{x:620,y:555},{x:875,y:555}],HOME={x:162,y:268};
  const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches,fmt=n=>Math.round(n).toLocaleString('sk-SK'),roman=['I','II','III'],stages=F.STAGES;
  let state,time=0,hover=-1,area='foundry',selectedBin='iron',cncPower=Array(7).fill(false);
  const cncPositions=[{x:123,y:144},{x:366,y:144},{x:609,y:144},{x:852,y:144},{x:609,y:441},{x:852,y:441},{x:72,y:408,amada:true}];
  function heatColor(temp){
    const points=[[20,[82,102,107]],[400,[109,61,51]],[650,[184,53,33]],[900,[247,96,38]],[1150,[255,157,67]],[1450,[255,233,164]]];
    for(let i=1;i<points.length;i++)if(temp<=points[i][0]){const a=points[i-1],b=points[i],f=Math.max(0,(temp-a[0])/(b[0]-a[0]));return 'rgb('+a[1].map((v,j)=>Math.round(v+(b[1][j]-v)*f)).join(',')+')';}return '#ffe9a4';
  }
  function poly(g,points,fill,stroke){g.beginPath();points.forEach((p,i)=>i?g.lineTo(...p):g.moveTo(...p));g.closePath();if(fill){g.fillStyle=fill;g.fill();}if(stroke){g.strokeStyle=stroke;g.stroke();}}
  function rect(g,x,y,w,h,fill,r=0){g.fillStyle=fill;g.beginPath();g.roundRect(x,y,w,h,r);g.fill();}
  function line(g,x1,y1,x2,y2,color,width=1){g.strokeStyle=color;g.lineWidth=width;g.beginPath();g.moveTo(x1,y1);g.lineTo(x2,y2);g.stroke();g.lineWidth=1;}
  function circle(g,x,y,r,fill,stroke){g.beginPath();g.arc(x,y,r,0,Math.PI*2);if(fill){g.fillStyle=fill;g.fill();}if(stroke){g.strokeStyle=stroke;g.stroke();}}
  function text(g,str,x,y,color='#c6d7cc',size=12,align='center',weight=500){g.fillStyle=color;g.font=weight+' '+size+'px "DM Sans", Arial, sans-serif';g.textAlign=align;g.textBaseline='middle';g.fillText(str,x,y);}
  function glow(g,x,y,r,color,alpha=1){g.save();g.globalAlpha=alpha;const a=g.createRadialGradient(x,y,0,x,y,r);a.addColorStop(0,color);a.addColorStop(1,'transparent');g.fillStyle=a;g.fillRect(x-r,y-r,r*2,r*2);g.restore();}
  function pipe(g,x,y,w,h){rect(g,x+4,y+5,w,h,'#152327',4);rect(g,x,y,w,h,'#576a68',4);rect(g,x+2,y+2,w-4,3,'#83918a',2);for(let i=25;i<w;i+=100)rect(g,x+i,y-3,7,h+6,'#3a4d4d',2);}
  function drawBackground(g){
    const bg=g.createLinearGradient(0,0,0,690);bg.addColorStop(0,'#364846');bg.addColorStop(.27,'#293d3e');bg.addColorStop(.28,'#3b4b48');bg.addColorStop(1,'#263a3c');g.fillStyle=bg;g.fillRect(0,0,1100,690);
    const lightLevel=F.daylight(state),night=1-lightLevel;
    rect(g,0,45,1100,105,'#324745');
    for(let x=25;x<1100;x+=240){rect(g,x,49,170,74,'#1c2e30',2);rect(g,x+4,53,162,65,'#4e6967');const light=g.createLinearGradient(0,53,0,118);light.addColorStop(0,'#8caaa180');light.addColorStop(1,'#385558');g.fillStyle=light;g.fillRect(x+5,54,160,64);for(let j=1;j<4;j++)rect(g,x+j*42,51,4,72,'#294241');rect(g,x,84,170,4,'#294241');}
    for(let x=25;x<1100;x+=240){
      g.save();g.beginPath();g.rect(x+4,53,162,65);g.clip();
      const sky=g.createLinearGradient(0,53,0,118);sky.addColorStop(0,lightLevel>.4?'#628eaa':'#172339');sky.addColorStop(1,lightLevel>.4?'#bfd9cf':'#46546b');g.fillStyle=sky;g.fillRect(x+4,53,162,65);
      if(night>.65){for(let i=0;i<8;i++)circle(g,x+12+(i*37)%148,57+(i*13)%41,.8,'#e4eacb');circle(g,x+119,68,6,'#e0dfbf');}
      else circle(g,x+119,65+Math.abs(F.hour(state)-12)*3,9,'#fff1ba');
      for(let i=0;i<6;i++)rect(g,x+i*32,106-i%3*5,23,18,'#243b43');
      for(let j=1;j<4;j++)rect(g,x+j*42,51,4,72,'#294241');rect(g,x,84,170,4,'#294241');g.restore();
    }
    for(let x=0;x<1200;x+=120){line(g,x,153,x+180,690,'#70817a13');line(g,0,190+x*.44,1100,190+x*.44,'#89958b13');}
    for(let x=0;x<1100;x+=225){rect(g,x+2,0,17,180,'#1c3032');rect(g,x+5,0,4,178,'#496160');}
    pipe(g,0,135,1100,10);pipe(g,15,165,1090,8);
    rect(g,0,184,1100,8,'#172d30');rect(g,0,192,1100,3,'#697568');
    // Overhead casting rail and hanging feed lines.
    rect(g,0,19,1100,13,'#a7874b');rect(g,0,22,1100,3,'#d4b365');rect(g,0,33,1100,5,'#14292b');
    for(let i=0;i<15;i++)line(g,i*78+13,20,i*78+26,30,'#564c34',3);
    rect(g,470,17,80,22,'#4b6867',3);circle(g,485,34,5,'#1b2a2e');circle(g,535,34,5,'#1b2a2e');
    line(g,510,40,510,77,'#203436',4);circle(g,510,80,7,null,'#9ba991');
    // Power conduits and safe walking lane.
    for(const y of [370,601]){g.save();g.setLineDash([17,10]);line(g,230,y,1035,y,'#c0a06355',2);g.restore();}
    line(g,215,202,215,645,'#c0a06350',2);
    text(g,'ODLIEVACIA HALA',641,656,'#789491',12,'center',600);
    drawFurnace(g);
    drawStock(g);
    // Floor drain and small foundry worker for scale.
    rect(g,50,566,120,18,'#192f31',3);for(let i=0;i<13;i++)line(g,56+i*8,568,52+i*8,581,'#42615d',2);

    const vignette=g.createRadialGradient(570,360,240,570,360,700);vignette.addColorStop(0,'transparent');vignette.addColorStop(1,'#061d2448');g.fillStyle=vignette;g.fillRect(0,0,1100,690);
  }
  function drawStock(g){
    text(g,'VSÁDZKA · '+F.used(state,'raw')+' / '+F.capacity(state,'raw')+' kg',101,393,'#c8d4c6',10);
    Object.entries(F.MATERIALS).forEach(([id,material],i)=>{
      const x=27+i*31,n=state.raw[id];rect(g,x,409,27,27,'#233a3e',2);rect(g,x+2,412,23,21,'#142b30');
      if(n){for(let k=0;k<Math.min(8,Math.ceil(n/4));k++)poly(g,[[x+3+k%3*7,430-Math.floor(k/3)*6],[x+8+k%3*7,422-Math.floor(k/3)*6],[x+12+k%3*7,430-Math.floor(k/3)*6]],material.color);}
      rect(g,x,432,27,4,'#71837a');text(g,id==='zinc'?'Zn':material.short.slice(0,2).toUpperCase(),x+13,444,material.color,8);text(g,String(n),x+13,457,'#d1ddd6',10);
    });
    rect(g,29,498,145,5,'#7b8772');rect(g,29,526,145,5,'#7b8772');rect(g,29,478,5,57,'#4e6a67');rect(g,169,478,5,57,'#4e6a67');
    Object.entries(F.PRODUCTS).filter(([,p])=>!p.finished).forEach(([id,p],i)=>{
      const x=48+i*36,count=state.goods[id],r=id==='ring'?11:id==='bronze_bushing'?8:9;
      g.save();g.globalAlpha=count?1:.17;rect(g,x-r,483,r*2,13,p.color,2);circle(g,x,491,r,p.color);circle(g,x,491,id==='bronze_bushing'?3:6,'#142d34');g.restore();text(g,p.code+' '+count,x,516,count?p.color:'#718a87',9);
    });
    text(g,'VÝROBKY · '+F.used(state,'goods')+' / '+F.capacity(state,'goods')+' ks',102,548,'#b4c7bd',10);
    if(!reduced){
      const feeding=state.machines.find(m=>m?.state==='working'&&m.elapsed<F.FLOW.spinup);
      if(feeding){const p=feeding.elapsed/F.FLOW.spinup,x=104,y=413-184*p;rect(g,x-14,y-8,28,16,'#a5b5a3',3);text(g,'VSÁDZKA',x,y,'#233a3e',6);}
      const entry=state.ledger.find(l=>l.type==='stock'&&l.text.startsWith('+1 ')),age=entry?state.clock-entry.clock:9;
      if(age>=0&&age<3){const slot=Number(entry.text.match(/stroj (\d)/)?.[1]||1)-1,p=positions[slot],progress=age/3,x=p.x+(101-p.x)*progress,y=p.y+(491-p.y)*progress;glow(g,x,y,20,'#94d5c2',.2);circle(g,x,y,8,'#b8cec3');circle(g,x,y,4,'#17383d');}
    }
  }
  function drawAmbient(g){
    const night=1-F.daylight(state);rect(g,0,0,1100,690,'rgba(8,17,38,'+(night*.36)+')');
    for(const x of [365,620,875]){
      if(night>.2){const beam=g.createLinearGradient(0,42,0,385);beam.addColorStop(0,'rgba(255,216,153,'+(night*.13)+')');beam.addColorStop(1,'transparent');poly(g,[[x-15,43],[x+15,43],[x+104,380],[x-104,380]],beam);glow(g,x,55,53,'#ffcf8a',night*.3);}
      rect(g,x-20,39,40,8,'#20383e',3);rect(g,x-16,46,32,3,night>.3?'#ffe0a9':'#b9c9b8',2);
    }
    glow(g,106,211,75,'#ff9737',.14+night*.18);
    const elapsed=state.clock-state.shiftChangedAt;
    if(state.shiftChanges&&elapsed<8){const p=clamp(elapsed/8),oldBusy=state.delivery?.crew===state.previousShift;
      const outgoing=F.profile(F.assigned(state,F.positionKey('ladle',state.previousShift))),incoming=F.profile(F.duty(state,'ladle'));if(!oldBusy&&outgoing)worker(g,985+145*p,651,true,1,false,1,outgoing);
      if(incoming)worker(g,1090-136*p,628,true,1,false,-1,incoming);
      rect(g,838,666,235,18,'#11262ee8',4);text(g,incoming?incoming.name+' preberá smenu':'PANVÁR CHÝBA · KANCELÁRIA',955,676,'#dfd6b4',10);
    }
  }
  function furnaceTilt(){
    const d=state.delivery,m=d?state.machines[d.slot]:null;if(!m||d.returnElapsed!==null||F.stage(m)!=='loading')return 0;
    const p=clamp((m.elapsed-F.FLOW.spinup)/(F.FLOW.loadEnd-F.FLOW.spinup));return .52*Math.sin(p*Math.PI);
  }
  function furnaceSpout(){const a=furnaceTilt(),dx=61,dy=-12;return {x:73+dx*Math.cos(a)-dy*Math.sin(a),y:234+dx*Math.sin(a)+dy*Math.cos(a)};}
  function drawFurnace(g){
    const pouring=state.machines.some(m=>F.stage(m)==='pouring'),pulse=reduced?1:1+Math.sin(time*2.2)*.07;
    glow(g,105,242,94,'#ff932f',pulse*(pouring?.16:.33));g.save();g.translate(98,320);
    ellipse(g,10,10,64,18,'#102a2c66');
    // A squat cube with a refractory volcano-shaped outlet in the centre of its top.
    rect(g,-42,-76,84,76,'#747b68',3);poly(g,[[42,-76],[62,-94],[62,-18],[42,0]],'#405755','#193638');poly(g,[[-42,-76],[-22,-94],[62,-94],[42,-76]],'#a4a18a','#526b61');
    line(g,-41,-74,39,-74,'#d0c39a',2);rect(g,-37,-68,74,55,'#626e5e',2);
    for(let j=0;j<3;j++){line(g,-36,-52+j*16,35,-52+j*16,'#88907a',1);for(let i=0;i<3;i++)line(g,-27+i*29+(j%2)*12,-66+j*16,-27+i*29+(j%2)*12,-54+j*16,'#4b6256',1);}
    rect(g,-30,-12,60,10,'#2b4842',2);text(g,'PEC 01',0,-7,'#cbd3b5',9,'center',600);rect(g,-35,0,11,7,'#1c3536');rect(g,29,0,11,7,'#1c3536');
    const lidTilt=furnaceTilt();ellipse(g,9,-83,35,13,'#ffbb6555');circle(g,-25,-86,5,'#c7c7a7');g.save();g.translate(-25,-86);g.rotate(lidTilt);g.translate(25,86);
    ellipse(g,9,-83,35,13,'#6d7160');
    poly(g,[[-27,-84],[-16,-101],[-8,-112],[24,-112],[32,-101],[44,-84],[28,-76],[-10,-76]],'#a29b80','#c5b692');
    poly(g,[[-27,-84],[-16,-101],[-8,-112],[2,-108],[-5,-87],[-10,-76]],'#bbb08e');poly(g,[[24,-112],[32,-101],[44,-84],[28,-76],[19,-88]],'#7c7c65');
    line(g,-8,-95,-14,-83,'#6d7560',2);line(g,26,-99,31,-87,'#bbb08b',2);
    ellipse(g,8,-111,20,8,'#544b3b');ellipse(g,8,-112,16,5.7,'#ff9b38');ellipse(g,8,-113,11,3.5,'#ffe094');
    glow(g,8,-111,34,'#ffb44e',pouring?.45:.7);
    if(!pouring){for(let i=0;i<3;i++){const a=(time*.5+i/3)%1;g.globalAlpha=(1-a)*.14;ellipse(g,8+Math.sin(time+i)*6,-123-a*34,11+a*13,4+a*4,'#f7cca1');}g.globalAlpha=1;}
    poly(g,[[23,-109],[35,-102],[40,-97],[32,-97],[17,-108]],'#a99976');line(g,24,-106,36,-98,'#ffbd64',2);
    g.restore();line(g,-37,-62,-25,-86,'#a9b7a2',4);circle(g,-37,-62,5,'#768b82');
    const product=state.delivery?F.PRODUCTS[state.machines[state.delivery.slot].product]:null;
    g.restore();drawFurnaceWorker(g);text(g,'TAVENINA',112,344,'#bbcab8',11);text(g,fmt(product?.temp||1700)+' °C',112,364,'#ffbd78',18,'center',600);
  }
  function ellipse(g,x,y,rx,ry,fill,stroke){g.beginPath();g.ellipse(x,y,rx,ry,0,0,Math.PI*2);if(fill){g.fillStyle=fill;g.fill();}if(stroke){g.strokeStyle=stroke;g.stroke();}}
  function worker(g,x,y,small=false,walk=0,handling=false,facing=1,crew=F.CREWS[F.shift(state)]){
    g.save();g.translate(x,y);g.scale((small?.85:handling?1.45:1)*facing,small?.85:handling?1.45:1);ellipse(g,0,4,17,6,'#142a2c55');
    const step=walk&&!reduced?Math.sin(time*11)*5:0;
    line(g,-6,-19,-8+step,0,'#203938',8);line(g,6,-19,8-step,0,'#203938',8);rect(g,-13+step,-2,12,6,'#172e30',2);rect(g,3-step,-2,12,6,'#172e30',2);
    rect(g,-12,-38,25,25,crew.color,5);rect(g,-15,-37,6,18,crew.color,3);line(g,13,-34,handling?25:16,handling?-32:-18,'#d1a465',6);rect(g,-10,-27,22,3,'#e9d6a9');rect(g,-3,-37,6,23,'#d0a66b');circle(g,1,-45,10,'#cab995');rect(g,-12,-50,27,6,crew.helmet,3);circle(g,1,-52,10,crew.helmet);rect(g,-9,-49,21,3,'#f1d17a');rect(g,-5,-45,14,4,'#425850',2);g.restore();
  }
  function drawOperator(g,p,i){
    const m=state.machines[i];if(!m)return;
    const count=Object.values(state.pallets[i]).reduce((a,b)=>a+b,0),x=p.x+112,y=p.y+18;
    ellipse(g,x,y+8,34,11,'#10242988');
    poly(g,[[x-27,y-8],[x+20,y-17],[x+34,y-4],[x-13,y+6]],'#778c8d','#c0cacc');
    poly(g,[[x-27,y-8],[x-13,y+6],[x-13,y+13],[x-27,y-1]],'#364e54');
    poly(g,[[x-13,y+6],[x+34,y-4],[x+34,y+3],[x-13,y+13]],'#4c646b');
    for(let k=0;k<4;k++)line(g,x-22+k*12,y-9-k*2,x-9+k*12,y+4-k*2,'#32494e',3);
    rect(g,x-20,y+3,6,12,'#293d44');rect(g,x+24,y-4,6,12,'#293d44');
    const ids=Object.keys(state.pallets[i]).filter(id=>state.pallets[i][id]);
    for(let k=0;k<Math.min(3,count);k++){const id=ids[k%ids.length],yy=y-12-k*8;rect(g,x-22,yy-7,39,9,F.PRODUCTS[id].color,3);ellipse(g,x-21,yy-2,5,6,'#c2d0cc');ellipse(g,x-21,yy-2,2.7,3.7,'#1c333b');line(g,x-16,yy-6,x+14,yy-6,'#d4dfdf',1);}
    text(g,count+' ks',x+5,y+24,'#c7d4cd',10);
    const unloading=m.state==='unloading',crew=unloading?F.profile(F.employee(state,m.unloadEmployeeId)):F.operator(state,i);
    text(g,crew?crew.name:'BEZ OBSLUHY',p.x-2,p.y+61,crew?'#bbd7d0':'#eca990',10);
    if(!crew)return;
    const t=unloading?Math.min(1,m.unloadElapsed/F.UNLOAD_SECONDS):0,travel=unloading?Math.sin(Math.min(1,t*1.25)*Math.PI/2):0,wx=p.x+57+travel*40,wy=p.y+18;
    worker(g,wx,wy,true,unloading?1:0,false,unloading?1:-1,crew);
    if(unloading){const lift=Math.min(1,t*5),py=wy-20-lift*5;rect(g,wx-22,py,43,11,F.PRODUCTS[m.product].color,3);line(g,wx-20,py+2,wx+18,py+2,'#dee4df',2);ellipse(g,wx-22,py+5,5,7,'#b8c9ca');ellipse(g,wx-22,py+5,2.6,4.5,'#203943');line(g,wx-11,wy-23,wx-8,py+10,'#dbc09a',4);line(g,wx+10,wy-23,wx+12,py+10,'#dbc09a',4);}
  }
  function drawForeman(g){
    // A regular patrol, with a short stop at either end of the walkway.
    const master=F.profile(F.duty(state,'foreman'));if(!master)return;const masterIndex=master.appearance||0;
    const phase=reduced?5:time%24,walking=phase<10||phase>=12&&phase<22;
    const progress=phase<10?phase/10:phase<12?1:phase<22?1-(phase-12)/10:0;
    const x=270+progress*750,y=641,facing=phase<12?1:-1,step=walking&&!reduced?Math.sin(time*13)*5:0;
    ellipse(g,x,y+3,24,7,'#10222a70');g.save();g.translate(x,y);g.scale(1.12*facing,1.12);g.translate(0,walking&&!reduced?-Math.abs(Math.sin(time*13))*.9:0);
    if(masterIndex===0){
    // Black trousers, boots and a loose hoodie with the hood down.
    line(g,-6,-21,-8+step,0,'#11151b',9);line(g,6,-21,8-step,0,'#171b21',9);
    line(g,-8,-19,-9+step,-4,'#363b43',1.2);line(g,8,-19,9-step,-4,'#363b43',1.2);
    rect(g,-15+step,-2,15,6,'#0a1016',2);rect(g,3-step,-2,15,6,'#0a1016',2);line(g,-14+step,3,-1+step,3,'#617078',1);line(g,4-step,3,17-step,3,'#617078',1);
    line(g,-13,-39,-16-step*.65,-19,'#10141a',9);line(g,13,-39,17+step*.65,-20,'#20252d',9);
    circle(g,-16-step*.65,-17,3,'#c29d7c');circle(g,17+step*.65,-18,3,'#c29d7c');
    rect(g,-14,-43,29,28,'#12161c',6);line(g,-13,-36,-12,-20,'#4b535d',1);line(g,14,-36,13,-20,'#49515a',1);rect(g,-10,-21,20,3,'#242b34',2);
    ellipse(g,0,-43,16,10,'#292c32','#535862');ellipse(g,0,-44,11,6,'#101419');
    // A silver, thorn-like black-metal print, visible around the beard.
    for(const side of [-1,1]){line(g,side*2,-33,side*11,-37,'#c4c9ca',1);line(g,side*4,-31,side*11,-30,'#e2e6df',1);line(g,side*7,-35,side*10,-41,'#c4c9ca',.8);line(g,side*7,-32,side*11,-27,'#c4c9ca',.8);}
    line(g,-5,-24,5,-24,'#979f9f',1);line(g,-6,-40,-7,-34,'#b5b9b9',.8);line(g,7,-40,8,-34,'#b5b9b9',.8);
    // Dark brown hair hangs over both shoulders; the beard reaches the chest.
    ellipse(g,0,-51,13,14,'#201c1c');poly(g,[[-12,-53],[-14,-37],[-10,-30],[-6,-34],[-6,-55]],'#292020');poly(g,[[8,-55],[13,-51],[15,-32],[10,-29],[6,-40]],'#231e1f');
    ellipse(g,1,-49,8,10,'#c6a182');poly(g,[[-9,-57],[-2,-64],[8,-60],[12,-53],[7,-51],[4,-57],[-4,-51],[-8,-45]],'#211d1e');
    line(g,-11,-52,-11,-35,'#49352e',1.3);line(g,11,-51,12,-34,'#49362e',1);
    line(g,-5,-50,-1,-50,'#171d24',1.4);line(g,4,-50,8,-50,'#171d24',1.4);line(g,2,-49,3,-45,'#987758',1);
    poly(g,[[-7,-46],[-3,-44],[2,-45],[6,-44],[10,-46],[9,-35],[5,-25],[1,-22],[-4,-29],[-8,-36]],'#0b1016');line(g,-4,-39,-1,-27,'#2c3036',1);line(g,6,-40,4,-30,'#2d3036',1);line(g,-4,-44,1,-45,'#0a1016',2);line(g,1,-45,7,-43,'#0a1016',2);
    }else{
      // Miro: grey trousers, a blue hoodie and a round, clean-shaven bald face.
      line(g,-7,-21,-9+step,0,'#727b85',10);line(g,7,-21,9-step,0,'#939aa1',10);
      line(g,-9,-18,-11+step,-5,'#b0b5b8',1);line(g,9,-18,10-step,-5,'#c3c6c6',1);
      rect(g,-16+step,-2,16,6,'#1d2933',2);rect(g,4-step,-2,16,6,'#182730',2);line(g,-15+step,3,-2+step,3,'#8a999f',1);line(g,5-step,3,18-step,3,'#8a999f',1);
      line(g,-15,-38,-18-step*.65,-19,'#35699b',10);line(g,15,-38,19+step*.65,-20,'#568fc1',10);
      circle(g,-18-step*.65,-17,3.5,'#dbb395');circle(g,19+step*.65,-18,3.5,'#dbb395');
      rect(g,-17,-44,35,30,'#397bae',7);line(g,-15,-36,-14,-20,'#83b8d7',1.3);line(g,16,-36,15,-20,'#639ec7',1.3);rect(g,-12,-19,25,4,'#2c6697',2);
      ellipse(g,0,-43,17,10,'#558cb6','#89b8d4');ellipse(g,0,-44,11,6,'#24577f');
      poly(g,[[-9,-28],[-5,-33],[6,-33],[10,-28],[9,-22],[-8,-22]],'#306a9b','#689ac0');line(g,-6,-41,-7,-33,'#d0d9d3',1);line(g,7,-41,8,-33,'#d0d9d3',1);
      rect(g,-5,-44,12,7,'#cda587',3);ellipse(g,-12,-50,3,5,'#c59a80');ellipse(g,13,-50,3,5,'#d4ad90');
      ellipse(g,0,-52,13,15,'#deb596');ellipse(g,-8,-46,6,7,'#deb194');ellipse(g,8,-46,6,7,'#e6ba9b');
      ellipse(g,-3,-61,6,3,'#edc9a9');line(g,-8,-55,-3,-55,'#8f715d',1.3);line(g,3,-55,8,-55,'#8f715d',1.3);
      circle(g,-5,-52,1.1,'#303c43');circle(g,6,-52,1.1,'#303c43');line(g,1,-51,2,-47,'#b68c71',1.2);ellipse(g,2,-46,2.5,1.5,'#d3a287');
      ellipse(g,-8,-47,3.5,2,'#dfa88e');ellipse(g,8,-47,3.5,2,'#e4ab8f');line(g,-3,-42,5,-42,'#a77565',1.1);ellipse(g,1,-39,5,2,'#e3bb9d');
    }
    g.restore();rect(g,x-56,y+8,112,17,'#121e27ef',4);text(g,master.name,x,y+16.5,masterIndex?'#c2e0fb':'#e0cfb0',10,'center',600);
  }
  const clamp=(n,a=0,b=1)=>Math.max(a,Math.min(b,n));
  function deliveryRoute(slot){const p=positions[slot],target={x:p.x-65,y:p.y-114},aisle=p.y+58-142;return [HOME,{x:226,y:HOME.y},{x:226,y:aisle},{x:target.x,y:aisle},target];}
  function pointOnRoute(points,progress){
    const lengths=points.slice(1).map((p,i)=>Math.hypot(p.x-points[i].x,p.y-points[i].y));let distance=lengths.reduce((a,b)=>a+b,0)*clamp(progress);
    for(let i=0;i<lengths.length;i++){if(distance<=lengths[i]&&lengths[i]>0){const f=distance/lengths[i];return {x:points[i].x+(points[i+1].x-points[i].x)*f,y:points[i].y+(points[i+1].y-points[i].y)*f};}distance-=lengths[i];}
    return points[points.length-1];
  }
  function stream(g,from,to,width=5){
    const grad=g.createLinearGradient(from.x,from.y,to.x,to.y);grad.addColorStop(0,'#ffefb0');grad.addColorStop(.65,'#ffc36b');grad.addColorStop(1,'#ff8c36');
    g.save();g.shadowColor='#ff9a3b';g.shadowBlur=9;g.lineWidth=width;g.strokeStyle=grad;g.beginPath();g.moveTo(from.x,from.y);g.quadraticCurveTo((from.x+to.x)/2,from.y+3,to.x,to.y);g.stroke();g.lineWidth=width*.35;g.strokeStyle='#fff1b8';g.stroke();g.restore();
    if(!reduced)for(let k=0;k<5;k++){const a=(time*1.7+k*.2)%1;circle(g,to.x+Math.sin(k*2.3)*a*17,to.y-a*18+a*a*15,(1-a)*1.6+.4,'#ffd693');}
  }
  function drawLadle(g,p,tilt,fill,preview=false){
    const railY=preview?4:28;
    // Travelling hoist, twin suspension cables, fixed yoke, and a tilting vessel.
    rect(g,p.x-22,railY,44,15,'#a58b51',3);rect(g,p.x-17,railY+3,34,4,'#d3b16b',2);circle(g,p.x-13,railY+15,4,'#233d3d');circle(g,p.x+13,railY+15,4,'#233d3d');
    line(g,p.x-3,railY+18,p.x-3,p.y-62,'#b1b4a0',1.8);line(g,p.x+3,railY+18,p.x+3,p.y-62,'#647e75',1.8);rect(g,p.x-8,p.y-63,16,13,'#58736b',3);circle(g,p.x,p.y-46,6,null,'#d0c7a3');
    line(g,p.x,p.y-42,p.x-31,p.y-8,'#93a396',3);line(g,p.x,p.y-42,p.x+31,p.y-8,'#93a396',3);line(g,p.x-31,p.y-8,p.x-31,p.y+1,'#93a396',3);line(g,p.x+31,p.y-8,p.x+31,p.y+1,'#93a396',3);
    if(fill>0)glow(g,p.x,p.y-14,45,'#ffa33f',.25*fill);
    g.save();g.translate(p.x,p.y);g.rotate(tilt);
    const body=g.createLinearGradient(-26,0,27,0);body.addColorStop(0,'#829087');body.addColorStop(.4,'#596c66');body.addColorStop(1,'#304b4b');
    poly(g,[[-27,-17],[27,-17],[20,21],[11,26],[-12,26],[-21,20]],body,'#b1b69b');ellipse(g,0,-17,27,10,'#c1b899','#586a5c');ellipse(g,0,-17,22,7,'#463f34');
    if(fill>0){g.save();g.beginPath();g.ellipse(0,-17,21,6.7,0,0,Math.PI*2);g.clip();ellipse(g,-2,-11-6*fill,23,6.5,'#ffba59');ellipse(g,-4,-14-4*fill,15,3,'#ffe19a');g.restore();}
    line(g,-20,-6,-16,17,'#b2b496',2);line(g,-16,20,16,20,'#2e4945',3);poly(g,[[21,-22],[33,-20],[34,-13],[24,-10]],'#b7ac86','#5e725f');if(fill>0)line(g,22,-17,32,-16,'#ffcd7a',2);
    circle(g,-29,0,4,'#d2caab');circle(g,29,0,4,'#d2caab');g.restore();
    return {x:p.x+34*Math.cos(tilt)+16*Math.sin(tilt),y:p.y+34*Math.sin(tilt)-16*Math.cos(tilt)};
  }
  function deliveryPose(){
    const d=state.delivery;if(!d)return {p:HOME,fill:0,tilt:0,walking:false,stage:'idle',crewProgress:0};
    const m=state.machines[d.slot],route=deliveryRoute(d.slot),end=route[route.length-1];
    if(d.returnElapsed!==null)return {p:pointOnRoute([...route].reverse(),d.returnElapsed/F.FLOW.returnTime),fill:0,tilt:0,walking:true,stage:'returning',crewProgress:1-clamp(d.returnElapsed/F.FLOW.returnTime)};
    const stage=F.stage(m);
    if(stage==='loading')return {p:HOME,fill:clamp((m.elapsed-F.FLOW.spinup)/(F.FLOW.loadEnd-F.FLOW.spinup)),tilt:0,walking:false,stage,crewProgress:0};
    if(stage==='carrying')return {p:pointOnRoute(route,(m.elapsed-F.FLOW.loadEnd)/(F.FLOW.carryEnd-F.FLOW.loadEnd)),fill:1,tilt:reduced?0:Math.sin(time*3)*.035,walking:true,stage,crewProgress:clamp((m.elapsed-F.FLOW.loadEnd)/(F.FLOW.carryEnd-F.FLOW.loadEnd))};
    const progress=clamp((m.elapsed-F.FLOW.carryEnd)/(F.FLOW.pourEnd-F.FLOW.carryEnd)),tilt=.86*Math.min(clamp(progress/.18),clamp((1-progress)/.13));
    return {p:end,fill:1-clamp((progress-.1)/.82),tilt,walking:false,stage,flow:progress>.1&&progress<.92,crewProgress:1};
  }
  function drawTransport(g){
    const pose=deliveryPose(),p=pose.p,person=F.profile(state.delivery?F.employee(state,state.delivery.employeeId):F.duty(state,'ladle'));if(!person){drawLadle(g,p,0,0);return;}
    ellipse(g,p.x,p.y+136,43,10,'#142a2c38');
    const t=pose.crewProgress,crew={x:p.x+48-99*t,y:p.y+86+56*t},facing=t<.5?-1:1,hand={x:crew.x+36*facing,y:crew.y-46},operator=person;line(g,p.x+27-54*t,p.y+2,hand.x,hand.y,'#b4ab8a',3);worker(g,crew.x,crew.y,false,pose.walking,true,facing,operator);circle(g,hand.x,hand.y,4,'#d8bf8e');
    rect(g,crew.x-31,crew.y+13,62,17,'#14292edd',4);text(g,operator.name,crew.x,crew.y+22,'#d6ddd5',10);
    const lip=drawLadle(g,p,pose.tilt,pose.fill);
    if(pose.stage==='loading')stream(g,furnaceSpout(),{x:p.x-4,y:p.y-18},4);
    if(pose.stage==='pouring'&&pose.flow){const target=positions[state.delivery.slot];stream(g,lip,{x:target.x-7,y:target.y-82},5);}
  }
  function drawSlot(g,p,index){
    const selected=state.selected===index,over=hover===index,m=state.machines[index];g.save();g.translate(p.x,p.y);
    const floor=[[-91,22],[69,22],[110,-8],[-51,-8]];poly(g,floor,selected?'#81988023':'#b0b99808',selected?'#bdd6a58a':'#90aaa14a');
    if(!m){g.save();g.setLineDash([7,6]);g.strokeStyle=selected?'#b9d5b0':over?'#d0d8c1':'#7a9a916b';g.lineWidth=2;g.beginPath();g.moveTo(-64,4);g.lineTo(63,4);g.lineTo(89,-17);g.lineTo(-36,-17);g.closePath();g.stroke();g.restore();
      circle(g,10,-64,25,selected?'#aac8ae18':'#425c532c',selected?'#b3ceb08a':'#7f9e8c55');line(g,-1,-64,21,-64,selected?'#c1d9b9':'#829e91',2);line(g,10,-75,10,-53,selected?'#c1d9b9':'#829e91',2);text(g,'MIESTO '+String(index+1).padStart(2,'0'),10,-22,'#a3b9a9',11);text(g,F.price(state)+' ₵',10,49,selected?'#c1d9b4':'#86a595',13);}
    g.restore();if(m)drawMachine(g,p.x,p.y,m,index,1,selected||over);
  }
  function drawCooling(g,m,index){
    const active=F.stage(m)==='cooling',clock=reduced?index*.29:time+index*.29;
    g.save();g.beginPath();g.roundRect(-36,-125,61,89,3);g.clip();
    // Two fixed nozzles sit inside the cabinet, above the rotating mould.
    line(g,-32,-120,19,-120,'#354f59',4);line(g,-32,-121,19,-121,'#8caeb7',1.2);
    const nozzles=[{x:-30,y:-110,hitX:-25,hitY:-97,side:-1},{x:18,y:-110,hitX:11,hitY:-97,side:1}];
    nozzles.forEach((n,j)=>{
      line(g,n.x,-120,n.x,-114,'#70949f',3);
      poly(g,[[n.x-3,-116],[n.x+3,-116],[n.x+2,-110],[n.x-2,-110]],'#9bbec7','#304b55');
      ellipse(g,n.x,-110,2.5,1.2,active?'#caf7ff':'#243e48');
      if(!active)return;
      // Fine spray fans and moving bright streaks, all clipped behind the glass.
      for(let jet=0;jet<3;jet++){
        const endX=n.hitX+(jet-1)*3.3,endY=n.hitY+(jet-1)*1.6;
        line(g,n.x,n.y,endX,endY,'#80dff887',1.25);
        for(let drop=0;drop<3;drop++){
          const p=(clock*2.9+drop/3+jet*.17+j*.31)%1,q=Math.max(0,p-.18);
          line(g,n.x+(endX-n.x)*q,n.y+(endY-n.y)*q,n.x+(endX-n.x)*p,n.y+(endY-n.y)*p,'#d7faff',1.3);
        }
      }
      for(let k=0;k<6;k++){
        const age=(clock*1.7+k/6+j*.21)%1,dx=n.side*(3+k%3*2),px=n.hitX+dx*age,py=n.hitY-5*Math.sin(age*Math.PI)+38*age*age;
        g.globalAlpha=(1-age)*.78;line(g,px,py,px-n.side*.6,py+2.2,'#98e7ff',1.25);
      }
      g.globalAlpha=1;ellipse(g,n.hitX,n.hitY,4.3,2,'#c7f6ff66');
    });
    if(active){
      const heat=clamp((F.temperature(m)-180)/1100),steamStrength=.025+heat*.19;
      for(let i=0;i<7;i++){
        const age=(clock*.58+i/7)%1,px=-8+Math.sin(i*2.3+clock*.3)*15,py=-91-age*30;
        g.globalAlpha=Math.sin(age*Math.PI)*steamStrength;ellipse(g,px,py,6+age*9,4+age*6,'#d8f2f4');
      }
      g.globalAlpha=1;
      // Runoff collects in the internal drip tray instead of escaping the cabinet.
      ellipse(g,-7,-39,26,2.5,'#75cae55c');
      for(let i=0;i<3;i++){const phase=(clock*1.1+i/3)%1;g.globalAlpha=(1-phase)*.42;ellipse(g,-22+i*16,-39,1+phase*5,.6+phase,null,'#b4eeff');}
      g.globalAlpha=1;
    }
    g.restore();
  }
  function drawMachine(g,x,y,m,index,scale=1,selected=false,preview=false){
    g.save();g.translate(x,y);g.scale(scale,scale);
    const stage=F.stage(m),failed=m.state==='failed',working=m.state==='working'||failed,ready=m.state==='ready'||m.state==='unloading',temp=F.temperature(m),hasMetal=ready&&!(m.state==='unloading'&&m.unloadElapsed>.7)||working&&m.elapsed>F.FLOW.carryEnd,hot=working?Math.max(0,(temp-430)/1020):0;
    const body=m.level===1?'#647e78':m.level===2?'#64858a':'#879181',side=m.level===1?'#3c5957':m.level===2?'#385d64':'#536961',top=m.level===1?'#8ca195':m.level===2?'#8eaeb0':'#b4bda2';
    g.fillStyle='#0b252851';g.beginPath();g.ellipse(16,14,80,20,0,0,Math.PI*2);g.fill();
    if(hot>0)glow(g,0,-37,107,'#ff983f',hot*.15);if(ready)glow(g,0,-43,91,'#bbe58f',.07);
    rect(g,-51,-7,15,22,'#253d3c',3);rect(g,37,-7,15,22,'#253d3c',3);rect(g,-50,-5,13,4,'#a1ab8c');rect(g,38,-5,13,4,'#a1ab8c');
    poly(g,[[55,-151],[80,-169],[80,-13],[55,5]],side,'#172e31');poly(g,[[-55,-151],[-30,-169],[80,-169],[55,-151]],top,'#48605a');rect(g,-55,-151,110,156,body,4);line(g,-53,-148,51,-148,'#c5cfaa77',2);
    rect(g,-43,-133,73,105,'#344b49',4);rect(g,-39,-129,65,98,'#12292d',3);rect(g,-35,-124,57,87,'#1b3437',4);
    // Rotating tube: its lit circumference, bore, and moving rim marks are temperature driven.
    const product=F.PRODUCTS[m.product||'iron_pipe'],bore=m.product==='bronze_bushing'?10:m.product==='ring'?19:15;
    const cy=-82,cx=-7,angle=working?stage==='spinup'?m.elapsed*m.elapsed*2.2:time*(stage==='cooling'?2:7):.4;
    if(hot>0)glow(g,cx,cy,52,heatColor(temp),hot*.36);
    circle(g,cx,cy,30,'#14282c','#799387');circle(g,cx,cy,27,'#59706b');
    const metalColor=ready||temp<400?product.color:heatColor(temp),ring=g.createRadialGradient(cx-7,cy-10,4,cx,cy,26);ring.addColorStop(0,hasMetal?metalColor:'#b3c2b0');ring.addColorStop(.67,hasMetal?metalColor:'#8da398');ring.addColorStop(1,hasMetal&&temp>=400?heatColor(temp*.84):'#647f76');
    g.save();g.shadowColor=heatColor(temp);g.shadowBlur=hot*13;circle(g,cx,cy,25,ring);g.restore();
    circle(g,cx,cy,bore,hasMetal&&temp>400?'#502e24':'#122d32');circle(g,cx+1,cy+2,bore-4,'#112b30');
    if(working&&temp>850){g.save();g.globalAlpha=(temp-850)/600;circle(g,cx-2,cy-3,15,'#ffab5955');g.restore();circle(g,cx+1,cy+2,10,'#402d24');}
    g.save();g.translate(cx,cy);g.rotate(angle);circle(g,21,0,2.4,hasMetal?'#ffefbb':'#e3e5ce');for(let k=0;k<6;k++){g.rotate(Math.PI/3);line(g,18,0,24,0,hasMetal?'#ffe9b199':'#d0dbc488',2);}g.restore();
    rect(g,-32,-46,51,5,'#53695c',2);rect(g,-25,-43,8,8,'#152e31');rect(g,4,-43,8,8,'#152e31');
    drawCooling(g,m,index);
    // The full-height hinged door opens for loading/unloading; closed door has an inspection window.
    if(m.state==='idle'||ready){
      poly(g,[[-43,-134],[-78,-144],[-78,-40],[-43,-29]],'#718980','#c3cba366');poly(g,[[-48,-124],[-72,-131],[-72,-53],[-48,-44]],'#263e3f','#a3b99a44');line(g,-69,-91,-69,-78,'#b8c9ac',3);rect(g,-47,-117,6,13,'#a8b599',2);rect(g,-47,-51,6,13,'#a8b599',2);
    }else{
      rect(g,-45,-135,78,8,'#8aa08f',2);rect(g,-45,-35,78,8,'#506f67',2);rect(g,-45,-133,8,104,'#8aa08f',2);rect(g,25,-131,8,100,'#486961',2);rect(g,28,-87,4,24,'#c2ccac',2);line(g,-30,-117,19,-52,'#bfdfc70d',5);line(g,-21,-120,22,-61,'#d2f4d909',9);
    }
    rect(g,36,-133,13,45,'#2c4849',2);rect(g,38,-128,9,15,'#102e32',2);text(g,String(m.level),42.5,-120,'#bae4b2',9);circle(g,42,-101,4,stage==='cooling'?'#8ce3ff':working?'#ffb766':ready?'#c7e8a0':'#94b495');circle(g,42,-77,6,'#2b4444','#a5b69c');circle(g,42,-77,3,'#c48156');
    rect(g,-44,-20,64,10,'#254443',2);text(g,'CENTRA · '+roman[m.level-1],-12,-15,'#b5c6af',8,'center',600);rect(g,27,-20,21,10,'#bdad6b',1);text(g,'⚡',37,-15,'#393e2a',9);
    for(let j=0;j<5;j++)line(g,62,-115+j*6,73,-123+j*6,'#192f34',2);
    [[-49,-143],[48,-143],[-49,-3],[48,-3]].forEach(p=>circle(g,...p,2,'#c0c7aa'));
    if(selected&&!preview){g.save();g.strokeStyle='#cde2b4';g.lineWidth=2;g.setLineDash([4,5]);g.strokeRect(-86,-180,176,213);g.restore();}
    if(!preview){
      const tagY=-195;rect(g,-66,tagY-11,140,23,failed?'#783523f5':'#172d31ed',4);circle(g,-54,tagY,3.5,working?'#ffab63':ready?'#bee291':'#8fae9e');text(g,failed?'NEPODARENÁ RÚRA':working?hasMetal?fmt(temp)+' °C':stages[stage].toUpperCase():ready?m.state==='unloading'?'NA PALETU':'ČAKÁ NA OBSLUHU':F.operator(state,index)?'PRIPRAVENÁ':'CHÝBA OBSLUHA',8,tagY,working?'#ffc584':ready?'#cde6ad':'#b9cabc',10);
      if(working){rect(g,-53,-174,120,3,'#182f32',2);rect(g,-53,-174,120*m.elapsed/F.duration(m.level,m.product),3,'#e5ad69',2);}
      text(g,String(index+1).padStart(2,'0')+' / '+product.code+' / MK '+roman[m.level-1]+(m.auto?' · SÉRIA':''),6,44,selected?'#d7e3c2':'#a6bca9',11,'center',600);
    }
    g.restore();
  }
  function drawFurnaceWorker(g){
    const loading=state.delivery?.returnElapsed===null&&F.stage(state.machines[state.delivery.slot])==='loading',crew=F.profile(loading?F.employee(state,state.delivery.furnaceId):F.duty(state,'furnace')),tilt=furnaceTilt();if(!crew)return;
    worker(g,34,328,false,0,false,1,crew);rect(g,49,296,12,14,'#254952',2);line(g,54,299,60+tilt*12,283+tilt*14,'#bac4af',3);circle(g,60+tilt*12,283+tilt*14,4,'#e2b766');
    line(g,45,294,60+tilt*12,283+tilt*14,crew.color,6);circle(g,60+tilt*12,283+tilt*14,3,'#d8bf98');
    rect(g,10,337,48,16,'#162c33d9',3);text(g,crew.name,34,345,'#d4dfd4',10);
    if(loading)glow(g,47,286,23,'#ffc67e',.1);
  }
  function drawExternalSteam(g,x,y,m,index,scale=1){
    if(!m)return;const cooling=F.stage(m)==='cooling',tail=m.state==='ready'&&m.finishedAt!==null&&Number.isFinite(m.finishedAt)?clamp(1-(state.clock-m.finishedAt)/3):0;if(!cooling&&!tail)return;
    const heat=clamp((F.temperature(m)-180)/1200),strength=cooling?.45+.55*heat:tail*.42,clock=reduced?1.4:time;
    g.save();g.translate(x,y);g.scale(scale,scale);
    // Steam leaves the top vent. Deliberately drawn outside the cabinet clip.
    for(let i=0;i<16;i++){
      const age=(clock*.23+i/16+index*.17)%1,spread=35+age*95+heat*20,px=8+Math.sin(i*1.8+clock*.38)*age*60+age*28,py=-148-age*(180+heat*75);
      g.save();g.globalAlpha=Math.sin(age*Math.PI)*(.27+.11*heat)*strength;g.translate(px,py);g.scale(1,.68);
      const cloud=g.createRadialGradient(-spread*.15,-spread*.12,0,0,0,spread);cloud.addColorStop(0,'#e5f4f5');cloud.addColorStop(.6,'#cedfe5');cloud.addColorStop(1,'#bdd9e000');circle(g,0,0,spread,cloud);g.restore();
    }
    if(cooling){g.globalAlpha=.16*strength;ellipse(g,9,-151,21,12,'#d5eff5');}g.restore();
  }
  function drawRejectSparks(g,x,y,m,index,scale=1){
    if(m?.state!=='failed')return;
    const age=m.failedElapsed,fade=clamp((F.FAILURE_SECONDS-age)/.85),hash=n=>{const v=Math.sin(n*127.1+index*311.7)*43758.5453;return v-Math.floor(v);};
    g.save();g.translate(x-7,y-82);g.scale(scale,scale);
    glow(g,0,0,105,'#ff7b24',.34*fade);glow(g,0,0,38,'#ffd27b',.5*fade);
    if(reduced){for(let k=0;k<28;k++){const a=k/28*Math.PI*2,r=30+hash(k+1)*45;line(g,Math.cos(a)*20,Math.sin(a)*20,Math.cos(a)*r,Math.sin(a)*r,'#ffbc64',1);}g.restore();return;}
    // 720 independently timed hot fragments fan out of the spinning bore.
    // Ballistic paths and cooling colours use simulation time, so pause freezes the burst.
    g.globalCompositeOperation='lighter';
    for(let k=0;k<720;k++){
      const birth=k/255,life=1.1+hash(k+19)*.55,t=age-birth;if(t<0||t>life)continue;
      const a=hash(k+2)*Math.PI*2+birth*8,speed=105+hash(k+5)*170,vx=Math.cos(a)*speed,vy=Math.sin(a)*speed*.76-28;
      const sx=Math.cos(a)*19,sy=Math.sin(a)*19,px=sx+vx*t,py=sy+vy*t+94*t*t,tail=Math.max(0,t-(.015+hash(k+3)*.018));
      const q=t/life,alpha=Math.min(1,t*35)*(1-q*.7)*fade;
      g.globalAlpha=alpha;line(g,sx+vx*tail,sy+vy*tail+94*tail*tail,px,py,q<.22?'#fff5c9':q<.58?'#ffc266':'#ff6b2e',.65+hash(k+8)*1.15);
      if(k%9===0){g.globalAlpha=alpha*.22;circle(g,px,py,3+hash(k+10)*2,'#ff9a46');}
    }
    g.globalAlpha=1;g.globalCompositeOperation='source-over';
    // A few larger torn chips make the damaged casting readable among the fine sparks.
    for(let k=0;k<12;k++){const t=age-k*.07;if(t<0||t>2.2)continue;const dir=k%2?1:-1,px=dir*(20+t*(45+hash(k+1)*90)),py=-t*(65+hash(k+7)*60)+78*t*t;g.save();g.translate(px,py);g.rotate(t*(k%2?8:-7));g.globalAlpha=clamp(1-t/2.2)*fade;poly(g,[[-3,-1],[0,-3],[4,1],[1,3]],t<.6?'#ffd48b':'#b94e2c');g.restore();}
    g.restore();
  }
  function drawWarehouse(g){
    const bg=g.createLinearGradient(0,0,0,690);bg.addColorStop(0,'#354753');bg.addColorStop(.26,'#263d47');bg.addColorStop(.27,'#53615e');bg.addColorStop(1,'#2c4146');rect(g,0,0,1100,690,bg);
    for(let x=0;x<1100;x+=138){rect(g,x,0,8,185,'#182f39');line(g,x,190,x+160,690,'#c4cfc012');}
    for(let y=200;y<690;y+=65)line(g,0,y,1100,y,'#b8cab017');
    for(let x=250;x<1100;x+=250){rect(g,x,50,165,71,'#19343e',3);rect(g,x+5,55,155,61,F.daylight(state)>.4?'#8aaeb9':'#263851');for(let j=1;j<4;j++)line(g,x+j*41,52,x+j*41,120,'#36535d',4);line(g,x,87,x+165,87,'#36535d',4);}
    rect(g,0,181,1100,8,'#172f37');pipe(g,0,147,1100,7);text(g,'SKLADOVÁ HALA / PRÍJEM A EXPEDÍCIA',650,166,'#cbd7d1',13,'center',600);
    // Receiving door and loaded pallets. Only stored stock is used by production.
    rect(g,18,206,167,328,'#152c35',5);for(let y=212;y<275;y+=10)rect(g,24,y,155,3,'#49646c');rect(g,25,280,151,245,'#2d454c');
    g.save();g.setLineDash([12,9]);line(g,198,200,198,577,'#e1bb7180',3);g.restore();text(g,'PRÍJMOVÁ RAMPA',102,298,'#edcf95',14,'center',600);
    Object.entries(F.MATERIALS).forEach(([id,p],i)=>{const y=334+i*36,quantity=state.incoming[id];rect(g,35,y+13,127,5,'#aa8b5b',2);if(quantity){rect(g,40,y-7,29,21,p.color,2);line(g,54,y-7,54,y+14,'#304951',3);text(g,p.short+' · '+quantity+' kg',80,y+5,'#e5ece1',11,'left');}else text(g,p.short+' · 0',103,y+5,'#728e97',11);});
    text(g,F.used(state,'incoming')+' / '+F.capacity(state,'incoming')+' kg',104,555,'#e7cca2',14);
    const ids=[...Object.keys(F.MATERIALS),'goods'];ids.forEach((id,i)=>{
      const p=positions[i],selected=selectedBin===id,over=hover===i,raw=id!=='goods',material=raw?F.MATERIALS[id]:null,count=raw?state.raw[id]:F.used(state,'goods'),max=raw?F.binCapacity(state,id):F.capacity(state,'goods'),color=raw?material.color:'#b7d5bb';g.save();g.translate(p.x,p.y);
      ellipse(g,10,16,104,24,'#10273055');poly(g,[[-95,16],[85,16],[115,-8],[-65,-8]],selected?'#e6c08416':'#c1cbbb08',selected?'#e4c58b':'#8ca3a14a');
      rect(g,-77,-103,156,111,'#304952',4);poly(g,[[79,-103],[100,-121],[100,-10],[79,8]],'#213b45','#526b70');poly(g,[[-77,-103],[-56,-121],[100,-121],[79,-103]],'#71837e','#98a59b');
      rect(g,-70,-92,142,91,'#142f39',2);for(const x of [-79,73])rect(g,x,-112,8,126,'#7f9993');
      for(const shelfY of [-47,-8]){rect(g,-77,shelfY,155,8,'#bba273',2);line(g,-73,shelfY+2,73,shelfY+2,'#ecd5a0');}
      if(raw){const total=Math.min(12,Math.ceil(count/Math.max(1,max)*12));for(let j=0;j<total;j++){const x=-62+(j%6)*22,y=j<6?-57:-18;rect(g,x,y-28,18,25,color,2);poly(g,[[x,y-28],[x+5,y-34],[x+23,y-34],[x+18,y-28]],'#c5d0c344');line(g,x+9,y-27,x+9,y-5,'#2c444b',2);}}
      else {let j=0;for(const [product,n]of Object.entries(state.goods))for(let k=0;k<Math.min(4,n)&&j<12;k++){const x=-56+(j%6)*24,y=j<6?-59:-20,fill=F.PRODUCTS[product].color;rect(g,x-9,y-20,18,20,fill,2);circle(g,x,y,9,fill);circle(g,x,y,product==='bronze_bushing'?3:6,'#17323b');j++;if(j>=12)break;}}
      const label=raw?material.name:'Hotové výrobky';rect(g,-99,-149,210,31,'#162f39ef',5);text(g,label,6,-133,selected?'#ffe2a6':'#d6e3e0',14,'center',600);
      text(g,raw&&!F.binOpen(state,id)?'ZAMKNUTÉ · '+F.BIN_UNLOCK[id]+' ₵':count+' / '+max+(raw?' kg':' ks'),3,26,color,raw&&!F.binOpen(state,id)?13:18,'center',600);rect(g,-74,42,154,4,'#142e38',2);rect(g,-74,42,154*clamp(count/Math.max(1,max)),4,color,2);
      if(raw&&state.incoming[id]){rect(g,-76,51,161,20,'#594933',4);text(g,'NA RAMPE: '+state.incoming[id]+' kg',5,61,'#ffe1a7',11);}
      if(selected||over){g.save();g.setLineDash([5,5]);g.strokeStyle=selected?'#f4ce88':'#b4c7b7';g.strokeRect(-104,-158,218,236);g.restore();}g.restore();
    });
    const move=state.stockMove,age=move?state.clock-move.at:5,storekeeper=F.profile(F.duty(state,'warehouse'));
    if(storekeeper&&move&&age>=0&&age<3){const i=Object.keys(F.MATERIALS).indexOf(move.material),target=positions[i],p=reduced?1:age/3,x=150+(target.x-150)*p,y=553+(target.y+25-553)*p;rect(g,x-20,y-12,48,7,'#c39b57',2);circle(g,x-13,y,5,'#192f35');circle(g,x+23,y,5,'#192f35');rect(g,x-14,y-40,35,28,F.MATERIALS[move.material].color,3);line(g,x-22,y-12,x-39,y-39,'#c8bb8b',3);worker(g,x-61,y+3,false,1,false,1,storekeeper);text(g,'+'+move.quantity+' kg',x,y-53,'#ffe5b9',13);text(g,storekeeper.name,x-61,y+18,'#dbebda',10);}
    else if(storekeeper){const phase=reduced?4:time%28,progress=phase<12?phase/12:phase<14?1:phase<26?1-(phase-14)/12:0,x=275+progress*730,y=635;worker(g,x,y,false,phase<12||phase>=14&&phase<26?1:0,false,phase<14?1:-1,storekeeper);rect(g,x-59,y+8,118,19,'#18323ce8',4);text(g,storekeeper.name+' · SKLADNÍK',x,y+18,'#d9e5ce',10);}
    const night=1-F.daylight(state);rect(g,0,0,1100,690,'rgba(8,18,35,'+night*.23+')');for(const x of [365,620,875]){rect(g,x-28,30,56,9,'#233a42',3);rect(g,x-22,39,44,3,'#d9e3cb',2);glow(g,x,50,80,'#dfdfba',.08+night*.1);}
  }
  function drawWasherHall(g){
    const w=state.washer,stage=F.washStage(state),running=F.washerRunning(state),t=w.elapsed;
    const bg=g.createLinearGradient(0,0,0,690);bg.addColorStop(0,'#243b4b');bg.addColorStop(.28,'#324c58');bg.addColorStop(.281,'#647172');bg.addColorStop(1,'#35494e');rect(g,0,0,1100,690,bg);
    for(let x=25;x<1100;x+=180){rect(g,x,0,10,193,'#1c303d');rect(g,x+27,46,116,83,'#162e3e',3);rect(g,x+32,51,106,73,F.daylight(state)>.4?'#84a3ab':'#233751');line(g,x+85,51,x+85,124,'#35515d',5);line(g,x+32,88,x+138,88,'#35515d',4);}
    rect(g,0,188,1100,9,'#162f3b');pipe(g,0,155,1100,8);line(g,0,173,1100,173,'#af9b69',3);
    for(let y=228;y<690;y+=62)line(g,0,y,1100,y,'#b1c1b718');for(let x=0;x<1100;x+=110)line(g,x,197,x-90,690,'#b1c1b714');
    // The L-shaped hall road follows the reference sketch.
    poly(g,[[0,552],[976,552],[976,197],[1100,197],[1100,690],[0,690]],'#283b43');
    line(g,0,550,974,550,'#d4b875',3);line(g,974,550,974,197,'#d4b875',3);
    g.save();g.setLineDash([28,24]);line(g,0,614,1043,614,'#c0bc9b55',3);line(g,1043,614,1043,197,'#c0bc9b55',3);g.restore();
    text(g,'HALOVÁ CESTA',822,665,'#8b9b9e',12,'center',600);poly(g,[[906,582],[887,573],[887,579],[858,579],[858,585],[887,585],[887,591]],'#bcc6b64d');
    ellipse(g,512,471,255,42,'#10222b55');ellipse(g,261,492,143,20,'#172b3455');ellipse(g,852,479,97,22,'#172b3455');
    const rail=(x,end,y,slope=0)=>{for(let px=x+20;px<end;px+=70){rect(g,px,y+18+(px-x)*slope,8,79,'#263e49',2);line(g,px,y+95+(px-x)*slope,px+25,y+95+(px-x)*slope,'#9eaeb0',4);}poly(g,[[x,y],[end,y+(end-x)*slope],[end,y+23+(end-x)*slope],[x,y+23]],'#344e5b','#82989f');for(let px=x+7;px<end;px+=22){line(g,px,y+4+(px-x)*slope,px,y+18+(px-x)*slope,'#a7b9bb',8);line(g,px-2,y+5+(px-x)*slope,px-2,y+16+(px-x)*slope,'#e0e4d5',2);}line(g,x,y+24,end,y+24+(end-x)*slope,'#b7c6c5',3);};
    rail(100,383,370,.045);rail(700,943,363,-.035);rect(g,95,353,8,58,'#b5c7c9',2);
    const tube=(x,y,clean=false)=>{const id=w.active||(!running&&w.lastProduct&&state.clock-w.lastAt<3?w.lastProduct:w.product);g.save();g.translate(x,y);g.scale(id==='ring'?.28:id==='bronze_bushing'?.45:1,1);x=0;y=0;const metal=g.createLinearGradient(0,y-29,0,y);metal.addColorStop(0,clean?'#dcecf0':'#8e9894');metal.addColorStop(.28,clean?'#f1fcfc':'#c7c7b9');metal.addColorStop(.53,clean?'#87acb9':'#8a9692');metal.addColorStop(1,'#344b58');rect(g,x,y-29,132,29,metal,3);ellipse(g,x+132,y-14.5,8,14.5,clean?'#abc8d0':'#aeb9ae');ellipse(g,x+132,y-14.5,5,10,'#192f3a');ellipse(g,x,y-14.5,8,14.5,clean?'#d8e8e6':'#b9c2b6');ellipse(g,x,y-14.5,5,10,'#243d48');line(g,x+8,y-25,x+122,y-25,clean?'#f0ffff':'#dddccd',1);if(!clean){for(let i=0;i<6;i++)ellipse(g,x+20+i*18,y-14+Math.sin(i*4)*7,10,4,'#e7e5d3b0');}else{line(g,x+14,y-8,x+124,y-8,'#b6e7ee',1);}g.restore();};
    // Pipes are painted first, so the opaque blue casing hides the whole cleaning chamber.
    if(stage==='loading')tube(824-280*clamp(t/F.WASH.load),359,false);
    if(stage==='ejecting'){const q=clamp((t-F.WASH.washEnd)/(F.WASH.total-F.WASH.washEnd));tube(430-266*q,362+q*q*18,true);}
    const recentlyDone=!running&&w.lastProduct&&state.clock-w.lastAt<3;if(recentlyDone)tube(164,380,true);
    // Closed enclosure: blue top, side and solid service doors, no cutaway.
    poly(g,[[372,231],[406,202],[724,202],[690,231]],'#4b8da8','#92b9c9');poly(g,[[690,231],[724,202],[724,422],[690,452]],'#154e71','#3b7690');
    const blue=g.createLinearGradient(372,231,690,450);blue.addColorStop(0,'#377caa');blue.addColorStop(.48,'#28698f');blue.addColorStop(1,'#17476b');rect(g,372,231,318,221,blue,5);line(g,377,233,687,233,'#85b8cc',2);
    rect(g,381,241,300,42,'#1d4868',3);text(g,'PIESKOVAČ',397,259,'#f0f5e6',22,'left',700);text(g,'VODNÉ ČISTENIE / UZAVRETÁ KOMORA',397,275,'#a6cbdc',9,'left',600);
    rect(g,384,294,204,136,'#235a80',3);rect(g,390,300,192,124,'#2c7198',3);line(g,487,302,487,421,'#163f5d',3);for(const x of [476,497])rect(g,x,347,5,24,'#c4d4d3',2);
    for(const x of [395,575])for(const y of [307,418]){circle(g,x,y,3,'#a4b9bf');line(g,x-1,y-1,x+1,y+1,'#27495f');}
    rect(g,604,296,66,118,'#153c55',4);rect(g,612,305,50,31,'#0c2535',2);text(g,running?'AUTO · RUN':'STANDBY',637,315,running?'#a5e9d3':'#aec2c7',8);text(g,running&&stage==='washing'?'120 bar':running?'POSUV':'0 bar',637,329,'#c3e8ec',11);
    circle(g,624,351,7,running?'#87d4ad':'#4f7274');circle(g,649,351,7,'#932f37');circle(g,649,351,4,'#e06755');
    circle(g,636,387,18,'#96b4c2');circle(g,636,387,14,'#e2e7d8');for(let k=0;k<7;k++){const a=-2.6+k*.65;line(g,636+Math.cos(a)*10,387+Math.sin(a)*10,636+Math.cos(a)*13,387+Math.sin(a)*13,'#47616d');}line(g,636,387,running&&stage==='washing'?645:627,running&&stage==='washing'?379:394,'#a44d42',2);circle(g,636,387,2,'#38596b');
    for(let k=0;k<6;k++)line(g,701,254+k*8,716,242+k*8,'#113951',3);
    rect(g,371,436,320,17,'#142d41',2);for(let x=376;x<682;x+=24)poly(g,[[x,438],[x+10,438],[x+19,450],[x+9,450]],'#d7b465');
    for(const x of [391,655]){rect(g,x,453,13,23,'#173449',2);rect(g,x-7,474,29,6,'#9daeb0',2);}rect(g,677,214,10,16,'#263f49',2);rect(g,678,204,8,12,running?'#7dd6a7':'#476659',3);if(running)glow(g,682,207,22,'#83edb2',.25);
    // Recirculating water tank, pump, hoses and drain grate.
    rect(g,479,466,141,54,'#25495c',5);poly(g,[[479,466],[490,457],[630,457],[619,466]],'#6a98ab');rect(g,487,476,8,31,'#7bc2d2',2);text(g,'VODA · FILTRÁCIA',557,488,'#c1d8dd',10);rect(g,531,503,60,4,'#133245',2);circle(g,642,482,14,'#397d96');circle(g,642,482,7,'#142f45');line(g,643,467,643,448,'#7aafbd',5);line(g,628,487,619,487,'#83b5bf',5);
    rect(g,345,500,111,21,'#1a323e',2);for(let x=351;x<454;x+=8)line(g,x,503,x,518,'#708d94',2);
    ellipse(g,421,477,52,10,running&&stage==='washing'?'#7cbcc842':'#79a9bb25');
    if(running&&stage==='washing'){
      const clock=reduced?1:t;
      for(let i=0;i<(reduced?12:86);i++){const q=(clock*1.35+i*.618)%1,side=i%2?-1:1,sx=side<0?380:707,sy=side<0?377:362,v=25+(i%11)*7,px=sx+side*v*q,py=sy-28*q+120*q*q+(i%5)*3;g.save();g.globalAlpha=(1-q)*.85;line(g,px,py,px-side*2,py-3-q*4,'#b8f2fa',1.3);g.restore();if(i%5===0){g.save();g.globalAlpha=(1-q)*.4;ellipse(g,sx+side*v,side<0?470:458,3+q*10,1+q*3,'#96ddea');g.restore();}}
      for(let i=0;i<13;i++){const q=(clock*.85+i/13)%1;line(g,397+i*13,426,397+i*13+Math.sin(i)*3,435+q*29,'#85cbd999',1);}
    }
    for(const [x,input]of [[154,false],[795,true]]){rect(g,x-16,516,171,7,'#a48860',2);rect(g,x-10,524,22,7,'#655942');rect(g,x+110,524,22,7,'#655942');const count=input?F.available(state,w.product):state.goods[F.WASH.outputs[w.product]];for(let i=0;i<Math.min(3,count);i++)tube(x+i*4,511-i*15,!input);text(g,(input?'NEOČISTENÉ':'OPRACOVANÉ')+' · '+count+' ks',x+64,542,'#c8d7d5',11,'center',600);}
    text(g,'← VÝSTUP',211,329,'#b6e2d4',13,'center',600);text(g,'VSTUP ←',850,308,'#e1dcc0',13,'center',600);
    const attendant=F.profile(F.duty(state,'washer'));if(attendant){worker(g,782,500,false,0,false,-1,attendant);text(g,attendant.name,782,524,'#e3ece4',12,'center',600);}
    rect(g,392,91,325,42,'#122c3cdc',6);circle(g,410,112,4,running?'#8cddbe':'#9eb2b6');text(g,{idle:'PRIPRAVENÝ NA NAKLADANIE',loading:'NAKLADANIE RÚRY',washing:'ČISTENIE TLAKOVOU VODOU',ejecting:'VÝSTUP OPRACOVANEJ RÚRY'}[stage],552,112,'#d9e8e6',13,'center',600);
    drawForeman(g);const night=1-F.daylight(state);rect(g,0,0,1100,690,'rgba(8,18,35,'+night*.23+')');for(const x of [260,550,850]){rect(g,x-29,25,58,9,'#19323e',3);rect(g,x-23,34,46,3,'#e4ebd3',2);glow(g,x,75,125,'#d5e4d6',.09+night*.09);}
  }

  function drawCncMachine(g,p,i){
    const modern=!!p.amada,on=!!state.cncOwned[i]&&!!cncPower[i];g.save();g.translate(p.x,p.y);if(modern)g.scale(1.17,1.2);
    ellipse(g,108,139,109,17,'#10283066');poly(g,[[0,0],[19,-19],[211,-19],[192,0]],modern?'#e47770':'#d0d0b7','#97aaa0');poly(g,[[192,0],[211,-19],[211,112],[192,131]],modern?'#862e3a':'#3e655c','#6b8d7f');
    rect(g,0,0,192,130,modern?'#bc4250':'#c0c3a8',3);rect(g,0,95,192,35,modern?'#8f2d3b':'#426f5f',2);line(g,3,2,189,2,modern?'#f8a194':'#e3e4cc',2);
    rect(g,8,10,137,72,modern?'#9b303f':'#a7ae95',3);rect(g,16,18,121,54,'#142e35',3);rect(g,21,23,111,44,on?'#2f5155':'#223b40',2);
    // The same aged machine geometry and coolant streaks are reused for CNC 1–6.
    rect(g,25,43,25,15,'#839590',2);circle(g,49,50,13,'#6c8581');circle(g,49,50,8,'#b6c7bc');circle(g,49,50,4,'#203d40');rect(g,50,45,55,10,'#aabcb5',2);line(g,51,46,103,46,'#d6dfca',1);
    const offset=on&&!reduced?Math.sin(time*1.7+i)*4:0;rect(g,89+offset,29,21,9,'#778d85',1);poly(g,[[99+offset,38],[105+offset,38],[104+offset,48]],'#d7ddc6');line(g,81,26,115,26,'#bfba77',2);line(g,115,26,110,41,'#b8ba78',2);
    line(g,75,16,75,73,modern?'#e16b70':'#b9c1a9',3);rect(g,132,42,4,18,'#dde1d0',2);rect(g,147,10,37,79,modern?'#ede8db':'#c8cbb3',3);rect(g,152,18,27,23,'#172f39',2);
    if(on){rect(g,155,22,20,3,'#89c6b4');for(let k=0;k<3;k++)rect(g,155,28+k*3,11+k*3,1,'#7daea2');}else line(g,155,30,175,30,'#476367');
    for(let y=49;y<70;y+=8)for(let x=153;x<179;x+=8)rect(g,x,y,4,4,'#5d756e',1);circle(g,166,78,5,'#b9473e');circle(g,166,78,2,'#e89b6e');
    if(!modern){for(let k=0;k<18;k++){const x=12+(k*47)%129,y=75+(k*19)%38;ellipse(g,x,y,4+(k%4)*2,2+k%3,'#7b583a66');line(g,x,y,x+Math.sin(k)*3,y+7+k%11,'#8e613d70',2);}for(let k=0;k<7;k++){const x=10+k*23;line(g,x,5,x+9,6,'#8b9c85',1);line(g,x+3,103,x+12,105,'#aac0a14d',2);}rect(g,16,88,65,3,'#8d633b70');}
    rect(g,12,113,88,12,modern?'#762936':'#315747',2);text(g,modern?'AMADA':'CNC '+(i+1),56,119,modern?'#ffe5dd':'#e5e8cc',modern?11:12,'center',700);
    for(let k=0;k<5;k++)line(g,125,105+k*4,176,105+k*4,modern?'#702331':'#294e43',2);
    for(const x of [12,169]){rect(g,x,130,9,10,'#1d343b');rect(g,x-3,139,15,3,'#82958f');}
    // Swarf conveyor/chute and a separate collection bin on every machine.
    poly(g,[[179,104],[202,102],[224,132],[209,140]],'#546d65','#9ead9c');poly(g,[[185,105],[198,105],[218,133],[209,133]],'#243e3d');for(let k=0;k<5;k++){const x=194+k*4,y=111+k*5;line(g,x,y,x+7,y-2,'#a1aaa0',2);}
    rect(g,207,142,33,23,modern?'#365566':'#62674b',2);poly(g,[[203,140],[232,134],[241,141],[211,148]],'#929b80');poly(g,[[208,141],[232,137],[236,141],[212,145]],'#273e39');line(g,209,149,237,149,'#b1b59b',2);for(let k=0;k<8;k++){const x=211+k*3,y=139+Math.sin(k*3)*2;line(g,x,y,x+3,y+2,'#c0b79b',1);}circle(g,212,167,3,'#1d3338');circle(g,234,167,3,'#1d3338');
    rect(g,178,-33,4,17,'#344e50');rect(g,171,-43,18,13,'#253e43',3);rect(g,173,-41,14,9,on?'#72e7a8':'#f57663',3);line(g,175,-40,183,-40,on?'#d4ffe3':'#ffd9bd',1);glow(g,180,-37,21,on?'#7bf2ad':'#f98164',.24);
    if(!state.cncOwned[i]){rect(g,0,0,192,130,'#102632aa',3);rect(g,8,46,176,42,'#11262fed',4);text(g,modern?'AMADA · ZAMKNUTÁ':'KÚPIŤ · '+F.cncPrice(i)+' ₵',96,68,'#f0d39b',13,'center',600);}
    if(hover===i){g.save();g.setLineDash([5,5]);g.strokeStyle='#f1d49a';g.strokeRect(-6,-47,251,221);g.restore();}g.restore();
  }
  function drawCncHall(g){
    const bg=g.createLinearGradient(0,0,0,690);bg.addColorStop(0,'#3f5452');bg.addColorStop(.16,'#344b4a');bg.addColorStop(.161,'#596961');bg.addColorStop(1,'#374d49');rect(g,0,0,1100,690,bg);
    for(let x=25;x<1100;x+=180){rect(g,x,0,8,107,'#203a3b');rect(g,x+32,26,104,48,F.daylight(state)>.4?'#88a39e':'#273d4d',2);line(g,x+83,26,x+83,74,'#3b5554',4);line(g,x+32,51,x+136,51,'#3b5554',3);}rect(g,0,104,1100,7,'#1d3736');pipe(g,0,88,1100,5);
    for(let y=145;y<690;y+=57)line(g,0,y,1100,y,'#b8c9ad14');for(let x=0;x<1100;x+=110)line(g,x,111,x-35,690,'#b8c9ad14');
    // Four machines above, AMADA lower left, 5/6 lower right; the road wraps around them.
    poly(g,[[359,317],[1100,317],[1100,405],[553,405],[553,617],[1100,617],[1100,690],[0,690],[0,617],[359,617]],'#273e40');
    line(g,365,315,1100,315,'#d7bd75',3);line(g,356,320,356,614,'#d7bd75',3);line(g,0,614,356,614,'#d7bd75',3);line(g,556,408,1100,408,'#d7bd75',3);line(g,556,408,556,614,'#d7bd75',3);line(g,556,614,1100,614,'#d7bd75',3);
    g.save();g.setLineDash([22,20]);line(g,457,360,1100,360,'#adbd9e50',2);line(g,457,360,457,652,'#adbd9e50',2);line(g,0,652,1100,652,'#adbd9e50',2);g.restore();text(g,'HALOVÁ CESTA',767,670,'#8fa49c',10,'center',600);
    // Desk faces into the hall: monitor at the left wall, keyboard and chair to its right.
    ellipse(g,66,370,57,14,'#152d3450');
    for(const [x,y]of [[21,322],[69,327],[21,349],[69,354]]){line(g,x,y,x,y+24,'#a4afaa',3);line(g,x,y+24,x+5,y+24,'#526966',2);}line(g,22,354,68,359,'#627c76',2);
    rect(g,26,351,19,25,'#233238',2);poly(g,[[45,351],[51,345],[51,370],[45,376]],'#162a30');rect(g,30,355,11,2,'#101e27');circle(g,40,361,1.7,'#8de6c2');for(let k=0;k<4;k++)line(g,30,366+k*2,41,366+k*2,'#526970');
    poly(g,[[17,308],[68,316],[80,348],[28,340]],'#c1a47b','#d5bd94');poly(g,[[28,340],[80,348],[80,355],[28,347]],'#8c7255');poly(g,[[17,308],[28,340],[28,347],[17,315]],'#a98a64');
    // Upright monitor, seen obliquely from the hall; its stand stays vertical.
    poly(g,[[29,325],[35,321],[46,329],[40,333]],'#35474a');line(g,35,311,35,326,'#3b4d50',4);
    poly(g,[[17,282],[37,297],[42,322],[22,307]],'#1a292f','#728987');poly(g,[[20,288],[34,298],[38,316],[24,306]],'#82b5bd');line(g,21,290,34,300,'#3f6878',2);for(let k=0;k<4;k++)line(g,23+k*.6,294+k*3,33+k*.6,301+k*3,'#d2e4d7',1);circle(g,39,318,1,'#91e6bb');
    // Keyboard's long edge follows the wall, with the mouse beside it.
    poly(g,[[46,316],[55,319],[64,336],[54,333]],'#283a40','#7f9190');for(let row=0;row<3;row++)for(let key=0;key<8;key++)rect(g,48+row*2+key*.95,319+key*1.55+row*.5,1.2,1,'#b7c6bd');line(g,55,324,60,332,'#d9ddd0',1);
    poly(g,[[62,339],[71,341],[74,347],[65,345]],'#465b5b');ellipse(g,68,342,3,2,'#c7cec4');line(g,68,341,68,342,'#546767');
    // Office chair turned toward the monitor, on an upright gas lift and wheeled base.
    line(g,99,348,99,371,'#acb8b3',3);for(const [x,y]of [[81,374],[109,379],[117,369],[92,364],[97,380]]){line(g,99,371,x,y,'#819895',2);ellipse(g,x,y+2,3,2,'#152a31');}
    poly(g,[[80,340],[96,334],[113,342],[105,354],[87,351]],'#384e58','#6e8588');ellipse(g,97,344,16,7,'#3d5662');
    for(const [x,y]of [[87,333],[101,350]]){line(g,x,y,x,y+12,'#8fa5a4',2);line(g,x-6,y,x+5,y+2,'#1b303a',3);}
    line(g,111,331,108,352,'#2b414a',3);poly(g,[[106,313],[116,318],[115,342],[105,337]],'#263e4a','#536c75');line(g,109,318,114,321,'#70858b',1);
    text(g,'PROGRAMOVANIE',67,395,'#c0d1be',8,'center',600);
    cncPositions.forEach((p,i)=>drawCncMachine(g,p,i));
    text(g,'PÔVODNÁ LINKA / CNC 1–6',634,85,'#d0dcc5',11,'center',600);text(g,'NOVÁ LINKA',193,376,'#e4d1bc',11,'center',600);
    const night=1-F.daylight(state);rect(g,0,0,1100,690,'rgba(8,18,35,'+night*.21+')');for(const x of [210,487,767,1010]){rect(g,x-25,8,50,8,'#243e3c',3);rect(g,x-20,16,40,3,'#e2e6c8');glow(g,x,50,85,'#e5e6bc',.08+night*.1);}
  }

  function draw(){
    ctx.clearRect(0,0,1100,690);if(area==='warehouse'){drawWarehouse(ctx);return;}if(area==='washer'){drawWasherHall(ctx);return;}if(area==='cnc'){drawCncHall(ctx);return;}
    drawBackground(ctx);positions.forEach((p,i)=>{drawSlot(ctx,p,i);drawOperator(ctx,p,i);});drawTransport(ctx);drawAmbient(ctx);positions.forEach((p,i)=>{drawExternalSteam(ctx,p.x,p.y,state.machines[i],i);drawRejectSparks(ctx,p.x,p.y,state.machines[i],i);});drawForeman(ctx);
    dc.clearRect(0,0,320,220);const m=state.machines[state.selected];if(!m){dc.save();dc.globalAlpha=.42;drawMachine(dc,155,201,{level:1,state:'idle',elapsed:0},state.selected,1,false,true);dc.restore();}else{drawMachine(dc,155,201,m,state.selected,1,false,true);drawExternalSteam(dc,155,201,m,state.selected,.65);drawRejectSparks(dc,155,201,m,state.selected,.48);if(F.stage(m)==='pouring'&&state.delivery?.slot===state.selected){const pose=deliveryPose(),lip=drawLadle(dc,{x:90,y:87},pose.tilt,pose.fill,true);if(pose.flow)stream(dc,lip,{x:148,y:119},4);}}
  }

  return {render(snapshot,animationTime,hovered=-1,location='foundry',bin='iron',cnc=[]){cncPower=cnc;state=snapshot;time=animationTime;hover=hovered;area=location;selectedBin=bin;draw();},hit(e,location='foundry'){if(location==='washer')return -1;const r=canvas.getBoundingClientRect(),x=(e.clientX-r.left)*1100/r.width,y=(e.clientY-r.top)*690/r.height;if(location==='cnc')return cncPositions.findIndex(p=>x>p.x&&x<p.x+(p.amada?260:192)&&y>p.y-25&&y<p.y+(p.amada?175:130));return positions.findIndex(p=>x>p.x-(location==='warehouse'?104:94)&&x<p.x+(location==='warehouse'?114:101)&&y>p.y-(location==='warehouse'?158:174)&&y<p.y+(location==='warehouse'?80:43));}};
}};
