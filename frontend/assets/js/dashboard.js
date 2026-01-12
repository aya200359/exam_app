import { api } from "./api.js";
const $ = (id)=>document.getElementById(id);
const periodeSel = $("periode");
const refreshBtn = $("refresh");

function fillSelect(sel, items, getVal, getLabel){
  sel.innerHTML = "";
  items.forEach(it=>{
    const opt=document.createElement("option");
    opt.value=getVal(it);
    opt.textContent=getLabel(it);
    sel.appendChild(opt);
  });
}

let roomChart = null;
let groupChart = null;

function setMsg(t, bad=false){
  const msg = $("msg");
  msg.textContent = t;
  msg.className = bad ? "alert-box bad" : "alert-box good";
}

function renderConf(rows){
  const confEl = $("conf");
  if (!confEl) return;
  confEl.innerHTML = "";
  if(!rows || rows.length === 0) return;
  rows.forEach(r=>{
    const tr = document.createElement("tr");
    tr.innerHTML = `<td>${r.Professor}</td><td>${String(r.date).slice(0,10)}</td><td>${r.Start}</td><td><span class="badge danger">${r.Assignments}</span></td>`;
    confEl.appendChild(tr);
  });
}

function renderTopRooms(rows){
  const tbody = $("topRooms");
  if (!tbody) return;
  tbody.innerHTML = "";
  if(!rows || rows.length === 0) return;
  rows.forEach(r=>{
    const tr = document.createElement("tr");
    const typeIcon = r.Type === "salle" ? "🏠" : "🏛️";
    tr.innerHTML = `<td>${typeIcon} ${r.nom}</td><td><span class="badge">${r.Type}</span></td><td><strong>${r.sessions}</strong></td>`;
    tbody.appendChild(tr);
  });
}

function renderProfLoad(rows){
  const tbody = $("profLoad");
  if (!tbody) return;
  tbody.innerHTML = "";
  if(!rows || rows.length === 0) {
    tbody.innerHTML = "<tr><td colspan='3'>No data</td></tr>";
    return;
  }
  const sorted = rows.sort((a,b) => b.total_surveillances - a.total_surveillances).slice(0,8);
  sorted.forEach(r=>{
    const tr = document.createElement("tr");
    const pct = Math.round((r.total_surveillances / (sorted[0].total_surveillances || 1)) * 100);
    tr.innerHTML = `<td><strong>${r.nom}</strong></td><td>${r.Dept}</td><td><span class="badge" style="background:rgba(37,99,235,0.2); color:#2563eb;">${r.total_surveillances} <span style="font-size:11px;">/${pct}%</span></span></td>`;
    tbody.appendChild(tr);
  });
}

function createRoomChart(data){
  if(!data || data.length === 0) return;

  const canvas = $("roomChart");
  if(!canvas) return;

  if(roomChart) roomChart.destroy();

  const types = data.map(d => d.type || "Unknown");
  const counts = data.map(d => d.usage_count || 0);
  const colors = ["#3b82f6", "#10b981", "#f59e0b", "#ef4444"];

  const ctx = canvas.getContext("2d");
  roomChart = new Chart(ctx, {
    type: "doughnut",
    data: {
      labels: types,
      datasets: [{
        data: counts,
        backgroundColor: colors.slice(0, types.length),
        borderColor: "#ffffff",
        borderWidth: 2
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      plugins: {
        legend: {
          position: "bottom",
          labels: { font: { size: 12 }, padding: 15 }
        }
      }
    }
  });
}

function createGroupChart(totalPlanned, mergedCount, splitCount){
  if(!totalPlanned) return;

  const canvas = $("groupChart");
  if(!canvas) return;

  if(groupChart) groupChart.destroy();

  const regular = totalPlanned - mergedCount - splitCount;

  const ctx = canvas.getContext("2d");
  groupChart = new Chart(ctx, {
    type: "bar",
    data: {
      labels: ["Regular", "Merged\n(Amphi)", "Split"],
      datasets: [{
        label: "Count",
        data: [regular, mergedCount, splitCount],
        backgroundColor: ["#06b6d4", "#10b981", "#f59e0b"],
        borderRadius: 6,
        borderSkipped: false
      }]
    },
    options: {
      indexAxis: "y",
      responsive: true,
      maintainAspectRatio: true,
      plugins: {
        legend: { display: false }
      },
      scales: {
        x: { beginAtZero: true, grid: { color: "rgba(0,0,0,0.05)" } }
      }
    }
  });
}

(async function init(){
  try {
    setMsg("Loading analytics…");
    
    // load periodes
    try{
      const periodesRes = await api.periodes();
      // support both: direct array or wrapper { ok, data }
      const periodes = Array.isArray(periodesRes) ? periodesRes : (periodesRes && periodesRes.data ? periodesRes.data : []);
      if (Array.isArray(periodes) && periodeSel) {
        fillSelect(periodeSel, periodes, p=>p.id_periode, p=>p.label);
        // keep dashboard in global view by default: do not auto-select a periode
        try { periodeSel.selectedIndex = -1; periodeSel.value = ""; } catch(e) { /* noop */ }
      }
    }catch(e){ /* periodes load failed — ignored for clean console */ }

    const periode_id = periodeSel ? (Number(periodeSel.value) || undefined) : undefined;

    // KPIs
    const kpis = await api.dashKpis(periode_id) || {};
    const { total_planned = 0, merged_count = 0, split_count = 0, total_profs = 0 } = kpis;

    const k1 = $("k1"); if (k1) k1.textContent = total_planned;
    const k2 = $("k2"); if (k2) k2.textContent = merged_count;
    const k3 = $("k3"); if (k3) k3.textContent = split_count;
    const k4 = $("k4"); if (k4) k4.textContent = total_profs;
    
    // Percentages
    const merged_pct = total_planned > 0 ? Math.round((merged_count / total_planned) * 100) : 0;
    const split_pct = total_planned > 0 ? Math.round((split_count / total_planned) * 100) : 0;

    const k2pct = $("k2-pct"); if (k2pct) k2pct.textContent = merged_pct + "%";
    const k3pct = $("k3-pct"); if (k3pct) k3pct.textContent = split_pct + "%";
    
    // Room distribution chart
    const roomDist = await api.dashRoomDist(periode_id) || [];
    createRoomChart(roomDist);
    
    // Group handling chart
    createGroupChart(total_planned, merged_count, split_count);
    
    // Top rooms
    const topRooms = await api.dashTopRooms(periode_id) || [];
    renderTopRooms(topRooms);
    
    // Prof load
    const profLoad = await api.dashProfLoad(periode_id) || [];
    renderProfLoad(profLoad);
    
    // Conflicts
    const conflicts = await api.dashProfConflicts(periode_id) || [];
    renderConf(conflicts);

    if((conflicts || []).length === 0){
      setMsg("✅ No professor overlaps detected. System is optimal.", false);
    } else {
      setMsg(`⚠️ ${conflicts.length} conflict(s) detected. Review immediately.`, true);
    }
    
  } catch(e) {
    setMsg("Error: " + e.message, true);
    console.error(e);
  }
})();

// refresh handler
refreshBtn?.addEventListener('click', ()=>{
  window.location.reload();
});
