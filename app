const STORAGE_KEYS = {
  session: "dgz_session",
  appointments: "dgz_appointments",
  messages: "dgz_messages",
};

function readJson(key, fallback) {
  try {
    return JSON.parse(localStorage.getItem(key) || JSON.stringify(fallback));
  } catch {
    return fallback;
  }
}

const state = {
  user: null,
  appointments: readJson(STORAGE_KEYS.appointments, []),
  messages: readJson(STORAGE_KEYS.messages, []),
};

const el = {
  loginPanel: document.getElementById("login-panel"),
  appPanel: document.getElementById("app-panel"),
  reminderPanel: document.getElementById("reminder-panel"),
  loginForm: document.getElementById("login-form"),
  loginEmail: document.getElementById("login-email"),
  loginPassword: document.getElementById("login-password"),
  welcome: document.getElementById("welcome"),
  logout: document.getElementById("logout"),
  appointmentForm: document.getElementById("appointment-form"),
  appointmentId: document.getElementById("appointment-id"),
  clientName: document.getElementById("client-name"),
  appointmentTitle: document.getElementById("appointment-title"),
  appointmentDatetime: document.getElementById("appointment-datetime"),
  clearAppointment: document.getElementById("clear-appointment"),
  appointmentList: document.getElementById("appointment-list"),
  appointmentSearch: document.getElementById("appointment-search"),
  messageForm: document.getElementById("message-form"),
  messageType: document.getElementById("message-type"),
  messageCategory: document.getElementById("message-category"),
  messageRecipient: document.getElementById("message-recipient"),
  messageContext: document.getElementById("message-context"),
  messagePreview: document.getElementById("message-preview"),
  messageList: document.getElementById("message-list"),
  messageSearch: document.getElementById("message-search"),
  upcomingCount: document.getElementById("upcoming-count"),
  messageCount: document.getElementById("message-count"),
};

function persist() {
  localStorage.setItem(STORAGE_KEYS.appointments, JSON.stringify(state.appointments));
  localStorage.setItem(STORAGE_KEYS.messages, JSON.stringify(state.messages));
}

function getSession() {
  return readJson(STORAGE_KEYS.session, null);
}

function setSession(user) {
  localStorage.setItem(STORAGE_KEYS.session, JSON.stringify(user));
}

function clearSession() {
  localStorage.removeItem(STORAGE_KEYS.session);
}

function setAuthenticatedView(user) {
  state.user = user;
  el.loginPanel.classList.add("hidden");
  el.appPanel.classList.remove("hidden");
  el.welcome.textContent = `Signed in as ${user.email}`;
  render();
}

function setLoggedOutView() {
  state.user = null;
  el.appPanel.classList.add("hidden");
  el.loginPanel.classList.remove("hidden");
  el.loginForm.reset();
}

function formatDate(dateInput) {
  return new Date(dateInput).toLocaleString();
}

function makeMessage(type, recipient, context, category) {
  if (type === "hr") {
    return `Hello ${recipient},\n\nThis is an HR ${category} update regarding ${context}. Please review and reply with any questions.\n\nBest regards,\nHR Team`;
  }
  return `Hi ${recipient},\n\nThank you for your time regarding ${context}. This ${category} note includes your next steps.\n\nBest,\nSales Team`;
}

function renderReminders() {
  const now = Date.now();
  const nextDay = now + 24 * 60 * 60 * 1000;
  const soon = state.appointments
    .filter((item) => {
      const at = new Date(item.datetime).getTime();
      return at >= now && at <= nextDay;
    })
    .sort((a, b) => new Date(a.datetime) - new Date(b.datetime));

  if (soon.length === 0) {
    el.reminderPanel.classList.add("hidden");
    el.reminderPanel.textContent = "";
    return;
  }

  const top = soon[0];
  el.reminderPanel.classList.remove("hidden");
  el.reminderPanel.textContent = `Reminder: ${top.title} with ${top.client} is scheduled for ${formatDate(top.datetime)}.`;
}

function renderAppointments() {
  const term = el.appointmentSearch.value.trim().toLowerCase();
  const sorted = [...state.appointments].sort((a, b) => new Date(a.datetime) - new Date(b.datetime));
  const filtered = sorted.filter((item) => `${item.client} ${item.title}`.toLowerCase().includes(term));

  el.appointmentList.innerHTML = "";
  filtered.forEach((item) => {
    const li = document.createElement("li");
    li.innerHTML = `
      <div>
        <strong>${item.title}</strong><br>
        Client: ${item.client}<br>
        ${formatDate(item.datetime)}
      </div>
      <div>
        <button data-edit="${item.id}" class="secondary">Edit</button>
        <button data-delete="${item.id}">Delete</button>
      </div>`;
    el.appointmentList.appendChild(li);
  });

  el.upcomingCount.textContent = String(
    state.appointments.filter((a) => new Date(a.datetime).getTime() >= Date.now()).length
  );
}

function renderMessages() {
  const term = el.messageSearch.value.trim().toLowerCase();
  const filtered = [...state.messages]
    .reverse()
    .filter((message) => `${message.type} ${message.category} ${message.recipient} ${message.content}`.toLowerCase().includes(term));

  el.messageList.innerHTML = "";
  filtered.forEach((message) => {
    const li = document.createElement("li");
    li.innerHTML = `
      <div>
        <strong>${message.type.toUpperCase()}</strong> · ${message.category} · ${message.recipient}<br>
        ${new Date(message.createdAt).toLocaleString()}<br>
        ${message.content.replaceAll("\n", "<br>")}
      </div>`;
    el.messageList.appendChild(li);
  });

  el.messageCount.textContent = String(state.messages.length);
}

function render() {
  renderReminders();
  renderAppointments();
  renderMessages();
}

el.loginForm.addEventListener("submit", (event) => {
  event.preventDefault();
  const email = el.loginEmail.value.trim();
  const password = el.loginPassword.value;

  if (!email.includes("@") || password.length < 4) {
    alert("Use a valid email and password length of at least 4.");
    return;
  }

  const user = { email };
  setSession(user);
  setAuthenticatedView(user);
});

el.logout.addEventListener("click", () => {
  clearSession();
  setLoggedOutView();
});

el.appointmentForm.addEventListener("submit", (event) => {
  event.preventDefault();
  const datetime = el.appointmentDatetime.value;
  if (!datetime) {
    alert("Please choose a date and time.");
    return;
  }

  const id = el.appointmentId.value || crypto.randomUUID();
  const payload = {
    id,
    client: el.clientName.value.trim(),
    title: el.appointmentTitle.value.trim(),
    datetime,
  };

  const existingIdx = state.appointments.findIndex((a) => a.id === id);
  if (existingIdx >= 0) {
    state.appointments[existingIdx] = payload;
  } else {
    state.appointments.push(payload);
  }

  persist();
  el.appointmentForm.reset();
  el.appointmentId.value = "";
  render();
});

el.clearAppointment.addEventListener("click", () => {
  el.appointmentForm.reset();
  el.appointmentId.value = "";
});

el.appointmentList.addEventListener("click", (event) => {
  const target = event.target;
  if (!(target instanceof HTMLButtonElement)) {
    return;
  }

  const editId = target.getAttribute("data-edit");
  const deleteId = target.getAttribute("data-delete");

  if (editId) {
    const item = state.appointments.find((a) => a.id === editId);
    if (!item) {
      return;
    }
    el.appointmentId.value = item.id;
    el.clientName.value = item.client;
    el.appointmentTitle.value = item.title;
    el.appointmentDatetime.value = item.datetime;
  }

  if (deleteId) {
    state.appointments = state.appointments.filter((a) => a.id !== deleteId);
    persist();
    render();
  }
});

el.messageForm.addEventListener("submit", (event) => {
  event.preventDefault();
  const type = el.messageType.value;
  const category = el.messageCategory.value;
  const recipient = el.messageRecipient.value.trim();
  const context = el.messageContext.value.trim();
  const content = makeMessage(type, recipient, context, category);

  el.messagePreview.textContent = content;

  state.messages.push({
    id: crypto.randomUUID(),
    type,
    category,
    recipient,
    context,
    content,
    createdAt: new Date().toISOString(),
  });
  persist();
  el.messageForm.reset();
  el.messageType.value = type;
  renderMessages();
});

el.appointmentSearch.addEventListener("input", renderAppointments);
el.messageSearch.addEventListener("input", renderMessages);

(function init() {
  const session = getSession();
  if (session?.email) {
    setAuthenticatedView(session);
  } else {
    setLoggedOutView();
  }
})();
