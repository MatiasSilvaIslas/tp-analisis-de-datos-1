'use strict';

const DATA_URL = 'data/processed/dashboard.json';
const COLORS = ['#55d6d2', '#7d9cff', '#ad91ff', '#80dfb4', '#ffb86b'];
const TECH_LABELS = ['ADSL', 'Cablemódem', 'Fibra óptica', 'Wireless', 'Otros'];
const numberFmt = new Intl.NumberFormat('es-AR', { maximumFractionDigits: 0 });
const decimalFmt = new Intl.NumberFormat('es-AR', { maximumFractionDigits: 2 });
let DATA;
let charts = {};

const $ = (id) => document.getElementById(id);
const sum = (arr, key) => arr.reduce((acc, item) => acc + (Number(item[key]) || 0), 0);
const fmt = (value) => value == null || !Number.isFinite(Number(value)) ? '—' : numberFmt.format(value);
const fmtDecimal = (value, digits = 1) => value == null || !Number.isFinite(Number(value)) ? '—' : new Intl.NumberFormat('es-AR', { maximumFractionDigits: digits, minimumFractionDigits: digits }).format(value);
const periodSort = (a, b) => a.year - b.year || a.quarter - b.quarter;

function chartDefaults() {
  Chart.defaults.color = '#9aa9c2';
  Chart.defaults.font.family = "'DM Sans', sans-serif";
  Chart.defaults.font.size = 10;
  Chart.defaults.plugins.legend.display = false;
  Chart.defaults.plugins.tooltip.backgroundColor = '#080f1d';
  Chart.defaults.plugins.tooltip.borderColor = 'rgba(174,193,226,.2)';
  Chart.defaults.plugins.tooltip.borderWidth = 1;
  Chart.defaults.plugins.tooltip.padding = 10;
  Chart.defaults.plugins.tooltip.titleFont = { family: 'Manrope', weight: '700' };
  Chart.defaults.scale.grid.color = 'rgba(174,193,226,.09)';
  Chart.defaults.scale.border.display = false;
}

function initFilters() {
  const years = [...new Set(DATA.national.map(d => d.year))].sort((a,b) => a-b);
  years.forEach(year => $('yearFilter').add(new Option(String(year), String(year))));
  const provinces = [...new Set(DATA.provinces.map(d => d.province))].sort((a,b) => a.localeCompare(b, 'es'));
  provinces.forEach(province => $('provinceFilter').add(new Option(province, province)));
  ['yearFilter', 'quarterFilter', 'provinceFilter'].forEach(id => $(id).addEventListener('change', render));
  $('resetFilters').addEventListener('click', () => {
    $('yearFilter').value = 'all'; $('quarterFilter').value = 'all'; $('provinceFilter').value = 'all'; render();
  });
}

function selectedRows() {
  const year = $('yearFilter').value;
  const quarter = $('quarterFilter').value;
  const province = $('provinceFilter').value;
  const matches = row => (year === 'all' || String(row.year) === year) && (quarter === 'all' || String(row.quarter) === quarter);
  return { year, quarter, province, matches };
}

function rowsForProvince(province, matches) {
  return DATA.provinces.filter(r => r.province === province && matches(r)).sort(periodSort);
}

function nationalRows(matches) {
  return DATA.national.filter(matches).sort(periodSort);
}

function destroyChart(id) {
  if (charts[id]) { charts[id].destroy(); delete charts[id]; }
}

function makeChart(id, config) {
  destroyChart(id);
  const canvas = $(id);
  if (!canvas) return;
  charts[id] = new Chart(canvas, config);
}

function latestRow(rows) {
  return [...rows].sort(periodSort).at(-1) || null;
}

function updateKpis(ctx) {
  const sourceRows = ctx.province === 'all' ? nationalRows(ctx.matches) : rowsForProvince(ctx.province, ctx.matches);
  const latest = latestRow(sourceRows);
  const total = latest ? Number(latest.total_accesses) || 0 : 0;
  const fiber = latest ? Number(latest['tech_Fibra Optica']) || 0 : 0;
  const fiberShare = total ? fiber / total * 100 : null;
  const speed = latest ? (ctx.province === 'all' ? latest.weighted_mean_mbps_estimate : latest.mean_mbps) : null;
  const penetration = latest && ctx.province !== 'all' ? latest.per_100_households : null;

  $('kpiAccess').textContent = latest ? fmt(total) : '—';
  $('kpiAccessNote').textContent = latest ? `Último período del filtro · ${latest.period}` : 'Sin datos para los filtros elegidos';
  $('kpiFiber').textContent = fiberShare == null ? '—' : `${fmtDecimal(fiberShare, 1)}%`;
  $('kpiFiberNote').textContent = latest ? `${fmt(fiber)} accesos de fibra óptica · ${latest.period}` : 'Sin datos';
  $('kpiSpeed').textContent = speed == null ? '—' : `${fmtDecimal(speed, 1)} Mbps`;
  $('kpiSpeedNote').textContent = ctx.province === 'all' ? 'Estimación ponderada · último período' : `Dato provincial · ${latest ? latest.period : ''}`;
  $('kpiPenetration').textContent = penetration == null ? '—' : `${fmtDecimal(penetration, 1)}`;
  $('kpiPenetrationNote').textContent = ctx.province === 'all' ? 'Elegí una provincia para consultar' : `Accesos cada 100 hogares · ${latest ? latest.period : ''}`;

  const bits = [];
  if (ctx.year !== 'all') bits.push(ctx.year); else bits.push('2014–2024');
  if (ctx.quarter !== 'all') bits.push(`T${ctx.quarter}`);
  if (ctx.province !== 'all') bits.push(ctx.province);
  $('periodLabel').textContent = bits.join(' · ');
}

function accessAndTechCharts(ctx) {
  const selected = ctx.province === 'all' ? nationalRows(ctx.matches) : rowsForProvince(ctx.province, ctx.matches);
  const labels = selected.map(r => r.period);
  const totalKey = 'total_accesses';
  makeChart('accessChart', {
    type: 'line',
    data: { labels, datasets: [
      { label: 'Accesos totales', data: selected.map(r => r[totalKey]), borderColor: COLORS[1], backgroundColor: 'rgba(125,156,255,.10)', fill: true, tension: .28, pointRadius: 0, pointHoverRadius: 4, borderWidth: 2.5 },
      { label: 'Accesos de fibra óptica', data: selected.map(r => r['tech_Fibra Optica']), borderColor: COLORS[0], backgroundColor: 'rgba(85,214,210,.05)', fill: false, tension: .28, pointRadius: 0, pointHoverRadius: 4, borderWidth: 2.5 }
    ]},
    options: { responsive: true, maintainAspectRatio: false, interaction: { mode: 'index', intersect: false }, plugins: { tooltip: { callbacks: { label: c => `${c.dataset.label}: ${fmt(c.raw)}` } } }, scales: { x: { ticks: { maxTicksLimit: 12, maxRotation: 0 }, grid: { display: false } }, y: { beginAtZero: true, ticks: { callback: v => compact(v) } } } }
  });

  const techKeys = ['tech_ADSL', 'tech_Cablemodem', 'tech_Fibra Optica', 'tech_Wireless', 'tech_Otros'];
  const techColors = COLORS;
  const totalForMix = selected.map(r => Number(r.total_accesses) || 0);
  const datasets = techKeys.map((key, i) => ({
    label: TECH_LABELS[i],
    data: selected.map((r, idx) => totalForMix[idx] ? (Number(r[key]) || 0) / totalForMix[idx] * 100 : 0),
    borderColor: techColors[i], backgroundColor: techColors[i], fill: true, tension: .25, pointRadius: 0, borderWidth: 1.4, stack: 'share'
  }));
  makeChart('technologyChart', { type: 'line', data: { labels, datasets }, options: { responsive: true, maintainAspectRatio: false, interaction: { mode: 'index', intersect: false }, plugins: { tooltip: { callbacks: { label: c => `${c.dataset.label}: ${fmtDecimal(c.raw, 1)}%` } } }, scales: { x: { stacked: true, ticks: { maxTicksLimit: 8, maxRotation: 0 }, grid: { display: false } }, y: { stacked: true, min: 0, max: 100, ticks: { callback: v => `${v}%` } } } } });
  $('techLegend').innerHTML = TECH_LABELS.map((label,i) => `<span class="legend-item"><i class="legend-swatch" style="background:${COLORS[i]}"></i>${label}</span>`).join('');

  const speedKey = ctx.province === 'all' ? 'weighted_mean_mbps_estimate' : 'mean_mbps';
  const speedSeries = selected.filter(r => r[speedKey] != null);
  $('speedChartSubtitle').textContent = ctx.province === 'all' ? 'Mbps · estimación ponderada nacional' : `Mbps · ${ctx.province}`;
  makeChart('speedTrendChart', { type: 'line', data: { labels: speedSeries.map(r => r.period), datasets: [{ label: 'Velocidad media', data: speedSeries.map(r => r[speedKey]), borderColor: COLORS[2], backgroundColor: 'rgba(173,145,255,.13)', fill: true, tension: .3, pointRadius: 0, pointHoverRadius: 4, borderWidth: 2.5 }] }, options: { responsive: true, maintainAspectRatio: false, plugins: { tooltip: { callbacks: { label: c => `${fmtDecimal(c.raw, 1)} Mbps` } } }, scales: { x: { ticks: { maxTicksLimit: 9, maxRotation: 0 }, grid: { display: false } }, y: { beginAtZero: true, ticks: { callback: v => `${v} Mbps` } } } } });
}

function comparisonCharts(ctx) {
  const filtered = DATA.provinces.filter(ctx.matches);
  const latest = latestRow(filtered);
  const all = latest ? filtered.filter(r => r.year === latest.year && r.quarter === latest.quarter) : [];
  const byProvince = new Map(all.map(row => [row.province, row]));
  const penetration = [...byProvince.entries()].map(([province, row]) => ({ province, value: row.per_100_households })).filter(x => x.value != null).sort((a,b) => a.value-b.value);
  makeChart('penetrationChart', { type: 'bar', data: { labels: penetration.map(x => x.province), datasets: [{ data: penetration.map(x => x.value), backgroundColor: penetration.map((x,i) => i >= penetration.length-3 ? 'rgba(85,214,210,.85)' : 'rgba(125,156,255,.58)'), borderRadius: 4, barThickness: 10 }] }, options: horizontalOptions(v => `${fmtDecimal(v,1)} accesos/100 hogares`) });

  const speeds = [...byProvince.entries()].map(([province, row]) => ({ province, value: row.mean_mbps })).filter(x => x.value != null).sort((a,b) => a.value-b.value);
  makeChart('provinceSpeedChart', { type: 'bar', data: { labels: speeds.map(x => x.province), datasets: [{ data: speeds.map(x => x.value), backgroundColor: 'rgba(173,145,255,.72)', borderRadius: 4, barThickness: 10 }] }, options: horizontalOptions(v => `${fmtDecimal(v,1)} Mbps`) });
  speedCategoryChart(ctx);
}

function speedCategoryChart(ctx) {
  const matching = DATA.speed_bands.filter(r => ctx.matches(r) && (ctx.province === 'all' || r.province === ctx.province));
  const latest = latestRow(matching);
  const selected = latest ? matching.filter(r => r.year === latest.year && r.quarter === latest.quarter) : [];
  const grouped = new Map();
  selected.forEach(row => grouped.set(row.speed_category, (grouped.get(row.speed_category) || 0) + Number(row.accesses || 0)));
  const top = [...grouped.entries()].map(([category, accesses]) => ({ category, accesses })).sort((a,b) => b.accesses-a.accesses).slice(0,12).reverse();
  makeChart('speedBandsChart', { type: 'bar', data: { labels: top.map(x => x.category), datasets: [{ data: top.map(x => x.accesses), backgroundColor: 'rgba(255,184,107,.72)', borderRadius: 4, barThickness: 12 }] }, options: horizontalOptions(v => `${fmt(v)} accesos`) });
}

function localityChart(ctx) {
  const province = ctx.province;
  let rows = DATA.localities.filter(r => province === 'all' || r.province === province);
  rows = [...rows].sort((a,b) => b.total_accesses-a.total_accesses).slice(0, 12).reverse();
  const labels = rows.map(r => `${r.locality} · ${r.department}`);
  makeChart('localityChart', { type: 'bar', data: { labels, datasets: [{ data: rows.map(r => r.total_accesses), backgroundColor: 'rgba(85,214,210,.68)', borderRadius: 4, barThickness: 13 }] }, options: horizontalOptions(v => `${fmt(v)} accesos`) });
  const speedRows = DATA.locality_speed_bands.filter(r => province === 'all' || r.province === province);
  const grouped = new Map();
  speedRows.forEach(row => grouped.set(row.speed_category, (grouped.get(row.speed_category) || 0) + Number(row.accesses || 0)));
  const topSpeed = [...grouped.entries()].map(([category, accesses]) => ({ category, accesses })).sort((a,b) => b.accesses-a.accesses).slice(0,12).reverse();
  makeChart('localSpeedChart', { type: 'bar', data: { labels: topSpeed.map(x => x.category), datasets: [{ data: topSpeed.map(x => x.accesses), backgroundColor: 'rgba(173,145,255,.72)', borderRadius: 4, barThickness: 12 }] }, options: horizontalOptions(v => `${fmt(v)} accesos`) });
}

function horizontalOptions(labelCallback) {
  return { indexAxis: 'y', responsive: true, maintainAspectRatio: false, plugins: { tooltip: { callbacks: { label: c => labelCallback(c.raw) } } }, scales: { x: { beginAtZero: true, ticks: { callback: v => compact(v) } }, y: { grid: { display: false }, ticks: { autoSkip: false, font: { size: 9 } } } } };
}

function average(rows, key) {
  const valid = rows.filter(r => r[key] != null && Number.isFinite(Number(r[key])));
  if (!valid.length) return null;
  return valid.reduce((a,r) => a + Number(r[key]), 0) / valid.length;
}

function compact(value) {
  const n = Number(value);
  if (n >= 1e6) return `${(n/1e6).toLocaleString('es-AR',{maximumFractionDigits:1})} M`;
  if (n >= 1e3) return `${(n/1e3).toLocaleString('es-AR',{maximumFractionDigits:0})} mil`;
  return numberFmt.format(n);
}

function render() {
  const ctx = selectedRows();
  updateKpis(ctx);
  accessAndTechCharts(ctx);
  comparisonCharts(ctx);
  localityChart(ctx);
}

async function start() {
  try {
    if (typeof Chart === 'undefined') throw new Error('No se pudo cargar Chart.js. Revisá tu conexión a Internet.');
    const response = await fetch(DATA_URL);
    if (!response.ok) throw new Error(`No se pudo leer ${DATA_URL} (HTTP ${response.status}).`);
    DATA = await response.json();
    chartDefaults();
    initFilters();
    render();
    $('loading').classList.add('hidden');
  } catch (error) {
    $('loading').classList.add('hidden');
    $('errorBox').hidden = false;
    $('errorBox').textContent = `${error.message} Para abrir el dashboard, ejecutá un servidor local desde la carpeta del proyecto: python -m http.server 8000`;
    console.error(error);
  }
}

start();
