// This file is already complete -- nothing to write here. It's the ~10
// lines of JS that connect the button to your SQL (in place_order.sql,
// which is the actual thing you're writing this week). `callApi` and
// `renderResult` are provided by frontend/helpers.js.
//
// Wire up the "Place demo order" button so clicking it runs your transaction
// and shows the result.

document.getElementById("week03-place-order-btn").addEventListener("click", async () => {
  const result = await callApi("week03/place_order", { method: "POST" });
  renderResult("week03-place-order-result", result);
});
