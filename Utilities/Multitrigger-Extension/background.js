
function isDebuggerAttached(tabId, callback) {
    chrome.debugger.getTargets((targets) => {
        const isAttached = targets.some(target =>
            target.attached && target.tabId === tabId
        );
        callback(isAttached);
    });
}

function isJsonResponse(headers) {
    var isJson = false;
    for (i in headers) {
        if (headers[i]['name'] == 'content-type' && headers[i]['value'].includes('application/json')) {
            isJson = true;
            break;
        }
    }

    return isJson;
}

function fixBody(responseBody) {
    if (!(responseBody['data']['rows'] instanceof Array))
        return res;

    var newBody = structuredClone(responseBody);
    newBody['data']['rows'] = [];

    for (i in responseBody['data']['rows']) {
        const item = responseBody['data']['rows'][i];
        if (!(item[4]['provisioningState'] === "Succeeded")) { // placement four is the logic app definition, hopefully this won't change
            newBody['data']['rows'].push(item)
            continue
        }

        const logicApp = item[4];
        const logicAppDefinition = logicApp['definition'];
        if (!(logicAppDefinition['triggers'] instanceof Object) || (Object.keys(logicAppDefinition['triggers']).length <= 1)) {
            newBody['data']['rows'].push(item)
            continue
        }

        const logicAppTriggers = Object.keys(logicAppDefinition['triggers']);

        var newItems = [];
        for (j in logicAppTriggers) {
            const trigger = logicAppTriggers[j];
            var newItem = structuredClone(item);

            var newTriggersObject = {};
            newTriggersObject[trigger] = logicAppDefinition['triggers'][trigger];
            newItem[4]['definition']['triggers'] = newTriggersObject;

            newItems.push(newItem);
        }

        newBody['data']['rows'] = newBody['data']['rows'].concat(newItems);
    }

    newBody['totalRecords'] = newBody['data']['rows'].length;
    newBody['count'] = newBody['data']['rows'].length;
    return newBody;
};



chrome.webNavigation.onCompleted.addListener((details) => {
    const tabId = details.tabId;
    const url = details.url;

    if (!(url.startsWith("https://portal.azure.com/#view/Microsoft_Azure_Security_Insights"))) 
        return;

    isDebuggerAttached(tabId, (attached) => {
        if (attached) {
            return;
        }

        chrome.debugger.attach({ tabId: tabId }, "1.3", () => {
            console.log("Debugger attached to tab", tabId);

            chrome.debugger.sendCommand({ tabId: tabId }, "Fetch.enable", {
                patterns: [{ urlPattern: "https://management.azure.com/providers/Microsoft.ResourceGraph/resources*", requestStage: "Response" }]
            });
        });

        chrome.debugger.onEvent.addListener((source, method, params) => {
            if (method !== "Fetch.requestPaused")
                return;

            const { requestId } = params;

            chrome.debugger.sendCommand(source, "Fetch.getResponseBody", { requestId }, (response) => {
                let body = response.body;

                if (!isJsonResponse(params.responseHeaders)) {
                    chrome.debugger.sendCommand(source, "Fetch.continueRequest", {requestId});
                    return;
                }

                const parsedOriginalBody = JSON.parse(atob(body));
                const newBody = fixBody(parsedOriginalBody);
                const stringNewBody = JSON.stringify(newBody)

                chrome.debugger.sendCommand(source, "Fetch.fulfillRequest", {
                    requestId,
                    responseCode: 200,
                    responseHeaders: params.responseHeaders,
                    body: btoa(stringNewBody)
                });
            });

        });
    })
}, { url: [{ schemes: ["http", "https"] }] });