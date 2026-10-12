const summary = document.querySelector('#summary');
const services = document.querySelector('#services');

async function refresh() {
  try {
    const response = await fetch('/api/v1/status', {cache: 'no-store'});
    if (!response.ok) throw new Error('status request failed');
    const payload = await response.json();
    services.replaceChildren(...payload.services.map((service) => {
      const row = document.createElement('article');
      row.className = 'service';
      const name = document.createElement('span');
      name.textContent = service.name;
      const state = document.createElement('span');
      state.className = `state ${service.status}`;
      state.textContent = service.status;
      row.append(name, state);
      return row;
    }));
    summary.textContent = payload.services.length ? `Updated ${new Date(payload.generatedAt).toLocaleString()}` : 'Awaiting the first probe cycle.';
  } catch (_) {
    summary.textContent = 'Status data is temporarily unavailable.';
  }
}

refresh();
setInterval(refresh, 30000);
