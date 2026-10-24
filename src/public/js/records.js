// Patient Electronic Health Records (EHR) Telemetry Script

document.addEventListener('DOMContentLoaded', () => {
  loadPatientEHR();
});

async function loadPatientEHR() {
  try {
    const res = await fetch('/api/records');
    const data = await res.json();

    // Populate patient profile
    document.getElementById('patient-name').textContent = data.fullName;
    document.getElementById('patient-id').textContent = `Patient ID: ${data.patientId}`;
    document.getElementById('patient-age-dob').textContent = `${data.age} yrs (${data.dob})`;
    document.getElementById('patient-blood').textContent = data.bloodGroup;
    document.getElementById('patient-allergies').textContent = data.allergies.join(', ');
    document.getElementById('patient-emergency').textContent = data.emergencyContact;

    // Populate vitals
    document.getElementById('vital-bp').textContent = data.recentVitals.bloodPressure;
    document.getElementById('vital-hr').textContent = data.recentVitals.heartRate;
    document.getElementById('vital-spo2').textContent = data.recentVitals.spO2;
    document.getElementById('vital-glucose').textContent = data.recentVitals.glucose;

    // Populate Prescriptions Table
    const rxBody = document.getElementById('prescriptions-tbody');
    rxBody.innerHTML = '';
    data.recentPrescriptions.forEach(rx => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td><strong>${rx.drug}</strong></td>
        <td>${rx.frequency}</td>
        <td>${rx.doctor}</td>
        <td><span class="apt-status">${rx.refillsLeft} refills</span></td>
      `;
      rxBody.appendChild(tr);
    });

    // Populate Lab Results Table
    const labBody = document.getElementById('lab-tbody');
    labBody.innerHTML = '';
    data.labResults.forEach(lab => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td><strong>${lab.test}</strong></td>
        <td>${lab.date}</td>
        <td><span style="color:#059669; font-weight:600;">${lab.result}</span></td>
        <td><span class="apt-status">${lab.status}</span></td>
      `;
      labBody.appendChild(tr);
    });

  } catch (err) {
    console.error('Failed to load EHR records:', err);
  }
}

function exportMedicalSummary() {
  window.print();
}
