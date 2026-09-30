// This file is already complete -- nothing to write here. It's the ~15
// lines of JS that connect the dropdown/input/button to your SQL (in
// rls_policy.sql, which is the actual thing you're writing this week).

const roleSelect = document.getElementById("week08-role-select");
const personInput = document.getElementById("week08-person-id");
const valueLabel = document.getElementById("week08-value-label");

const LABELS = {
  app_customer: { text: "Person (customer_unique_id)", placeholder: "paste a real customer_unique_id" },
  app_district_admin: { text: "District (state code)", placeholder: "e.g. SP" },
  app_admin: { text: "(no value needed for this role)", placeholder: "" },
};

function updateLabel() {
  const info = LABELS[roleSelect.value] || LABELS.app_customer;
  valueLabel.textContent = info.text;
  personInput.placeholder = info.placeholder;
}

async function refresh() {
  // Sent under both keys -- only the one your active role's policy
  // actually reads via current_setting() has any effect; the other is
  // simply unused for that role.
  const result = await callApi("week08/rls_role_switch", {
    method: "POST",
    body: { role: roleSelect.value, person_id: personInput.value, district: personInput.value },
  });
  renderResult("week08-rls-result", result);
}

roleSelect.addEventListener("change", updateLabel);
document.getElementById("week08-role-switch-btn").addEventListener("click", refresh);
updateLabel();
