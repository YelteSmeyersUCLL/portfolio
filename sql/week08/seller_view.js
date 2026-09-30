// This file is already complete -- nothing to write here. It's the ~5
// lines of JS that connect the button/input to your SQL (in
// seller_rls_policy.sql, which is the actual thing you're writing this
// week).
const sellerInput = document.getElementById("week08-seller-id");

async function refreshSellerView() {
  const result = await callApi("week08/rls_seller_view", {
    method: "POST",
    body: { role: "app_seller", seller_id: sellerInput.value },
  });
  renderResult("week08-seller-result", result);
}

document.getElementById("week08-seller-view-btn").addEventListener("click", refreshSellerView);
