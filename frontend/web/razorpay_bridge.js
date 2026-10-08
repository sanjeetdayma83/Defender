(function () {
  "use strict";

  function ensureCheckoutScript() {
    return new Promise(function (resolve, reject) {
      if (window.Razorpay) {
        resolve();
        return;
      }

      var existing = document.getElementById(
        "loss-defender-razorpay-checkout"
      );

      if (existing) {
        existing.addEventListener("load", resolve, { once: true });
        existing.addEventListener("error", reject, { once: true });
        return;
      }

      var script = document.createElement("script");
      script.id = "loss-defender-razorpay-checkout";
      script.src = "https://checkout.razorpay.com/v1/checkout.js";
      script.async = true;

      script.onload = function () {
        resolve();
      };

      script.onerror = function () {
        reject(
          new Error("Unable to load Razorpay Checkout.")
        );
      };

      document.head.appendChild(script);
    });
  }

  window.openLossDefenderRazorpay = async function (
    payloadJson,
    onSuccess,
    onFailure
  ) {
    try {
      var payload = JSON.parse(payloadJson);

      await ensureCheckoutScript();

      if (!window.Razorpay) {
        throw new Error(
          "Razorpay Checkout is unavailable."
        );
      }

      var options = {
        key: payload.keyId,
        amount: payload.amountPaise,
        currency: payload.currency || "INR",
        name: "Loss Defender Pro",
        description: payload.description || "Subscription",
        order_id: payload.orderId,
        prefill: {
          name: payload.name || "",
          email: payload.email || "",
          contact: payload.phone || ""
        },
        theme: {
          color: "#0061FC"
        },
        modal: {
          ondismiss: function () {
            if (onFailure) {
              onFailure("Payment window was closed.");
            }
          }
        },
        handler: function (response) {
          if (onSuccess) {
            onSuccess(JSON.stringify(response));
          }
        }
      };

      var razorpay = new window.Razorpay(options);

      razorpay.on(
        "payment.failed",
        function (response) {
          var reason =
            response &&
            response.error &&
            response.error.description
              ? response.error.description
              : "Payment failed.";

          if (onFailure) {
            onFailure(reason);
          }
        }
      );

      razorpay.open();
    } catch (error) {
      if (onFailure) {
        onFailure(
          error && error.message
            ? error.message
            : "Unable to open Razorpay Checkout."
        );
      }
    }
  };
})();
