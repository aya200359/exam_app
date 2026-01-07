import { api } from "./api.js";

const $ = (id) => document.getElementById(id);
const deptSel = $("dept");
const formSel = $("formation");
const anneeSel = $("annee");
const periodeSel = $("periode");
const msg = $("msg");
const tablesContainer = document.getElementById("tables-container");
const studentIdInput = document.getElementById("student_id");
const loadPersonalBtn = document.getElementById("load_personal");
let lastRows = [];

function setMsg(text, bad=false){
  msg.textContent = text;
  msg.style.borderColor = bad ? "rgba(239,68,68,.35)" : "rgba(255,255,255,.18)";
  msg.style.background = bad ? "rgba(239,68,68,.12)" : "rgba(255,255,255,.06)";
}

function fillSelect(sel, items, getVal, getLabel){
  sel.innerHTML = "";
  items.forEach(it=>{
    const opt=document.createElement("option");
    opt.value=getVal(it);
    opt.textContent=getLabel(it);
    sel.appendChild(opt);
  });
}

function renderGroupTables(rows){
  tablesContainer.innerHTML = "";

  // Group by FullGroupLabel (fallback to GroupCode)
  const groups = {};
  rows.forEach(r => {
    const label = r.FullGroupLabel || r.GroupCode || "(unknown)";
    groups[label] = groups[label] || [];
    groups[label].push(r);
  });

  Object.keys(groups).forEach(label => {
    const card = document.createElement('div');
    card.className = 'card mb-3';
    card.innerHTML = `
      <div class="card-header small fw-bold">Groupe: ${label} <span class="text-muted small">(${groups[label].length} lignes)</span></div>
      <div class="card-body p-0">
        <div class="table-responsive">
          <table class="table table-sm mb-0">
            <thead class="table-light small">
              <tr>
                <th>Date</th>
                <th>Début</th>
                <th>Fin</th>
                <th>Module</th>
                <th>Salle</th>
                <th>Bâtiment</th>
              </tr>
            </thead>
            <tbody></tbody>
          </table>
        </div>
      </div>
    `;

    const tb = card.querySelector('tbody');
    groups[label].forEach(r => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${r.DateLabel ?? ''}</td>
        <td>${r.Start ?? ''}</td>
        <td>${r.End ?? ''}</td>
        <td>${r.Module ?? ''}</td>
        <td>${r.Room ?? ''}</td>
        <td>${r.Building ?? ''}</td>
      `;
      tb.appendChild(tr);
    });

    tablesContainer.appendChild(card);
  });
}

async function loadDepts(){
  const depts = await api.departements();
  fillSelect(deptSel, depts, d=>d.id_dept, d=>d.nom);
}

async function loadFormations(){
  const dept_id = Number(deptSel.value);
  const forms = await api.formations(dept_id);
  fillSelect(formSel, forms, f=>f.id_formation, f=>f.nom);
}

async function loadAnnees(){
  const formation_id = Number(formSel.value);
  const years = await api.annees(formation_id);
  fillSelect(anneeSel, years, y=>y, y=>y);
}

async function loadPeriodes(){
  const formation_id = Number(formSel.value);
  const annee = anneeSel.value;
  const sessions = await api.sessions(formation_id, annee);
  fillSelect(periodeSel, sessions, s=>s.id_periode, s=>s.label);
}

function toCSV(rows){
  const cols = ["DateLabel","Start","End","Module","Room","Building","FullGroupLabel"];
  const head = cols.join(",");
  const body = rows.map(r => cols.map(c => `"${String(r[c] ?? "").replaceAll('"','""')}"`).join(",")).join("\n");
  return head + "\n" + body;
}

$("load").addEventListener("click", async ()=>{
  try{
    setMsg("Loading schedule…");
    const formation_id = Number(formSel.value);
    const annee = anneeSel.value;
    const periode_id = Number(periodeSel.value);

    const rows = await api.schedule(formation_id, annee, periode_id);
    lastRows = rows;
    renderGroupTables(rows);
    setMsg(`Loaded ${rows.length} rows ✅`);
  }catch(e){
    lastRows = [];
    renderGroupTables([]);
    setMsg(e.message, true);
  }
});

$("export").addEventListener("click", ()=>{
  if(!lastRows.length) return setMsg("Nothing to export.", true);
  const csv = toCSV(lastRows);
  const blob = new Blob([csv], {type:"text/csv;charset=utf-8"});
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = "student_schedule.csv";
  a.click();
  URL.revokeObjectURL(a.href);
});

async function init(){
  try{
    setMsg("Loading lists…");
    await loadDepts();
    await loadFormations();
    await loadAnnees();
    await loadPeriodes();
    setMsg("Ready ✅");
  }catch(e){
    setMsg(e.message, true);
  }
}

deptSel.addEventListener("change", async ()=>{
  try{
    await loadFormations(); await loadAnnees(); await loadPeriodes();
    setMsg("Ready ✅");
  }catch(e){ setMsg(e.message, true); }
});
formSel.addEventListener("change", async ()=>{
  try{
    await loadAnnees(); await loadPeriodes();
    setMsg("Ready ✅");
  }catch(e){ setMsg(e.message, true); }
});
anneeSel.addEventListener("change", async ()=>{
  try{
    await loadPeriodes();
    setMsg("Ready ✅");
  }catch(e){ setMsg(e.message, true); }
});

loadPersonalBtn.addEventListener('click', async () => {
  const student_id = Number(studentIdInput.value);
  const periode_id = Number(periodeSel.value);
  if (!student_id) return setMsg('Veuillez saisir un ID étudiant', true);
  if (!periode_id) return setMsg('Veuillez sélectionner une session', true);

  try {
    setMsg('Chargement de votre emploi du temps…');
    const rows = await api.studentSchedule(student_id, periode_id);
    lastRows = rows;
    renderGroupTables(rows);
    setMsg(`Loaded ${rows.length} rows ✅`);
  } catch (e) {
    lastRows = [];
    renderGroupTables([]);
    setMsg(e.message, true);
  }
});

init();
