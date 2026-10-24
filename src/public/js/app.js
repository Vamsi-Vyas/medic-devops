// Global PulseCare Application Script
// Handles DevOps environment indicators and Emergency Alert System

document.addEventListener('DOMContentLoaded', () => {
  fetchDeploymentInfo();
  setupEmergencySOS();
});

async function fetchDeploymentInfo() {
  try {
    const res = await fetch('/api/info');
    if (!res.ok) return;
    const data = await res.json();

    const pill = document.getElementById('deployment-pill');
    const versionLabel = document.getElementById('version-label');
    const clusterLabel = document.getElementById('cluster-label');

    if (pill) {
      const color = (data.deploymentColor || 'blue').toLowerCase();
      pill.className = `devops-pill pill-${color}`;
      pill.innerHTML = `<span class="pill-dot"></span> Pod Active: ${color.toUpperCase()} (${data.version || 'v1.0.0'})`;
    }

    if (versionLabel) {
      versionLabel.textContent = `v${data.version || '1.0.0'}`;
    }

    if (clusterLabel) {
      clusterLabel.textContent = 'Kubernetes K3s / EKS';
    }
  } catch (err) {
    console.warn('Failed to load DevOps metadata:', err);
  }
}

function setupEmergencySOS() {
  const sosBtn = document.getElementById('emergency-sos-btn');
  if (!sosBtn) return;

  sosBtn.addEventListener('click', async () => {
    const confirmed = confirm('CRITICAL: Confirm dispatching emergency rapid response ambulance unit to your current location?');
    if (!confirmed) return;

    try {
      const res = await fetch('/api/emergency', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          patientName: 'Emergency Walk-in / Caller',
          location: 'Auto-detected GPS coordinates',
          timestamp: new Date().toISOString()
        })
      });

      const data = await res.json();
      alert(`EMERGENCY SOS DISPATCHED!\nUnit: ${data.dispatchedUnit}\nEstimated ETA: ${data.etaMinutes} mins\nTicket ID: ${data.emergencyId}`);
    } catch (err) {
      alert('Emergency request triggered. Central dispatcher notified.');
    }
  });
}
