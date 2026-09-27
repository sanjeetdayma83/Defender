(function () {
  "use strict";

  let clerkLoaded = false;
  let clerkLoadingPromise = null;

  function loadScript(id, src, attributes) {
    return new Promise(function (resolve, reject) {
      const existing = document.getElementById(id);

      if (existing) {
        if (existing.dataset.loaded === "true") {
          resolve();
          return;
        }

        existing.addEventListener("load", function () {
          resolve();
        }, { once: true });

        existing.addEventListener("error", function () {
          reject(new Error("Failed to load " + src));
        }, { once: true });

        return;
      }

      const script = document.createElement("script");
      script.id = id;
      script.src = src;
      script.async = true;
      script.crossOrigin = "anonymous";

      if (attributes) {
        Object.keys(attributes).forEach(function (key) {
          script.setAttribute(key, attributes[key]);
        });
      }

      script.onload = function () {
        script.dataset.loaded = "true";
        resolve();
      };

      script.onerror = function () {
        reject(new Error("Failed to load " + src));
      };

      document.head.appendChild(script);
    });
  }

  async function initialize(publishableKey) {
    if (!publishableKey) {
      throw new Error("Clerk publishable key is missing.");
    }

    if (!publishableKey.startsWith("pk_")) {
      throw new Error("Invalid Clerk publishable key.");
    }

    if (window.Clerk && clerkLoaded) {
      return;
    }

    if (clerkLoadingPromise) {
      return clerkLoadingPromise;
    }

    clerkLoadingPromise = (async function () {
      const encoded = publishableKey.split("_")[2];

      if (!encoded) {
        throw new Error("Could not derive Clerk Frontend API domain.");
      }

      const clerkDomain = atob(encoded).slice(0, -1);

      const uiUrl =
        "https://" +
        clerkDomain +
        "/npm/@clerk/ui@1/dist/ui.browser.js";

      const clerkJsUrl =
        "https://" +
        clerkDomain +
        "/npm/@clerk/clerk-js@6/dist/clerk.browser.js";

      await loadScript(
        "loss-defender-clerk-ui",
        uiUrl
      );

      await loadScript(
        "loss-defender-clerk-js",
        clerkJsUrl,
        {
          "data-clerk-publishable-key": publishableKey
        }
      );

      if (!window.Clerk) {
        throw new Error("ClerkJS loaded but window.Clerk is unavailable.");
      }

      await window.Clerk.load({
        ui: {
          ClerkUI: window.__internal_ClerkUICtor
        },
        afterSignOutUrl: "/"
      });

      window.Clerk.addListener(function () {
        window.dispatchEvent(
          new CustomEvent("loss-defender-auth-change")
        );
      });

      clerkLoaded = true;
    })();

    try {
      await clerkLoadingPromise;
    } catch (error) {
      clerkLoadingPromise = null;
      throw error;
    }
  }

  async function mountSignIn(element) {
    if (!window.Clerk || !clerkLoaded) {
      throw new Error("Clerk is not initialized.");
    }

    element.innerHTML = "";

    window.Clerk.mountSignIn(element, {
      routing: "hash",
      oauthFlow: "popup",
      fallbackRedirectUrl: "/",
      signUpFallbackRedirectUrl: "/"
    });
  }

  async function mountSignUp(element) {
    if (!window.Clerk || !clerkLoaded) {
      throw new Error("Clerk is not initialized.");
    }

    element.innerHTML = "";

    window.Clerk.mountSignUp(element, {
      routing: "hash",
      oauthFlow: "popup",
      fallbackRedirectUrl: "/",
      signInFallbackRedirectUrl: "/"
    });
  }

  async function unmount(element) {
    if (!window.Clerk || !clerkLoaded || !element) {
      return;
    }

    try {
      window.Clerk.unmountSignIn(element);
    } catch (_) {}

    try {
      window.Clerk.unmountSignUp(element);
    } catch (_) {}
  }

  function isSignedIn() {
    return !!(
      window.Clerk &&
      clerkLoaded &&
      window.Clerk.isSignedIn
    );
  }

  async function getToken() {
    if (!window.Clerk || !window.Clerk.session) {
      return null;
    }

    return await window.Clerk.session.getToken();
  }

  async function signOut() {
    if (!window.Clerk) {
      return;
    }

    await window.Clerk.signOut();
  }

  async function handleRedirectCallback() {
    if (!window.Clerk || !clerkLoaded) {
      throw new Error("Clerk is not initialized.");
    }

    const currentUrl = window.location.href;

    console.log(
      "[Loss Defender] Handling Clerk OAuth callback:",
      currentUrl
    );

    await window.Clerk.handleRedirectCallback(
      {
        redirectUrl: window.location.origin + "/",
        redirectUrlComplete: window.location.origin + "/"
      },
      async function (to) {
        window.history.replaceState({}, "", "/");
      }
    );

    window.history.replaceState({}, "", "/");

    window.dispatchEvent(
      new CustomEvent("loss-defender-auth-change")
    );
  }
  window.lossDefenderClerk = {
    initialize: initialize,
    mountSignIn: mountSignIn,
    mountSignUp: mountSignUp,
    unmount: unmount,
    isSignedIn: isSignedIn,
    getToken: getToken,
    signOut: signOut
  };
})();






