const fs = require("node:fs");
const path = require("node:path");
const { parseArgs } = require("node:util");
const { Select } = require("enquirer");

// ---------------------------
// region Config
// ---------------------------

const nodeTypeToModelType = {
    "CheckpointLoaderSimple": "checkpoints",
    "Power Lora Loader (rgthree)": "loras",
};

const modelTypeToPath = {
    "checkpoints": "./app/models/checkpoints",
    "loras": "./app/models/loras",
};

const nodeTypeToQueryFn = {
    "CheckpointLoaderSimple": (widgetValue) => widgetValue,
    "Power Lora Loader (rgthree)": (widgetValue) => widgetValue.lora,
};

// ---------------------------
// region Cache
// ---------------------------

const SEARCH_CACHE_DIR = "./.cache/search_hits";
const MODEL_CACHE_DIR = "./.cache/model_data";

if (!fs.existsSync(SEARCH_CACHE_DIR)) fs.mkdirSync(SEARCH_CACHE_DIR, { recursive: true });
if (!fs.existsSync(MODEL_CACHE_DIR)) fs.mkdirSync(MODEL_CACHE_DIR, { recursive: true });

function getCachePathForQuery(query) {
    const safeName = query.replace(/[\/\\:?<>|"]/g, "_");
    return path.join(SEARCH_CACHE_DIR, `${safeName}.json`);
}

function getCachePathForModel(id) {
    return path.join(MODEL_CACHE_DIR, `${id}.json`);
}

function cacheSearchHits(query, newHits) {
    const path = getCachePathForQuery(query);
    let current = [];
    if (fs.existsSync(path)) {
        try {
            current = JSON.parse(fs.readFileSync(path, "utf-8"));
        } catch {
            console.error("Error reading cache file:", e.message);
        }
    }

    // merge current and newHits by stable id
    const merged = [...current, ...newHits];
    const seen = {};
    const deduped = [];

    for (const hit of merged.sort((a, b) => a.id - b.id)) {
        if (!seen[hit.id]) {
            deduped.push(hit);
            seen[hit.id] = true;
        }
    }

    fs.writeFileSync(path, JSON.stringify(deduped, null, 2), "utf-8");
}

function getCachedHits(query, limit) {
    const path = getCachePathForQuery(query);
    if (fs.existsSync(path)) {
        try {
            const hits = JSON.parse(fs.readFileSync(path, "utf-8"));
            if (hits.length > limit) return hits;
        } catch {
            console.error("Error reading cache file:", e.message);
        }
    };
    return null;
}

function cacheModelData(id, data) {
    fs.writeFileSync(getCachePathForModel(id), JSON.stringify(data, null, 2), "utf-8");
}

function getCachedModelData(id) {
    const path = getCachePathForModel(id);
    if (fs.existsSync(path)) {
        try {
            return JSON.parse(fs.readFileSync(path, "utf-8"));
        } catch {
            console.error("Error reading cache file:", e.message);
        }
    }
    return null;
}

// ---------------------------
// region searchCivitai
// ---------------------------

async function searchCivitai(query, limit=1) {
    const cached = getCachedHits(query, limit);
    if (cached !== null) return cached.slice(0, limit);

    try {
        const res = await fetch("https://search-new.civitai.com/multi-search", {
            method: "POST",
            headers: {
                "authorization": "Bearer 8c46eb2508e21db1e9828a97968d91ab1ca1caa5f70a00e88a2ba1e286603b61",
                "content-type": "application/json",
                "Referer": "https://civitai.com/"
            },
            body: JSON.stringify({
                queries: [
                    {
                        q: query,
                        indexUid: `models_v9`,
                        limit,
                        offset: 0
                    }
                ]
            })
        });

        const data = await res.json();
        const hits = data.results?.[0]?.hits || [];
        cacheSearchHits(query, hits);
        return hits;
    } catch (error) {
        console.error("Error fetching data:", error.message);
        return null;
    }
}

// ---------------------------
// region fetchModelData
// ---------------------------

async function fetchModelData(hit) {
    const cached = getCachedModelData(hit.id);
    if (cached !== null) return cached;

    try {
        const res = await fetch(`https://civitai.com/models/${hit.id}`, {
            headers: { "Referer": "https://civitai.com/" }
        });
        const html = await res.text();
        const match = html.match(/<script id="__NEXT_DATA__" type="application\/json">(.+?)<\/script>/);
        if (!match) return null;
        const json = JSON.parse(match[1]);
        cacheModelData(hit.id, json);
        return json;
    } catch (error) {
        console.error("Error fetching model page:", error.message);
        return null;
    }
}

// ---------------------------
// region Main
// ---------------------------

async function main() {
    const { positionals } = parseArgs({ options: {}, allowPositionals: true });
    const workflowPath = positionals[0];

    if (!workflowPath || !fs.existsSync(workflowPath)) {
        console.error("Usage: node downloadFromWorkflow.js <workflow.json>");
        process.exit(1);
    }

    const workflow = JSON.parse(fs.readFileSync(workflowPath, "utf-8"));
    const nodes = workflow.nodes || [];

    const selectedFiles = [];
    const seen = {};

    for (const node of nodes) {
        const type = node.type;
        const modelType = nodeTypeToModelType[type];
        const queryFn = nodeTypeToQueryFn[type];

        if (!modelType || !queryFn || !Array.isArray(node.widgets_values)) continue;
        
        console.log();
        
        for (const widgetValue of node.widgets_values) {
            let query = queryFn(widgetValue);
            if (!query) continue;

            // Sometimes names have a path like prefix
            // Only keep the last part
            query = query.split(/[/\\]/).pop();

            if (query in seen) continue;

            let limit = 1;
            let hits = await searchCivitai(query, limit);

            let selected = null;
            while (!selected && hits?.length > 0) {
                const versions = [];

                for (const hit of hits) {
                    const modelData = await fetchModelData(hit);
                    if (!modelData) continue;

                    for (const a of modelData?.props?.pageProps?.trpcState?.json?.queries) {
                        if ("modelVersions" in a?.state?.data) {
                            for (const modelVersion of a.state.data.modelVersions) {
                                for (const file of modelVersion.files) {
                                    versions.push({ modelVersion, file });
                                }
                            }
                            break;
                        }
                    }
                }

                if (versions.length === 0) break;

                // Check exact match first
                selected = versions.find(v => v.file.name === query);

                // Lucky :)
                // Actually that's often the case, few people bother rename models
                if (selected) continue;

                const skipSymbol = Symbol("Skip");
                const moreSymbol = Symbol("More");

                const choices = [skipSymbol, ...versions.map(v => v), moreSymbol];
                const prompt = new Select({
                    name: 'modelVersion',
                    message: `[${modelType}] ${query} - select file`,
                    choices: choices.map(v => {
                        if (v === skipSymbol) return "Skip";
                        if (v === moreSymbol) return "More...";
                        return `${v.modelVersion.name} (${v.file.name})`;
                    })
                });

                const answer = await prompt.run();
                if (answer === "Skip") break;

                if (answer === "More...") {
                    limit += 1;
                    hits = await searchCivitai(query, limit);
                    continue; // rerun loop with more hits
                }

                selected = choices.find(v => v && `${v.modelVersion.name} (${v.file.name})` === answer);
            }

            // Whether selected is null or not we mark it as seen
            // If it was skipped we don't want to prompt it again
            seen[query] = true;
            if (selected) selectedFiles.push({ path: modelTypeToPath[modelType], file: selected.file });
        }
    }

    console.log("\nSelected files:", selectedFiles);
}

main();
