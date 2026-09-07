.pragma library

// QuoteClient service for Ticking Plasmoid
// Handles offline curated selection and remote LLM quote fetching with sanitization.

var DEFAULT_QUOTE_TEXT = "The only reason for time is so that everything does not happen at once.";
var DEFAULT_QUOTE_AUTHOR = "Albert Einstein";
var ZEN_ENDPOINT = "https://opencode.ai/zen/v1/chat/completions";
var REMOTE_MODELS = ["nemotron-3-ultra-free", "nemotron-3.5-lightning-free"];
var TIMEOUT_MS = 25000;

function cleanQuoteText(text) {
    if (!text || typeof text !== "string") {
        return "";
    }
    var cleaned = text.trim();
    if (cleaned.indexOf("thinking process") !== -1 || cleaned.indexOf("Analyze User Request") !== -1) {
        return "";
    }
    cleaned = cleaned.replace(/^(alternatively|here is|here's|sure[!,.]?|quote|option \d+)[:\s\-]*/i, "").trim();
    cleaned = cleaned.replace(/^(a quote|another quote|one quote|a profound quote)[:\s\-]*/i, "").trim();
    cleaned = cleaned.replace(/^["'\u201c\u201d\u00ab\u00bb]+|["'\u201c\u201d\u00ab\u00bb]+$/g, "").trim();
    return cleaned;
}

function cleanQuoteAuthor(author) {
    if (!author || typeof author !== "string") {
        return "";
    }
    var cleaned = author.trim();
    cleaned = cleaned.replace(/^["'\u201c\u201d\u00ab\u00bb]+|["'\u201c\u201d\u00ab\u00bb]+$/g, "").trim();

    // Reject commentary lines masquerading as authors
    if (/^(attributed to|possibly|maybe|this is|that's|probably|unknown|an? \w+ quote)/i.test(cleaned)) {
        return "";
    }

    // Cut off full sentences continuing after the author's name (e.g. "Bruce Lee. That's a quote about focus, but...")
    var periodIdx = cleaned.indexOf(". ");
    if (periodIdx !== -1) {
        var beforePeriod = cleaned.substring(0, periodIdx).trim();
        if (!/^[A-Z]\.?\s*[A-Z]?\.?$/.test(beforePeriod)) {
            cleaned = beforePeriod;
        }
    }

    // Cut off trailing explanatory phrases after comma or dash
    cleaned = cleaned.replace(/,\s*(?:which|who|that|a|an|the|as|noting|explaining|saying)[\s\S]*$/i, "");
    cleaned = cleaned.replace(/\s+-\s+.*$/, "");
    cleaned = cleaned.replace(/[.\-,;:\s]+$/, "").trim();

    if (cleaned.length > 45 || cleaned.length === 0) {
        return "";
    }
    return cleaned;
}

function parseModelContent(content) {
    if (!content || typeof content !== "string") {
        return null;
    }

    var text = content.replace(/<think>[\s\S]*?<\/think>/g, "").trim();
    text = text.replace(/\u2014/g, "-");

    if (text.indexOf("thinking process") !== -1 || text.indexOf("Analyze User Request") !== -1) {
        var lines = text.trim().split("\n");
        var foundLine = "";
        for (var li = lines.length - 1; li >= 0; --li) {
            var candidate = lines[li].trim();
            if (candidate.length > 5 && candidate.indexOf(" - ") !== -1 && candidate.indexOf("thinking process") === -1 && candidate.indexOf("**") === -1) {
                foundLine = candidate;
                break;
            }
        }
        if (foundLine.length > 0) {
            text = foundLine;
        } else {
            return null;
        }
    }

    var qText = "";
    var qAuthor = "";
    var matchQuoted = text.match(/["\u201c]([^"\u201d\n]+)["\u201d]\s*[-by]+\s*([^"\n]+)/);

    if (matchQuoted) {
        qText = matchQuoted[1].trim();
        qAuthor = matchQuoted[2].trim();
    } else {
        var trimmed = text.replace(/^(alternatively|here is|here's|sure[!,.]?|quote|option \d+)[:\s\-]*/i, "").trim();
        trimmed = trimmed.replace(/^(a quote|another quote|one quote|a profound quote)[:\s\-]*/i, "").trim();
        if (trimmed.indexOf(" - ") !== -1) {
            var parts = trimmed.split(" - ");
            qText = parts[0].trim();
            qAuthor = parts.slice(1).join(" - ").trim();
        } else if (trimmed.indexOf(" by ") !== -1) {
            var bParts = trimmed.split(" by ");
            qText = bParts[0].trim();
            qAuthor = bParts.slice(1).join(" by ").trim();
        } else {
            qText = trimmed;
        }
    }

    qText = cleanQuoteText(qText);
    qAuthor = cleanQuoteAuthor(qAuthor);

    if (qText.length === 0 || qAuthor.length === 0 || qText.length > 280) {
        return null;
    }
    return { text: qText, author: qAuthor };
}

var ARCHETYPE_TOPICS = {
    stoic: [
        "stoic discipline and inner fortress",
        "amor fati and enduring hardship",
        "focusing strictly on what is in your control",
        "tranquility through reason and wisdom",
        "memento mori and the urgency of time",
        "self-mastery and temperance"
    ],
    builder: [
        "craftsmanship and building great things",
        "relentless iteration and engineering excellence",
        "creating software systems that endure",
        "shipping and execution over talking",
        "overcoming technical barriers through persistence",
        "the beauty of master craftsmanship"
    ],
    cosmic: [
        "the vastness of time and cosmic perspective",
        "the preciousness of fleeting human moments",
        "the mystery of the universe and human purpose",
        "the arrow of time and starlight",
        "humility under the vast cosmos"
    ],
    intensity: [
        "unwavering self-discipline and daily mastery",
        "grit and relentless determination",
        "deep work and eliminating all distractions",
        "perseverance through pain and struggle",
        "laser focus and fierce urgency",
        "mental toughness and relentless drive",
        "obsession with excellence and execution"
    ],
    adaptive: [
        "clarity of vision and unrelenting momentum",
        "mastery over time and decisive action",
        "turning ambitious goals into reality",
        "relentless focus and dedication"
    ]
};

function resolveTopic(archetype, headline, personalFocus) {
    var focus = (personalFocus || "").trim();
    if (focus.length > 0) {
        return focus;
    }
    var pool = ARCHETYPE_TOPICS[archetype];
    if (pool && pool.length > 0) {
        var idx = Math.floor(Math.random() * pool.length);
        return pool[idx];
    }
    var title = (headline || "").trim();
    if (title.length > 0 && title !== "NEW HORIZON") {
        return title;
    }
    return "relentless focus and execution";
}

function fetchQuote(params, quoteLibrary, callbacks) {
    var apiKey = (params.apiKey || "").trim();
    var archetype = params.archetype || "adaptive";
    var ratio = params.progressRatio || 0.0;
    var forceOffline = !!params.forceOffline;
    var currentQuote = (params.currentQuoteText || "").trim();
    var currentAuthor = (params.currentQuoteAuthor || "").trim();

    var onSuccess = (callbacks && callbacks.onSuccess) ? callbacks.onSuccess : function () {};
    var onComplete = (callbacks && callbacks.onComplete) ? callbacks.onComplete : function () {};

    function fallbackToCurated() {
        var fallback = quoteLibrary.getCuratedQuote(archetype, ratio, currentQuote);
        onSuccess(cleanQuoteText(fallback.text), cleanQuoteAuthor(fallback.author));
        onComplete();
    }

    if (forceOffline || apiKey.length === 0) {
        fallbackToCurated();
        return;
    }

    var topic = resolveTopic(archetype, params.milestoneTitle, params.personalFocus);
    var prompt = "Famous quote about " + topic + ".";
    if (currentQuote.length > 10) {
        var quoteSnippet = currentQuote.replace(/["\n]/g, "").slice(0, 35);
        prompt += " Do NOT provide the quote: \"" + quoteSnippet + "...\"";
        if (currentAuthor.length > 0) {
            prompt += " or any quote by " + currentAuthor;
        }
        prompt += ".";
    }
    prompt += " 1 line only: \"Quote\" - Author Name";

    var modelIndex = 0;

    function tryNextModel() {
        if (modelIndex >= REMOTE_MODELS.length) {
            fallbackToCurated();
            return;
        }

        var modelName = REMOTE_MODELS[modelIndex++];
        var xhr = new XMLHttpRequest();
        xhr.open("POST", ZEN_ENDPOINT, true);
        xhr.setRequestHeader("Authorization", "Bearer " + apiKey);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader("x-session-id", "ticking-" + Date.now());
        xhr.timeout = TIMEOUT_MS;

        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var res = JSON.parse(xhr.responseText);
                        if (res.error) {
                            console.warn("Ticking QuoteClient: upstream error on", modelName, res.error.message);
                        } else {
                            var content = res.choices && res.choices[0] && res.choices[0].message ? res.choices[0].message.content : "";
                            var parsed = parseModelContent(content);
                            if (parsed && parsed.text.length > 0 && parsed.author.length > 0) {
                                if (currentQuote.length > 0 && parsed.text.toLowerCase() === currentQuote.toLowerCase()) {
                                    console.warn("Ticking QuoteClient: duplicate quote received, cascading");
                                    tryNextModel();
                                    return;
                                }
                                onSuccess(parsed.text, parsed.author);
                                onComplete();
                                return;
                            }
                        }
                    } catch (e) {
                        console.warn("Ticking QuoteClient: parse failed:", e);
                    }
                } else {
                    console.warn("Ticking QuoteClient: model", modelName, "returned status", xhr.status, xhr.responseText);
                }
                tryNextModel();
            }
        };

        xhr.ontimeout = tryNextModel;
        xhr.onerror = tryNextModel;

        var messages = [
            {
                role: "system",
                content: "You are a database of famous quotes. Respond ONLY with the format:\n\"<Quote>\" - <Author Name>\nDo NOT add notes, explanations, commentary, or attribution disclaimers. Author must be ONLY the person name."
            },
            {
                role: "user",
                content: prompt
            }
        ];

        var payload = JSON.stringify({
            model: modelName,
            messages: messages,
            max_tokens: 800,
            temperature: 0.85
        });
        xhr.send(payload);
    }

    tryNextModel();
}
