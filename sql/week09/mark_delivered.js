// This file is already complete -- nothing to write here. It's the ~10
// lines of JS that connect the button/input to your SQL (in
// mark_delivered.sql, which is the actual thing you're writing this week).
document.getElementById("week09-deliver-btn").addEventListener("click", async () => {
  const orderId = document.getElementById("week09-deliver-order-id").value;
  const result = await callApi("week09/mark_delivered", {
    method: "POST",
    body: { order_id: orderId },
  });
  renderResult("week09-deliver-result", result);
});
