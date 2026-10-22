/// The script [RedditPage] runs in the thread page to read it.
///
/// Reddit now refuses every anonymous `.json` request, even from a browser
/// that passed its JavaScript check ("blocked by network security"), so the
/// thread is read from the page itself: the post and the first comments as
/// the page shows them (Reddit only renders the comment tree for a real
/// navigation, not for a `fetch`), then the « more comments » blocks it leaves
/// for later (`/svc/shreddit/more-comments`, one POST each), shallowest first,
/// the way the page fills them in when they are tapped or scrolled to.
///
/// The script answers on [channel] with `{nonce, status, text, failed}`, where
/// `text` is the thread in the `[postListing, commentListing]` shape of
/// Reddit's `.json`, so the rest of the engine reads it as before, and
/// `failed` counts the « more comments » blocks it could not load. Status 0
/// means « not ready yet, try again »: the page is still Reddit's check, or the
/// post is not on it yet; 1, that the post is there but its comments are still
/// loading. Whatever was read is sent by [deadlineMs] (epoch ms).
String threadScript({
  required String channel,
  required String nonce,
  required String postId,
  required int deadlineMs,
}) =>
    '''
(async () => {
  // Taken before any await: a page script swapping them later cannot read
  // the nonce from our calls.
  const channel = $channel, stringify = JSON.stringify;
  const send = (status, text, failed = 0) =>
    channel.postMessage(stringify({nonce: "$nonce", status, text, failed}));
  // One run at a time: a tick that finds one running leaves the answer to it.
  if (window.__tldrRun === "$nonce") return;
  window.__tldrRun = "$nonce";
  const left = () => $deadlineMs - Date.now();
  const abortAfter = (ms) => {
    if (AbortSignal.timeout) return AbortSignal.timeout(ms);
    const c = new AbortController();
    setTimeout(() => c.abort(), ms);
    return c.signal;
  };
  const number = (value, fallback) => {
    const n = parseFloat(value);
    return Number.isFinite(n) ? n : fallback;
  };
  try {
    const post = document.querySelector('shreddit-post[id="t3_$postId"]');
    if (!post) {
      // Reddit's check, or an error page: its status, read once per page,
      // says which. A 403 may be the check or a closed community alike: both
      // wait, and the timeout reports Reddit refusing the read.
      if (!location.protocol.startsWith("http") || document.readyState === "loading") {
        return send(0, "");
      }
      if (window.__tldrStatus === undefined) {
        const r = await fetch(location.href,
          {credentials: "include", signal: abortAfter(Math.max(1, Math.min(5000, left())))});
        window.__tldrStatus = r.status;
      }
      if (window.__tldrStatus === 404) return send(404, '{"error":404}');
      return send(window.__tldrStatus === 403 ? 403 : 0, "");
    }
    const sub = post.getAttribute("subreddit-name") ||
      (location.pathname.match(/^\\/r\\/([^/]+)/) || [])[1];
    if (!sub) return send(1, "");
    // The comment tree renders after the post, a few comments first and the
    // « more comments » blocks later, and the page is still being parsed while
    // it loads: wait for them while there is time.
    const announced = number(post.getAttribute("comment-count"), 0);
    const shown = document.querySelectorAll("shreddit-comment").length;
    const short = shown < announced * 0.8 &&
      !document.querySelector('faceplate-partial[method="post" i]');
    if ((short || document.readyState === "loading") && left() > 6000) {
      // On a first visit Reddit may serve fewer comments and no way to load
      // the rest; reloaded with the cookies it just set, it serves them all.
      if (short && document.readyState !== "loading" && left() > 10000 &&
          !sessionStorage.getItem("tldr-reloaded-$postId")) {
        sessionStorage.setItem("tldr-reloaded-$postId", "1");
        location.reload();
      }
      return send(1, "");
    }

    const parse = (html) => new DOMParser().parseFromString(html, "text/html");
    const permalink = post.getAttribute("permalink") || "/r/" + sub + "/comments/$postId/";
    // An inert copy, filled in without touching the page's own scripts.
    const doc = parse(document.documentElement.outerHTML);
    const top = doc.querySelector('shreddit-post[id="t3_$postId"]') || post;

    const csrf = (document.cookie.match(/(?:^|; )csrf_token=([^;]+)/) || [])[1] ||
      (document.querySelector("input[name=csrf_token]") || {}).value || "";
    // Only Reddit's own « more comments » endpoint gets the page's cookies.
    const target = (p) => {
      const url = new URL(p.getAttribute("src") || "", location.href);
      return url.origin === location.origin &&
        url.pathname.startsWith("/svc/shreddit/more-comments/") ? url : null;
    };
    const depthOf = (url) => +(url.searchParams.get("startingDepth") || 0);
    const end = Math.min(Date.now() + $_budgetMs, $deadlineMs);
    let requests = 0, failed = 0;
    for (;;) {
      if (requests >= $_maxRequests || Date.now() >= end) break;
      if (doc.querySelectorAll("shreddit-comment").length >= $_maxComments) break;
      const more = [...doc.querySelectorAll('faceplate-partial[method="post" i]')]
        .map((p) => ({p, url: target(p)}))
        .filter(({url}) => url && depthOf(url) <= $_maxDepth)
        .sort((a, b) => depthOf(a.url) - depthOf(b.url))
        .slice(0, Math.min($_batchSize, $_maxRequests - requests));
      if (more.length === 0) break;
      requests += more.length;
      await Promise.all(more.map(async ({p, url}) => {
        const form = new URLSearchParams();
        p.querySelectorAll("input[type=hidden]").forEach((i) => form.append(i.name, i.value));
        form.append("csrf_token", csrf);
        try {
          const res = await fetch(url.href, {method: "POST", credentials: "same-origin",
            headers: {"content-type": "application/x-www-form-urlencoded"}, body: form,
            signal: abortAfter(Math.max(1, Math.min($_requestTimeoutMs, end - Date.now())))});
          if (!res.ok) throw new Error(String(res.status));
          const part = parse(await res.text());
          p.replaceWith(...[...part.body.childNodes].map((n) => doc.importNode(n, true)));
        } catch (_) {
          failed++;
          p.remove();
        }
      }));
    }

    // Text with its paragraphs, list items and line breaks.
    const blocks = /^(P|DIV|LI|BLOCKQUOTE|PRE|H[1-6]|UL|OL|TABLE|TR)\$/;
    const textOf = (el) => {
      let out = "";
      const walk = (n, pre) => {
        if (n.nodeType === 3) { out += pre ? n.nodeValue : n.nodeValue.replace(/\\s+/g, " "); return; }
        if (n.nodeType !== 1) return;
        if (n.tagName === "BR") { out += "\\n"; return; }
        const block = blocks.test(n.tagName);
        if (block) out += "\\n";
        if (n.tagName === "LI") out += "- ";
        n.childNodes.forEach((c) => walk(c, pre || n.tagName === "PRE"));
        if (block) out += n.tagName === "P" ? "\\n\\n" : "\\n";
      };
      walk(el, false);
      return out.replace(/[ \\t]+\\n/g, "\\n").replace(/\\n[ \\t]+/g, "\\n")
        .replace(/\\n{3,}/g, "\\n\\n").trim();
    };

    // Each comment's replies are the comments nested in its element. A
    // comment a « more comments » answer repeats is kept once.
    const kept = new Map();
    const all = [];
    for (const c of doc.querySelectorAll("shreddit-comment")) {
      const id = c.getAttribute("thingid");
      if (!id || kept.has(id)) continue;
      kept.set(id, c);
      all.push(c);
    }
    const parentOf = (c) => {
      const el = c.parentElement && c.parentElement.closest("shreddit-comment");
      return el ? kept.get(el.getAttribute("thingid")) || null : null;
    };
    const children = new Map();
    for (const c of all) {
      const parent = parentOf(c);
      if (!children.has(parent)) children.set(parent, []);
      children.get(parent).push(c);
    }
    const comment = (c) => {
      const replies = children.get(c) || [];
      const body = [...c.querySelectorAll("[slot=comment]")]
        .find((b) => b.closest("shreddit-comment") === c);
      return {kind: "t1", data: {
        id: c.getAttribute("thingid").replace(/^t1_/, ""),
        author: c.getAttribute("author") || "[deleted]",
        score: Math.round(number(c.getAttribute("score"), 0)),
        body: body ? textOf(body) : "",
        replies: replies.length === 0 ? "" :
          {kind: "Listing", data: {children: replies.map(comment)}},
      }};
    };

    const state = (top.getAttribute("item-state") || "").toLowerCase();
    const body = top.querySelector("[slot=text-body]");
    const created = Date.parse(top.getAttribute("created-timestamp") || "");
    const thread = {
      id: "$postId", subreddit: sub, permalink,
      title: top.getAttribute("post-title") || "",
      author: top.getAttribute("author") || "[deleted]",
      created_utc: Number.isFinite(created) ? created / 1000 : Date.now() / 1000,
      score: Math.round(number(top.getAttribute("score"), 0)),
      upvote_ratio: number(top.getAttribute("upvote-ratio"), 1),
      num_comments: Math.round(number(top.getAttribute("comment-count"), all.length)),
      over_18: top.hasAttribute("nsfw"),
      selftext: body ? textOf(body) : "",
      removed_by_category: state.includes("deleted") ? "deleted" :
        state.includes("removed") ? "moderator" : null,
    };
    send(200, stringify([
      {kind: "Listing", data: {children: [{kind: "t3", data: thread}]}},
      {kind: "Listing", data: {children: (children.get(null) || []).map(comment)}},
    ]), failed);
  } catch (_) {
    send(0, "");
  } finally {
    window.__tldrRun = null;
  }
})();
''';

const _maxComments = 500;
const _maxDepth = 4;
const _maxRequests = 60;
const _batchSize = 6;
const _budgetMs = 10000;
const _requestTimeoutMs = 5000;
