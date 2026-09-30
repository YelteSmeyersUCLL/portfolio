// This file is already complete -- nothing to write here. It's the ~10
// lines of JS that connect the button/input to your SQL (in
// process_refund.sql, which is the actual thing you're writing this week).
document.getElementById("week09-refund-btn").addEventListener("click", async () => {
  const orderId = document.getElementById("week09-order-id").value;
  const result = await callApi("week09/process_refund", {
    method: "POST",
    body: { order_id: orderId },
  });
  renderResult("week09-refund-result", result);
  // The audit log widget re-checks itself on an interval (see app.js), so it
  // will pick up the new row without any extra code here.
});
