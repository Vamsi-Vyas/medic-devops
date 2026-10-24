// Appointments Booking & Management Script

let selectedTimeSlot = '10:00 AM';

document.addEventListener('DOMContentLoaded', () => {
  loadDoctors();
  loadAppointments();
  setupSlotPicker();
  setupFormSubmit();
});

async function loadDoctors() {
  const doctorSelect = document.getElementById('doctor-select');
  if (!doctorSelect) return;

  try {
    const res = await fetch('/api/doctors');
    const doctors = await res.json();

    doctorSelect.innerHTML = '<option value="">-- Select Specialist Doctor --</option>';
    doctors.forEach(doc => {
      const opt = document.createElement('option');
      opt.value = `${doc.name} (${doc.department})`;
      opt.textContent = `${doc.name} — ${doc.role} (${doc.department}) ★ ${doc.rating}`;
      doctorSelect.appendChild(opt);
    });
  } catch (err) {
    console.error('Error fetching doctors:', err);
  }
}

async function loadAppointments() {
  const listContainer = document.getElementById('appointments-list');
  if (!listContainer) return;

  try {
    const res = await fetch('/api/appointments');
    const appointments = await res.json();

    if (appointments.length === 0) {
      listContainer.innerHTML = '<p style="color:#64748b; font-size:0.9rem;">No upcoming appointments booked yet.</p>';
      return;
    }

    listContainer.innerHTML = '';
    appointments.forEach(apt => {
      const item = document.createElement('div');
      item.className = 'apt-item';
      item.innerHTML = `
        <div class="apt-meta">
          <h5>${apt.doctor}</h5>
          <p><strong>Patient:</strong> ${apt.patientName} &bull; <strong>Ref:</strong> ${apt.id}</p>
          <p>📅 ${apt.date} at ⏰ ${apt.time}</p>
          <span class="apt-status">${apt.status}</span>
        </div>
        <div>
          <button class="btn-cancel" onclick="cancelAppointment('${apt.id}')">Cancel</button>
        </div>
      `;
      listContainer.appendChild(item);
    });
  } catch (err) {
    console.error('Error loading appointments:', err);
  }
}

function setupSlotPicker() {
  const slots = document.querySelectorAll('.slot-btn');
  slots.forEach(slot => {
    slot.addEventListener('click', () => {
      slots.forEach(s => s.classList.remove('active'));
      slot.classList.add('active');
      selectedTimeSlot = slot.getAttribute('data-time');
    });
  });
}

function setupFormSubmit() {
  const form = document.getElementById('appointment-form');
  if (!form) return;

  form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const patientName = document.getElementById('patientName').value.trim();
    const patientEmail = document.getElementById('patientEmail').value.trim();
    const patientPhone = document.getElementById('patientPhone').value.trim();
    const doctor = document.getElementById('doctor-select').value;
    const date = document.getElementById('appointmentDate').value;
    const reason = document.getElementById('reason').value.trim();

    if (!doctor || !date || !selectedTimeSlot) {
      alert('Please fill out all mandatory fields and select a consultation slot.');
      return;
    }

    const payload = {
      patientName,
      patientEmail,
      patientPhone,
      doctor,
      date,
      time: selectedTimeSlot,
      reason
    };

    try {
      const res = await fetch('/api/appointments', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      const data = await res.json();
      if (res.ok) {
        showSuccessModal(data.appointment);
        form.reset();
        loadAppointments();
      } else {
        alert(data.error || 'Failed to schedule appointment.');
      }
    } catch (err) {
      alert('Network error while scheduling appointment.');
    }
  });
}

async function cancelAppointment(id) {
  if (!confirm(`Are you sure you want to cancel appointment ${id}?`)) return;

  try {
    const res = await fetch(`/api/appointments/${id}`, { method: 'DELETE' });
    const data = await res.json();
    if (res.ok) {
      loadAppointments();
    } else {
      alert(data.error || 'Could not cancel appointment.');
    }
  } catch (err) {
    alert('Error connecting to server.');
  }
}

function showSuccessModal(apt) {
  const modal = document.getElementById('booking-modal');
  const details = document.getElementById('modal-details');
  if (!modal || !details) return;

  details.innerHTML = `
    <p><strong>Appointment ID:</strong> ${apt.id}</p>
    <p><strong>Doctor:</strong> ${apt.doctor}</p>
    <p><strong>Date & Time:</strong> ${apt.date} @ ${apt.time}</p>
    <p><strong>Patient:</strong> ${apt.patientName}</p>
  `;

  modal.classList.add('active');
}

function closeModal() {
  const modal = document.getElementById('booking-modal');
  if (modal) modal.classList.remove('active');
}
