const API_BASE_URL = "https://7knhe8rpy7.execute-api.us-east-1.amazonaws.com";

async function loadResources() {
    const resourceList = document.getElementById("resource-list");

    try {
        const response = await fetch(`${API_BASE_URL}/resources`);
        const resources = await response.json();

        // Displays a message when no resources are currently stored.
        if (resources.length === 0) {
            resourceList.innerHTML = "<p>No resources found.</p>";
            return;
        }

        resourceList.innerHTML = "";

        for (const resource of resources) {
            const resourceElement = document.createElement("div");

            resourceElement.innerHTML = `
                <h3>${resource.name}</h3>
                <p>Type: ${resource.type}</p>
                <p>Environment: ${resource.environment}</p>
                <p>Status: ${resource.status}</p>
                <p>Security Review: ${resource.securityReview}</p>
            `;

            resourceList.appendChild(resourceElement);
        }
    } catch (error) {
        resourceList.innerHTML = "<p>Unable to load resources.</p>";
        console.error("Failed to load resources:", error);
    }
}

loadResources();

const resourceForm = document.getElementById("resource-form");

resourceForm.addEventListener("submit", async function (event) {
    event.preventDefault();

    const resource = {
        name: document.getElementById("name").value,
        type: document.getElementById("type").value,
        environment: document.getElementById("environment").value,
        owner: document.getElementById("owner").value,
        status: document.getElementById("status").value,
        securityReview: document.getElementById("securityReview").value,
        notes: document.getElementById("notes").value
    };

    try {
        const response = await fetch(`${API_BASE_URL}/resources`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(resource)
        });

        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }

        resourceForm.reset();
        await loadResources();
    } catch (error) {
        console.error("Failed to create resource:", error);
    }
});