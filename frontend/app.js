const API_BASE_URL = "https://7knhe8rpy7.execute-api.us-east-1.amazonaws.com";

let editingResourceId = null;

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
            securityReview.textContent = `Security Review: ${resource.securityReview}`;

            const notes = document.createElement("p");
            notes.textContent = `Notes: ${resource.notes || "None"}`;

            const editButton = document.createElement("button");
            editButton.textContent = "Edit";
            editButton.classList.add("edit-button");

            const deleteButton = document.createElement("button");
            deleteButton.textContent = "Delete";
            deleteButton.classList.add("delete-button");

            editButton.addEventListener("click", function () {
                editingResourceId = resource.id;

                cancelButton.hidden = false;
                document.getElementById("submit-button").textContent = "Save Changes";

                document.getElementById("name").value = resource.name;
                document.getElementById("type").value = resource.type;
                document.getElementById("environment").value = resource.environment;
                document.getElementById("owner").value = resource.owner;
                document.getElementById("status").value = resource.status;
                document.getElementById("securityReview").value = resource.securityReview;
                document.getElementById("notes").value = resource.notes || "";
            });

            deleteButton.addEventListener("click", function () {
                const confirmed = confirm(`Delete "${resource.name}"?`);

                if (confirmed) {
                    deleteResource(resource.id);
                }
            });

            resourceElement.appendChild(name);
            resourceElement.appendChild(type);
            resourceElement.appendChild(environment);
            resourceElement.appendChild(owner);
            resourceElement.appendChild(status);
            resourceElement.appendChild(securityReview);
            resourceElement.appendChild(notes);
            resourceElement.appendChild(editButton);
            resourceElement.appendChild(deleteButton);

            resourceList.appendChild(resourceElement);
        }
    } catch (error) {
        resourceList.textContent = "Unable to load resources.";
        console.error("Failed to load resources:", error);
    }
}

async function deleteResource(resourceId) {
    try {
        const response = await fetch(`${API_BASE_URL}/resources/${resourceId}`, {
            method: "DELETE"
        });

        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }

        await loadResources();
    } catch (error) {
        console.error("Failed to delete resource:", error);
    }
}

const resourceForm = document.getElementById("resource-form");
const cancelButton = document.getElementById("cancel-button");
const submitButton = document.getElementById("submit-button");

cancelButton.addEventListener("click", function () {
    resourceForm.reset();
    editingResourceId = null;

    submitButton.textContent = "Add Resource";
    cancelButton.hidden = true;
});

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
        const url = editingResourceId
            ? `${API_BASE_URL}/resources/${editingResourceId}`
            : `${API_BASE_URL}/resources`;

        const method = editingResourceId ? "PATCH" : "POST";

        const response = await fetch(url, {
            method: method,
            headers: {
                "Content-Type": "application/json"
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

loadResources();