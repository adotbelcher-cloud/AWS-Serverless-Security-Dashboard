const API_BASE_URL = "https://7knhe8rpy7.execute-api.us-east-1.amazonaws.com";

const COGNITO_CLIENT_ID = "4q6oodsbmutorlecnmfhgu4liv";
const COGNITO_DOMAIN = "serverless-security-dashboard.auth.us-east-1.amazoncognito.com";
const REDIRECT_URI = "https://d3j1gi7s7gqnk2.cloudfront.net";

let editingResourceId = null;


// Generates the temporary random value used to prove this browser started the login.
function generateCodeVerifier() {
    const randomBytes = new Uint8Array(32);
    crypto.getRandomValues(randomBytes);

    return base64UrlEncode(randomBytes);
}


// Creates the SHA-256 challenge sent to Cognito during sign-in.
async function generateCodeChallenge(codeVerifier) {
    const encodedVerifier = new TextEncoder().encode(codeVerifier);
    const digest = await crypto.subtle.digest("SHA-256", encodedVerifier);

    return base64UrlEncode(new Uint8Array(digest));
}


// Converts bytes into the URL-safe Base64 format required by PKCE.
function base64UrlEncode(bytes) {
    let binary = "";

    for (const byte of bytes) {
        binary += String.fromCharCode(byte);
    }

    return btoa(binary)
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=+$/, "");
}


// Returns the Cognito access token stored for the current browser session.
function getAccessToken() {
    return sessionStorage.getItem("access_token");
}


// Updates the page based on whether the user is currently authenticated.
function updateAuthenticationUI() {
    const accessToken = getAccessToken();
    const signedIn = Boolean(accessToken);

    signInButton.hidden = signedIn;
    signOutButton.hidden = !signedIn;

    resourceForm.hidden = !signedIn;
}


// Exchanges Cognito's authorization code for JWTs using the PKCE verifier.
async function exchangeAuthorizationCode(code) {
    const codeVerifier = sessionStorage.getItem("pkce_code_verifier");

    if (!codeVerifier) {
        throw new Error("PKCE code verifier was not found.");
    }

    const requestBody = new URLSearchParams({
        grant_type: "authorization_code",
        client_id: COGNITO_CLIENT_ID,
        code: code,
        redirect_uri: REDIRECT_URI,
        code_verifier: codeVerifier
    });

    const response = await fetch(
        `https://${COGNITO_DOMAIN}/oauth2/token`,
        {
            method: "POST",
            headers: {
                "Content-Type": "application/x-www-form-urlencoded"
            },
            body: requestBody
        }
    );

    if (!response.ok) {
        throw new Error(`Token exchange failed: ${response.status}`);
    }

    const tokens = await response.json();

    sessionStorage.setItem("access_token", tokens.access_token);
    sessionStorage.setItem("id_token", tokens.id_token);

    if (tokens.refresh_token) {
        sessionStorage.setItem("refresh_token", tokens.refresh_token);
    }

    sessionStorage.removeItem("pkce_code_verifier");
}


// Checks whether Cognito redirected back with an authorization code.
async function handleAuthenticationCallback() {
    const url = new URL(window.location.href);
    const authorizationCode = url.searchParams.get("code");
    const error = url.searchParams.get("error");

    if (error) {
        console.error(
            "Cognito authentication failed:",
            url.searchParams.get("error_description") || error
        );

        return;
    }

    if (!authorizationCode) {
        return;
    }

    try {
        await exchangeAuthorizationCode(authorizationCode);

        // Removes ?code=... from the browser address bar after successful login.
        window.history.replaceState(
            {},
            document.title,
            REDIRECT_URI
        );
    } catch (error) {
        console.error("Failed to complete authentication:", error);
    }
}


const signInButton = document.getElementById("sign-in-button");
const signOutButton = document.getElementById("sign-out-button");

const resourceForm = document.getElementById("resource-form");
const cancelButton = document.getElementById("cancel-button");
const submitButton = document.getElementById("submit-button");


// Starts the Cognito authorization-code login flow using PKCE.
signInButton.addEventListener("click", async function () {
    const codeVerifier = generateCodeVerifier();
    const codeChallenge = await generateCodeChallenge(codeVerifier);

    sessionStorage.setItem("pkce_code_verifier", codeVerifier);

    const authorizationUrl = new URL(
        `https://${COGNITO_DOMAIN}/oauth2/authorize`
    );

    authorizationUrl.searchParams.set("response_type", "code");
    authorizationUrl.searchParams.set("client_id", COGNITO_CLIENT_ID);
    authorizationUrl.searchParams.set("redirect_uri", REDIRECT_URI);
    authorizationUrl.searchParams.set("scope", "openid email");
    authorizationUrl.searchParams.set("code_challenge_method", "S256");
    authorizationUrl.searchParams.set("code_challenge", codeChallenge);

    window.location.href = authorizationUrl.toString();
});


// Clears local tokens and ends the Cognito managed-login session.
signOutButton.addEventListener("click", function () {
    sessionStorage.removeItem("access_token");
    sessionStorage.removeItem("id_token");
    sessionStorage.removeItem("refresh_token");
    sessionStorage.removeItem("pkce_code_verifier");

    const logoutUrl = new URL(
        `https://${COGNITO_DOMAIN}/logout`
    );

    logoutUrl.searchParams.set("client_id", COGNITO_CLIENT_ID);
    logoutUrl.searchParams.set("logout_uri", REDIRECT_URI);

    window.location.href = logoutUrl.toString();
});


// Loads resources from the public GET endpoint.
async function loadResources() {
    const resourceList = document.getElementById("resource-list");

    resourceList.textContent = "Loading resources...";

    try {
        const response = await fetch(`${API_BASE_URL}/resources`);

        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }

        const resources = await response.json();

        if (resources.length === 0) {
            resourceList.textContent = "No resources found.";
            return;
        }

        resourceList.textContent = "";

        for (const resource of resources) {
            const resourceElement = document.createElement("div");

            const name = document.createElement("h3");
            name.textContent = resource.name;

            const type = document.createElement("p");
            type.textContent = `Type: ${resource.type}`;

            const environment = document.createElement("p");
            environment.textContent = `Environment: ${resource.environment}`;

            const owner = document.createElement("p");
            owner.textContent = `Owner: ${resource.owner}`;

            const status = document.createElement("p");
            status.textContent = `Status: ${resource.status}`;

            const securityReview = document.createElement("p");
            securityReview.textContent =
                `Security Review: ${resource.securityReview}`;

            const notes = document.createElement("p");
            notes.textContent =
                `Notes: ${resource.notes || "None"}`;

            resourceElement.appendChild(name);
            resourceElement.appendChild(type);
            resourceElement.appendChild(environment);
            resourceElement.appendChild(owner);
            resourceElement.appendChild(status);
            resourceElement.appendChild(securityReview);
            resourceElement.appendChild(notes);

            // Only authenticated users receive controls that modify resources.
            if (getAccessToken()) {
                const editButton = document.createElement("button");
                editButton.textContent = "Edit";
                editButton.classList.add("edit-button");

                const deleteButton = document.createElement("button");
                deleteButton.textContent = "Delete";
                deleteButton.classList.add("delete-button");

                editButton.addEventListener("click", function () {
                    editingResourceId = resource.id;

                    cancelButton.hidden = false;
                    submitButton.textContent = "Save Changes";

                    document.getElementById("name").value = resource.name;
                    document.getElementById("type").value = resource.type;
                    document.getElementById("environment").value =
                        resource.environment;
                    document.getElementById("owner").value = resource.owner;
                    document.getElementById("status").value = resource.status;
                    document.getElementById("securityReview").value =
                        resource.securityReview;
                    document.getElementById("notes").value =
                        resource.notes || "";
                });

                deleteButton.addEventListener("click", function () {
                    const confirmed =
                        confirm(`Delete "${resource.name}"?`);

                    if (confirmed) {
                        deleteResource(resource.id);
                    }
                });

                resourceElement.appendChild(editButton);
                resourceElement.appendChild(deleteButton);
            }

            resourceList.appendChild(resourceElement);
        }
    } catch (error) {
        resourceList.textContent = "Unable to load resources.";
        console.error("Failed to load resources:", error);
    }
}


// Deletes a resource using the Cognito access token.
async function deleteResource(resourceId) {
    const accessToken = getAccessToken();

    if (!accessToken) {
        console.error("You must be signed in to delete resources.");
        return;
    }

    try {
        const response = await fetch(
            `${API_BASE_URL}/resources/${resourceId}`,
            {
                method: "DELETE",
                headers: {
                    "Authorization": `Bearer ${accessToken}`
                }
            }
        );

        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }

        await loadResources();
    } catch (error) {
        console.error("Failed to delete resource:", error);
    }
}


cancelButton.addEventListener("click", function () {
    resourceForm.reset();
    editingResourceId = null;

    submitButton.textContent = "Add Resource";
    cancelButton.hidden = true;
});


// Creates or updates a resource using the Cognito access token.
resourceForm.addEventListener("submit", async function (event) {
    event.preventDefault();

    const accessToken = getAccessToken();

    if (!accessToken) {
        console.error("You must be signed in to modify resources.");
        return;
    }

    const resource = {
        name: document.getElementById("name").value,
        type: document.getElementById("type").value,
        environment: document.getElementById("environment").value,
        owner: document.getElementById("owner").value,
        status: document.getElementById("status").value,
        securityReview:
            document.getElementById("securityReview").value,
        notes: document.getElementById("notes").value
    };

    try {
        const url = editingResourceId
            ? `${API_BASE_URL}/resources/${editingResourceId}`
            : `${API_BASE_URL}/resources`;

        const method = editingResourceId ? "PATCH" : "POST";

        const response = await fetch(url, {
            method: method,
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${accessToken}`
            },
            body: JSON.stringify(resource)
        });

        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }

        resourceForm.reset();
        editingResourceId = null;

        submitButton.textContent = "Add Resource";
        cancelButton.hidden = true;

        await loadResources();
    } catch (error) {
        console.error("Failed to save resource:", error);
    }
});


// Completes a Cognito redirect if one is present, then initializes the page.
async function initializeApplication() {
    await handleAuthenticationCallback();

    updateAuthenticationUI();

    await loadResources();
}

initializeApplication();