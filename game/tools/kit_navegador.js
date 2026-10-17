// Kit de teste do Golden Path no navegador automatizado (ADR-027). Só funciona
// com o build de DEPURAÇÃO Web, que expõe a sonda (systems/sonda_teste_web.gd):
// window.muriloEstado/muriloMirar/muriloProcurar/muriloBloco/muriloHora/
// muriloSpawnar/muriloLimparCriaturas/muriloMedir. Carregar com uma tag
// <script> na página do jogo e chamar as funções window.__* pelo console.
// Achados que moldaram o kit: o navegador automatizado não recebe Pointer Lock
// (a câmera é apontada pela sonda); a mira usa o braço da câmera, deslocado
// 0,55 de lado, então pra andar aponta-se para um ponto 9 blocos à frente na
// mesma direção (__mirarLonge); subir degrau é "segurar W contra a parede e só
// então pular"; chamadas do navegador expiram em 45 s, por isso __rodar/__aguardar.
window.__sleep = ms => new Promise(r => setTimeout(r, ms));
window.__estado = () => { window.muriloEstado(); return JSON.parse(window.muriloUltimoEstado); };
window.__down = (key, code, keyCode) => { const c = document.querySelector('canvas'); c.focus(); c.dispatchEvent(new KeyboardEvent('keydown', {key, code, keyCode, which: keyCode, bubbles: true, cancelable: true})); };
window.__up = (key, code, keyCode) => { const c = document.querySelector('canvas'); c.dispatchEvent(new KeyboardEvent('keyup', {key, code, keyCode, which: keyCode, bubbles: true, cancelable: true})); };
window.__tecla = async (key, code, keyCode, ms) => { window.__down(key, code, keyCode); await window.__sleep(ms); window.__up(key, code, keyCode); };
window.__busca = (id, raio, dmin, dmax) => { window.muriloProcurar(id, raio, dmin, dmax); return JSON.parse(window.muriloUltimaBusca); };
window.__bloco = (x, y, z) => { window.muriloBloco(x, y, z); return window.muriloUltimoBloco; };
window.__dist2d = (p, t) => Math.hypot(p[0] - (t[0] + 0.5), p[2] - (t[2] + 0.5));
// Aponta o corpo para a direção do alvo usando um ponto distante (anula o erro do braço da câmera).
window.__mirarLonge = (p) => { const e = window.__estado(); const dx = (p[0] + 0.5) - e.pos[0], dz = (p[2] + 0.5) - e.pos[2]; const n = Math.hypot(dx, dz) || 1; window.muriloMirar(Math.floor(e.pos[0] + dx / n * 9), Math.floor(e.pos[1]), Math.floor(e.pos[2] + dz / n * 9)); };
window.__andarAte = async (alvo, perto) => {
  let ultimo = null;
  for (let i = 0; i < 16; i++) {
    const e = window.__estado();
    const d = window.__dist2d(e.pos, alvo);
    if (d < perto) return d;
    window.__mirarLonge(alvo);
    await window.__sleep(250);
    const travado = ultimo && Math.hypot(e.pos[0] - ultimo[0], e.pos[2] - ultimo[2]) < 0.2;
    if (travado) window.__down(' ', 'Space', 32);
    await window.__tecla('w', 'KeyW', 87, Math.min(1500, 200 + d * 200));
    window.__up(' ', 'Space', 32);
    ultimo = e.pos;
  }
  return -1;
};
window.__quebrar = async (alvo, id) => {
  window.muriloMirar(alvo[0], alvo[1], alvo[2]);
  await window.__sleep(800);
  window.__down('q', 'KeyQ', 81);
  let quebrou = false;
  for (let k = 0; k < 14; k++) {
    await window.__sleep(2500);
    window.muriloMirar(alvo[0], alvo[1], alvo[2]);
    if (window.__bloco(alvo[0], alvo[1], alvo[2]) !== id) { quebrou = true; break; }
  }
  window.__up('q', 'KeyQ', 81);
  return quebrou;
};
window.__coletar = async (id, dmin, dmax) => {
  const log = [];
  const alvo = window.__busca(id, 16, dmin, dmax);
  if (!alvo.length) return ['nada perto'];
  log.push('alvo ' + alvo.join(','));
  log.push('d ' + (await window.__andarAte(alvo, 2.4)).toFixed(1));
  log.push('quebrou ' + await window.__quebrar(alvo, id));
  await window.__sleep(1500);
  await window.__andarAte(alvo, 0.6);
  await window.__sleep(2500);
  const f = window.__estado();
  log.push(f.quest + ' ' + f.progresso + ' ' + JSON.stringify(f.mochila.filter(s => Object.keys(s).length)));
  return log;
};
// Rota a pé por blocos reais (busca em largura) até uma condição; devolve lista de células [x, y_pes, z].
window.__rota = (meta, limite) => {
  const cache = {}; const S = (x, y, z) => { const k = x + ',' + y + ',' + z; if (!(k in cache)) { const v = window.__bloco(x, y, z); cache[k] = v !== 0 && v !== -1 && v !== 16; } return cache[k]; };
  const e = window.__estado(); const start = [Math.floor(e.pos[0]), Math.floor(e.pos[1] - 0.94), Math.floor(e.pos[2])];
  const ok = (x, y, z) => !S(x, y, z) && !S(x, y + 1, z) && S(x, y - 1, z);
  const q = [start], prev = {}; prev[start.join()] = null; let fim = null;
  while (q.length) { const c = q.shift(); if (meta(c)) { fim = c; break; }
    for (const [dx, dz] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) for (const dy of [0, 1, -1]) { const n = [c[0] + dx, c[1] + dy, c[2] + dz];
      if (Math.abs(n[0] - start[0]) > (limite || 10) || Math.abs(n[2] - start[2]) > (limite || 10)) continue; if (n.join() in prev) continue; if (!ok(...n)) continue;
      if (dy === 1 && S(c[0], c[1] + 2, c[2])) continue; if (dy === -1 && S(n[0], n[1] + 2, n[2])) continue; prev[n.join()] = c; q.push(n); } }
  const cam = []; let c = fim; while (c) { cam.unshift(c); c = prev[c.join()]; } return cam;
};
window.__seguir = async (cam) => {
  const log = [];
  for (const p of cam.slice(1)) { let ok = false;
    for (let t = 0; t < 8; t++) { const e = window.__estado(); const d = Math.hypot(e.pos[0] - (p[0] + 0.5), e.pos[2] - (p[2] + 0.5)); const pe = Math.floor(e.pos[1] - 0.94);
      if (pe >= p[1] && d < (p[1] > pe ? 0.45 : 1.2)) { ok = true; break; }
      if (pe > p[1] && d < 1.5) { ok = true; break; }
      const subir = p[1] > pe; window.__mirarLonge(p); await window.__sleep(250);
      if (subir) { window.__down('w', 'KeyW', 87); await window.__sleep(250); window.__down(' ', 'Space', 32); await window.__sleep(350); window.__up(' ', 'Space', 32); await window.__sleep(100); window.__up('w', 'KeyW', 87); }
      else { await window.__tecla('w', 'KeyW', 87, Math.min(500, 120 + d * 220)); }
      await window.__sleep(450); }
    const f = window.__estado(); log.push(p.join(',') + (ok ? ' ok ' : ' X ') + f.pos.map(v => v.toFixed(1)).join(',')); if (!ok) break; }
  return log;
};
window.__sairDoBuraco = async () => { const cam = window.__rota(c => { for (let k = c[1] + 2; k < c[1] + 10; k++) if (window.__bloco(c[0], k, c[2]) !== 0) return false; return true; }, 10); return await window.__seguir(cam); };
// Anda até um alvo móvel e aperta E quando a mira acerta o grupo pedido ('npc' ou 'criatura').
window.__irEInteragir = async (pegarAlvo, grupo) => {
  const log = []; let ultimo = null; let travadas = 0;
  for (let i = 0; i < 30; i++) {
    const e = window.__estado(); const p = pegarAlvo(e);
    if (!p) return log.concat('sem alvo');
    const d = Math.hypot(p[0] - e.pos[0], p[2] - e.pos[2]); log.push(d.toFixed(1));
    if (d < 2.6) {
      window.muriloMirar(Math.floor(p[0]), Math.floor(p[1]) - 1, Math.floor(p[2])); await window.__sleep(600);
      let m = window.__estado().mira;
      if (!(m && m.grupo === grupo)) { window.muriloMirar(Math.floor(p[0]), Math.floor(p[1]), Math.floor(p[2])); await window.__sleep(600); m = window.__estado().mira; }
      log.push(JSON.stringify(m));
      if (m && m.grupo === grupo) { await window.__tecla('e', 'KeyE', 69, 300); await window.__sleep(2500); log.push('estado ' + window.__estado().estado); return log; }
    }
    const travado = ultimo && Math.hypot(e.pos[0] - ultimo[0], e.pos[2] - ultimo[2]) < 0.2;
    if (travado) travadas++;
    if (travadas >= 2) { travadas = 0; const alvo = [Math.floor(p[0]), Math.floor(p[2])]; const cam = window.__rota(c => Math.abs(c[0] - alvo[0]) <= 1 && Math.abs(c[2] - alvo[1]) <= 1, 14); log.push('rota' + cam.length + ' ' + JSON.stringify(await window.__seguir(cam)).slice(0, 160)); }
    else { window.__mirarLonge([Math.floor(p[0]), 0, Math.floor(p[2])]); await window.__sleep(250); await window.__tecla('w', 'KeyW', 87, d > 6 ? 1000 : 350); }
    ultimo = e.pos;
  }
  return log;
};
window.__falarCom = (id) => window.__irEInteragir(e => { const n = e.npcs.find(x => x.id === id); return n && n.pos; }, 'npc');
window.__batalharCom = (especie) => window.__irEInteragir(e => {
  let m = null, md = 1e9;
  for (const c of e.criaturas) { if (c.especie !== especie) continue; const d = Math.hypot(c.pos[0] - e.pos[0], c.pos[2] - e.pos[2]); if (d < md) { md = d; m = c; } }
  return m && m.pos;
}, 'criatura');
// Roda em segundo plano (as chamadas do navegador automatizado expiram em 45 s).
window.__rodar = (promessa) => { window.__resultado = 'rodando'; promessa.then(r => { window.__resultado = r; }, e => { window.__resultado = 'erro ' + e; }); return 'iniciado'; };
window.__aguardar = async (ms) => { const t0 = performance.now(); while (window.__resultado === 'rodando' && performance.now() - t0 < ms) await window.__sleep(1000); return window.__resultado; };
'kit carregado';
